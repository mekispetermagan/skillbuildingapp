import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/shopping_game.dart';
import '../models/view_data.dart';
import '../theme/feature_palette.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/reward_gem_row.dart';

class ShoppingGameScreen extends StatelessWidget {
  final ShoppingGameViewData viewData;
  final VoidCallback onBack;
  final VoidCallback onToggleCashRegister;
  final VoidCallback onNotEnough;
  final VoidCallback onTakeBalance;
  final ValueChanged<int> onAddBalanceNote;
  final ValueChanged<int> onRemoveBalanceNote;

  const ShoppingGameScreen({
    required this.viewData,
    required this.onBack,
    required this.onToggleCashRegister,
    required this.onNotEnough,
    required this.onTakeBalance,
    required this.onAddBalanceNote,
    required this.onRemoveBalanceNote,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(
      title: context.l10n.activityShoppingGame,
      onBack: onBack,
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: ClipRect(
                    child: SizedBox.fromSize(
                      key: const ValueKey('shopping-game-stage'),
                      size: Size(
                        viewData.config.stageSize.width,
                        viewData.config.stageSize.height,
                      ),
                      child: _ShoppingStage(
                        viewData: viewData,
                        onToggleCashRegister: onToggleCashRegister,
                        onAddBalanceNote: onAddBalanceNote,
                        onRemoveBalanceNote: onRemoveBalanceNote,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  Expanded(
                    child: _DecisionButton(
                      label: context.l10n.notEnough,
                      colorScheme: FeaturePalette.schemeForIndex(4),
                      onPressed: viewData.canAnswerPayment ? onNotEnough : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DecisionButton(
                      label: context.l10n.takeTheBalance,
                      colorScheme: FeaturePalette.schemeForIndex(1),
                      onPressed: viewData.canAnswerPayment
                          ? onTakeBalance
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            RewardGemRow(count: viewData.score),
          ],
        ),
      ),
    ),
  );
}

class _ShoppingStage extends StatelessWidget {
  final ShoppingGameViewData viewData;
  final VoidCallback onToggleCashRegister;
  final ValueChanged<int> onAddBalanceNote;
  final ValueChanged<int> onRemoveBalanceNote;

  const _ShoppingStage({
    required this.viewData,
    required this.onToggleCashRegister,
    required this.onAddBalanceNote,
    required this.onRemoveBalanceNote,
  });

  Rect _rotatedCenteredRect(
    ShoppingPosition position,
    ShoppingSize originalSize,
    double scale,
  ) {
    final config = viewData.config;
    final center = Offset(
      config.stageSize.width / 2 + position.x,
      config.stageSize.height / 2 - position.y,
    );
    return Rect.fromCenter(
      center: center,
      width: originalSize.height * scale,
      height: originalSize.width * scale,
    );
  }

  Rect _centeredRect(
    ShoppingPosition position,
    ShoppingSize originalSize,
    double scale,
  ) {
    final config = viewData.config;
    final width = originalSize.width * scale;
    final height = originalSize.height * scale;
    final center = Offset(
      config.stageSize.width / 2 + position.x,
      config.stageSize.height / 2 - position.y,
    );
    return Rect.fromCenter(center: center, width: width, height: height);
  }

  Rect _centerLeftRect(ShoppingPosition position, ShoppingSize originalSize) {
    final config = viewData.config;
    final width = originalSize.width * config.spriteScale;
    final height = originalSize.height * config.spriteScale;
    final centerLeft = Offset(
      config.stageSize.width / 2 + position.x,
      config.stageSize.height / 2 - position.y,
    );
    return Rect.fromLTWH(
      centerLeft.dx,
      centerLeft.dy - height / 2,
      width,
      height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = viewData.config;
    final position = viewData.cashRegisterState == CashRegisterState.closed
        ? config.cashRegisterClosedCenter
        : config.cashRegisterOpenCenter;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        for (final (index, good) in viewData.displayedGoods.indexed)
          Positioned.fromRect(
            key: ValueKey('shopping-good-$index'),
            rect: _centeredRect(
              config.goodsPositions[index],
              good.originalSize,
              config.goodsScale,
            ),
            child: Image.asset(good.assetPath, fit: BoxFit.fill),
          ),
        AnimatedPositioned.fromRect(
          key: const ValueKey('cash-register'),
          rect: _rotatedCenteredRect(
            position,
            config.cashRegisterSize,
            config.spriteScale,
          ),
          duration: config.cashRegisterAnimationDuration,
          child: RotatedBox(
            quarterTurns: 3,
            child: _CashRegister(
              assetPath: config.cashRegisterAssetPath,
              state: viewData.cashRegisterState,
              denominationAreaFraction:
                  config.cashRegisterDenominationAreaFraction,
              denominationCount: config.balanceDenominations.length,
              onToggle: onToggleCashRegister,
              onSelectDenomination: onAddBalanceNote,
            ),
          ),
        ),
        if (viewData.paymentIntroState == PaymentIntroState.outgoingAtCenter ||
            viewData.paymentIntroState == PaymentIntroState.outgoing ||
            viewData.paymentIntroState == PaymentIntroState.complete)
          Positioned.fromRect(
            key: const ValueKey('payment-note'),
            rect: _centerLeftRect(
              config.paymentEndPosition,
              viewData.payment.noteOriginalSize,
            ),
            child: Image.asset(
              viewData.payment.noteAssetPath,
              fit: BoxFit.fill,
            ),
          ),
        if (viewData.paymentIntroState != PaymentIntroState.waiting &&
            viewData.paymentIntroState != PaymentIntroState.complete)
          AnimatedPositioned.fromRect(
            key: ValueKey(
              viewData.paymentIntroState == PaymentIntroState.incomingAtStart ||
                      viewData.paymentIntroState == PaymentIntroState.incoming
                  ? 'payment-hand-incoming'
                  : 'payment-hand-outgoing',
            ),
            rect: _centerLeftRect(
              viewData.paymentIntroState == PaymentIntroState.incomingAtStart ||
                      viewData.paymentIntroState == PaymentIntroState.outgoing
                  ? config.paymentStartPosition
                  : config.paymentEndPosition,
              viewData.paymentIntroState == PaymentIntroState.incomingAtStart ||
                      viewData.paymentIntroState == PaymentIntroState.incoming
                  ? viewData.payment.handOriginalSize
                  : config.emptyHandSize,
            ),
            duration: config.paymentAnimationDuration,
            child: Image.asset(
              viewData.paymentIntroState == PaymentIntroState.incomingAtStart ||
                      viewData.paymentIntroState == PaymentIntroState.incoming
                  ? viewData.payment.handAssetPath
                  : config.emptyHandAssetPath,
              fit: BoxFit.fill,
            ),
          ),
        for (final (index, note) in viewData.balanceNotes.indexed)
          Positioned.fromRect(
            key: ValueKey('balance-note-${note.id}'),
            rect: _centeredRect(
              ShoppingPosition(
                config.balanceFirstPosition.x +
                    index * config.balancePositionSpacing,
                config.balanceFirstPosition.y,
              ),
              note.denomination.originalSize,
              config.balanceNoteScale,
            ),
            child: Semantics(
              button: true,
              label: 'Remove ${note.denomination.value}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onRemoveBalanceNote(note.id),
                child: Image.asset(
                  note.denomination.assetPath,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CashRegister extends StatelessWidget {
  final String assetPath;
  final CashRegisterState state;
  final double denominationAreaFraction;
  final int denominationCount;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelectDenomination;

  const _CashRegister({
    required this.assetPath,
    required this.state,
    required this.denominationAreaFraction,
    required this.denominationCount,
    required this.onToggle,
    required this.onSelectDenomination,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cash register',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final size = context.size!;
        if (details.localPosition.dx >= size.width * denominationAreaFraction) {
          onToggle();
          return;
        }
        if (state != CashRegisterState.open) return;
        final rowHeight = size.height / denominationCount;
        final index = (details.localPosition.dy / rowHeight).floor().clamp(
          0,
          denominationCount - 1,
        );
        onSelectDenomination(index);
      },
      child: Image.asset(assetPath, fit: BoxFit.fill),
    ),
  );
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;
  final VoidCallback? onPressed;

  const _DecisionButton({
    required this.label,
    required this.colorScheme,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    onPressed: onPressed,
    child: Text(label, textAlign: TextAlign.center),
  );
}
