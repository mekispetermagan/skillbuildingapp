import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../audio/asset_audio_player.dart';
import '../models/shopping_game.dart';

const shoppingGameConfig = ShoppingGameConfig();

class ShoppingGameController extends ChangeNotifier {
  static const _correctPath = 'assets/audio/letter_dragging/correct.mp3';
  static const _wrongPath = 'assets/audio/letter_dragging/pop.wav';

  final AssetAudioPlayer _audioPlayer;
  final ShoppingGameConfig config;
  final Random _random;

  CashRegisterState cashRegisterState = CashRegisterState.closed;
  List<ShoppingGood> displayedGoods = const [];
  late ShoppingPayment payment;
  PaymentIntroState paymentIntroState = PaymentIntroState.complete;
  bool paymentDecisionComplete = false;
  List<ShoppingBalanceNote> balanceNotes = const [];
  ShoppingGameState state = ShoppingGameState.lottery;
  int score = 0;
  int incorrectAttempts = 0;
  int _nextBalanceNoteId = 0;
  int _animationGeneration = 0;
  Timer? _paymentTimer;

  ShoppingGameController(
    this._audioPlayer, {
    this.config = shoppingGameConfig,
    Random? random,
  }) : _random = random ?? Random();

  void start() {
    score = 0;
    incorrectAttempts = 0;
    _startExercise();
  }

  void _startExercise() {
    final generation = ++_animationGeneration;
    _paymentTimer?.cancel();
    cashRegisterState = CashRegisterState.closed;
    payment = config.payments[_random.nextInt(config.payments.length)];
    paymentIntroState = PaymentIntroState.waiting;
    paymentDecisionComplete = false;
    balanceNotes = const [];
    _nextBalanceNoteId = 0;
    state = ShoppingGameState.lottery;
    _cycleGoods();
    notifyListeners();
    final cycleCount =
        config.goodsLotteryDuration.inMicroseconds ~/
        config.goodsLotteryInterval.inMicroseconds;
    _scheduleLotteryStep(generation, cycleCount.clamp(1, 1000));
  }

  void _cycleGoods() {
    displayedGoods = List.unmodifiable([
      for (var i = 0; i < config.displayedGoodsCount; i++)
        config.goods[_random.nextInt(config.goods.length)],
    ]);
  }

  void _scheduleLotteryStep(int generation, int remainingCycles) {
    _paymentTimer = Timer(config.goodsLotteryInterval, () {
      if (generation != _animationGeneration) return;
      _cycleGoods();
      notifyListeners();
      if (remainingCycles > 1) {
        _scheduleLotteryStep(generation, remainingCycles - 1);
        return;
      }
      paymentIntroState = PaymentIntroState.incomingAtStart;
      notifyListeners();
      _schedulePaymentStep(
        generation,
        config.paymentAnimationStartDelay,
        PaymentIntroState.incoming,
      );
    });
  }

  void _schedulePaymentStep(
    int generation,
    Duration delay,
    PaymentIntroState nextState,
  ) {
    _paymentTimer?.cancel();
    _paymentTimer = Timer(delay, () {
      if (generation != _animationGeneration) return;
      paymentIntroState = nextState;
      notifyListeners();
      switch (nextState) {
        case PaymentIntroState.incoming:
          _schedulePaymentStep(
            generation,
            config.paymentAnimationDuration,
            PaymentIntroState.outgoingAtCenter,
          );
        case PaymentIntroState.outgoingAtCenter:
          _schedulePaymentStep(
            generation,
            config.paymentAnimationStartDelay,
            PaymentIntroState.outgoing,
          );
        case PaymentIntroState.outgoing:
          _schedulePaymentStep(
            generation,
            config.paymentAnimationDuration,
            PaymentIntroState.complete,
          );
        case PaymentIntroState.complete:
          state = ShoppingGameState.playing;
          notifyListeners();
          _paymentTimer = null;
        case PaymentIntroState.waiting || PaymentIntroState.incomingAtStart:
          _paymentTimer = null;
      }
    });
  }

  void toggleCashRegister() {
    if (!canUseCashRegister) return;
    cashRegisterState = cashRegisterState == CashRegisterState.closed
        ? CashRegisterState.open
        : CashRegisterState.closed;
    notifyListeners();
  }

  int get totalPrice => displayedGoods.fold(0, (sum, good) => sum + good.price);
  bool get paymentIsEnough => payment.value >= totalPrice;
  bool get canAnswerPayment =>
      state == ShoppingGameState.playing &&
      paymentIntroState == PaymentIntroState.complete &&
      !paymentDecisionComplete;
  bool get canUseCashRegister => canAnswerPayment;

  void answerPayment({required bool isEnough}) {
    if (!canAnswerPayment) return;
    paymentDecisionComplete = true;
    final correct = isEnough
        ? paymentIsEnough && balance == payment.value - totalPrice
        : !paymentIsEnough;
    _finishExercise(correct);
  }

  void _finishExercise(bool correct) {
    final generation = ++_animationGeneration;
    _paymentTimer?.cancel();
    if (correct) {
      score++;
      state = ShoppingGameState.correct;
      unawaited(_play(_correctPath));
    } else {
      incorrectAttempts++;
      state = ShoppingGameState.incorrect;
      unawaited(_play(_wrongPath));
    }
    notifyListeners();
    _paymentTimer = Timer(config.feedbackDuration, () {
      if (generation != _animationGeneration) return;
      if (score >= config.winningScore) {
        state = ShoppingGameState.won;
        notifyListeners();
      } else {
        _startExercise();
      }
    });
  }

  int get balance =>
      balanceNotes.fold(0, (sum, note) => sum + note.denomination.value);

  void addBalanceNote(int denominationIndex) {
    if (!canUseCashRegister ||
        cashRegisterState != CashRegisterState.open ||
        denominationIndex < 0 ||
        denominationIndex >= config.balanceDenominations.length) {
      return;
    }
    balanceNotes = List.unmodifiable([
      ...balanceNotes,
      ShoppingBalanceNote(
        id: _nextBalanceNoteId++,
        denomination: config.balanceDenominations[denominationIndex],
      ),
    ]);
    notifyListeners();
  }

  void removeBalanceNote(int noteId) {
    if (!canUseCashRegister) return;
    final updated = balanceNotes.where((note) => note.id != noteId).toList();
    if (updated.length == balanceNotes.length) return;
    balanceNotes = List.unmodifiable(updated);
    notifyListeners();
  }

  Future<void> _play(String path) async {
    try {
      await _audioPlayer.play(path);
    } catch (_) {
      // Audio feedback is optional; gameplay must continue without it.
    }
  }

  void stop() {
    _animationGeneration++;
    _paymentTimer?.cancel();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
