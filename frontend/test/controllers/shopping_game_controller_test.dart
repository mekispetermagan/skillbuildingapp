import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/audio/asset_audio_player.dart';
import 'package:literacy_game/controllers/shopping_game_controller.dart';
import 'package:literacy_game/models/shopping_game.dart';

class _FakeAudioPlayer implements AssetAudioPlayer {
  final played = <String>[];

  @override
  Future<void> play(String assetPath) async => played.add(assetPath);

  @override
  Future<void> stop() async {}
}

ShoppingGameConfig _fastConfig({
  List<ShoppingGood>? goods,
  List<ShoppingPayment>? payments,
  int winningScore = 10,
}) => ShoppingGameConfig(
  goods: goods ?? shoppingGameConfig.goods,
  payments: payments ?? shoppingGameConfig.payments,
  winningScore: winningScore,
  goodsLotteryDuration: const Duration(milliseconds: 1),
  goodsLotteryInterval: const Duration(milliseconds: 1),
  paymentAnimationDuration: Duration.zero,
  paymentAnimationStartDelay: Duration.zero,
  feedbackDuration: const Duration(milliseconds: 1),
);

Future<void> _finishIntro(ShoppingGameController controller) async {
  controller.start();
  await Future<void>.delayed(const Duration(milliseconds: 20));
  expect(controller.state, ShoppingGameState.playing);
}

void main() {
  test('lottery settles on three goods with repetition allowed', () async {
    final onlyGood = shoppingGameConfig.goods.first;
    final controller = ShoppingGameController(
      _FakeAudioPlayer(),
      config: _fastConfig(goods: [onlyGood]),
      random: Random(1),
    );

    await _finishIntro(controller);

    expect(controller.displayedGoods, [onlyGood, onlyGood, onlyGood]);
    controller.dispose();
  });

  test('cash register toggles after a sufficient payment', () async {
    final controller = ShoppingGameController(
      _FakeAudioPlayer(),
      config: _fastConfig(
        goods: [shoppingGameConfig.goods.first],
        payments: [shoppingGameConfig.payments.last],
      ),
      random: Random(1),
    );
    await _finishIntro(controller);

    expect(controller.cashRegisterState, CashRegisterState.closed);
    controller.toggleCashRegister();
    expect(controller.cashRegisterState, CashRegisterState.open);
    controller.toggleCashRegister();
    expect(controller.cashRegisterState, CashRegisterState.closed);
    controller.dispose();
  });

  test('correct insufficient decision rewards and can win', () async {
    final audio = _FakeAudioPlayer();
    final controller = ShoppingGameController(
      audio,
      config: _fastConfig(
        goods: [shoppingGameConfig.goods.last],
        payments: [shoppingGameConfig.payments.first],
        winningScore: 1,
      ),
      random: Random(2),
    );
    await _finishIntro(controller);

    expect(controller.paymentIsEnough, isFalse);
    controller.toggleCashRegister();
    expect(controller.cashRegisterState, CashRegisterState.open);
    controller.answerPayment(isEnough: false);
    expect(controller.state, ShoppingGameState.correct);
    expect(controller.score, 1);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(controller.state, ShoppingGameState.won);
    expect(audio.played, isNotEmpty);
    controller.dispose();
  });

  test('register notes add to and remove from the running balance', () async {
    final controller = ShoppingGameController(
      _FakeAudioPlayer(),
      config: _fastConfig(
        goods: [shoppingGameConfig.goods.first],
        payments: [shoppingGameConfig.payments.last],
      ),
      random: Random(3),
    );
    await _finishIntro(controller);

    controller.addBalanceNote(1);
    expect(controller.balanceNotes, isEmpty);

    controller.toggleCashRegister();
    controller.addBalanceNote(0);
    controller.addBalanceNote(2);
    controller.addBalanceNote(2);
    expect(controller.balance, 11000);

    controller.removeBalanceNote(controller.balanceNotes[1].id);
    expect(controller.balance, 6000);
    expect(controller.balanceNotes, hasLength(2));
    controller.dispose();
  });

  test(
    'incorrect submitted balance fails and starts another exercise',
    () async {
      final controller = ShoppingGameController(
        _FakeAudioPlayer(),
        config: _fastConfig(
          goods: [shoppingGameConfig.goods.first],
          payments: [shoppingGameConfig.payments.last],
        ),
        random: Random(4),
      );
      await _finishIntro(controller);

      controller.answerPayment(isEnough: true);
      expect(controller.state, ShoppingGameState.incorrect);
      expect(controller.incorrectAttempts, 1);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      expect(controller.state, ShoppingGameState.lottery);
      expect(controller.balanceNotes, isEmpty);
      expect(controller.cashRegisterState, CashRegisterState.closed);
      controller.dispose();
    },
  );
}
