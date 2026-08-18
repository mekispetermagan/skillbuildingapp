import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/l10n.dart';
import '../models/balance_game.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/reward_gem_row.dart';

class BalanceGameScreen extends StatelessWidget {
  final BalanceGameViewData viewData;
  final VoidCallback onBack;
  final ValueChanged<int> onSelectStone;

  const BalanceGameScreen({
    required this.viewData,
    required this.onBack,
    required this.onSelectStone,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(
      title: context.l10n.activityBalanceGame,
      onBack: onBack,
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: viewData.config.stageSize.width,
                    height: viewData.config.stageSize.height,
                    child: _BalanceStage(
                      key: ValueKey(viewData.exerciseId),
                      viewData: viewData,
                      onSelectStone: onSelectStone,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            RewardGemRow(count: viewData.score),
          ],
        ),
      ),
    ),
  );
}

class _BalanceStage extends StatelessWidget {
  final BalanceGameViewData viewData;
  final ValueChanged<int> onSelectStone;

  const _BalanceStage({
    required this.viewData,
    required this.onSelectStone,
    super.key,
  });

  BalanceGameConfig get config => viewData.config;
  Duration get _animationDuration => config.outroAnimationDuration;
  Curve get _animationCurve => Cubic(
    config.outroAnimationCurve.x1,
    config.outroAnimationCurve.y1,
    config.outroAnimationCurve.x2,
    config.outroAnimationCurve.y2,
  );

  Offset get _scaleAnchor => _absolutePoint(config.scalePosition);
  Offset get _shelfTopCenter => _absolutePoint(config.shelfPosition);

  Offset _absolutePoint(BalancePosition position) => Offset(
    config.stageSize.width / 2 + position.x,
    config.stageSize.height / 2 - position.y,
  );

  Rect _topCenteredRect(Offset anchor, BalanceSize size) => Rect.fromLTWH(
    anchor.dx - size.width / 2,
    anchor.dy,
    size.width,
    size.height,
  );

  Rect _trayRect(BalancePosition position, double y) =>
      _topCenteredRect(_scaleAnchor + Offset(position.x, -y), config.traySize);

  Rect _trayItemRect({
    required int weight,
    required int index,
    required bool isGoods,
  }) {
    final trayPosition = isGoods
        ? config.leftTrayPosition
        : config.rightTrayPosition;
    final trayY = isGoods ? viewData.leftTrayY : viewData.rightTrayY;
    final relativePosition = config.trayItemPositions[index];
    final originalSize = isGoods
        ? config.goodsSizes[weight]!
        : config.stoneSizes[weight]!;
    return _bottomCenteredRect(
      anchor: _scaleAnchor + Offset(trayPosition.x, -trayY),
      relativePosition: relativePosition,
      size: originalSize,
    );
  }

  Rect _shelfItemRect(BalanceStone stone, int index) => _bottomCenteredRect(
    anchor: _shelfTopCenter,
    relativePosition: config.shelfItemPositions[index],
    size: config.stoneSizes[stone.weight]!,
  );

  Rect _bottomCenteredRect({
    required Offset anchor,
    required BalancePosition relativePosition,
    required BalanceSize size,
  }) {
    final width = size.width * config.itemScale;
    final height = size.height * config.itemScale;
    final bottomCenter =
        anchor + Offset(relativePosition.x, -relativePosition.y);
    return Rect.fromLTWH(
      bottomCenter.dx - width / 2,
      bottomCenter.dy - height,
      width,
      height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIds = {for (final stone in viewData.selectedStones) stone.id};
    final scaleRect = Rect.fromCenter(
      center: _scaleAnchor,
      width: config.scaleSize.width,
      height: config.scaleSize.height,
    );
    final handRect = Rect.fromLTWH(
      _scaleAnchor.dx,
      _scaleAnchor.dy - config.handSize.height / 2,
      config.handSize.width,
      config.handSize.height,
    );

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fromRect(
            rect: _topCenteredRect(_shelfTopCenter, config.shelfSize),
            child: SvgPicture.asset('assets/images/balance_game/shelf.svg'),
          ),
          for (final (index, stone) in viewData.shelfStones.indexed)
            if (!selectedIds.contains(stone.id))
              Positioned.fromRect(
                rect: _shelfItemRect(stone, index),
                child: Semantics(
                  button: true,
                  label: 'Stone ${stone.weight}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: viewData.canSelect
                        ? () => onSelectStone(stone.id)
                        : null,
                    child: SvgPicture.asset(
                      'assets/images/balance_game/d${stone.weight}.svg',
                    ),
                  ),
                ),
              ),
          AnimatedPositioned.fromRect(
            key: const ValueKey('left-tray'),
            rect: _trayRect(config.leftTrayPosition, viewData.leftTrayY),
            duration: _animationDuration,
            curve: _animationCurve,
            child: SvgPicture.asset('assets/images/balance_game/tray.svg'),
          ),
          AnimatedPositioned.fromRect(
            key: const ValueKey('right-tray'),
            rect: _trayRect(config.rightTrayPosition, viewData.rightTrayY),
            duration: _animationDuration,
            curve: _animationCurve,
            child: SvgPicture.asset('assets/images/balance_game/tray.svg'),
          ),
          for (final (index, weight) in viewData.goodsWeights.indexed)
            AnimatedPositioned.fromRect(
              key: ValueKey('goods-$index'),
              rect: _trayItemRect(weight: weight, index: index, isGoods: true),
              duration: _animationDuration,
              curve: _animationCurve,
              child: SvgPicture.asset(
                'assets/images/balance_game/c$weight.svg',
              ),
            ),
          for (final (index, stone) in viewData.selectedStones.indexed)
            AnimatedPositioned.fromRect(
              key: ValueKey('selected-stone-${stone.id}'),
              rect: _trayItemRect(
                weight: stone.weight,
                index: index,
                isGoods: false,
              ),
              duration: _animationDuration,
              curve: _animationCurve,
              child: SvgPicture.asset(
                'assets/images/balance_game/d${stone.weight}.svg',
              ),
            ),
          Positioned.fromRect(
            rect: scaleRect,
            child: SvgPicture.asset('assets/images/balance_game/scale.svg'),
          ),
          Positioned.fromRect(
            rect: handRect,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: viewData.handAngle, end: viewData.handAngle),
              duration: _animationDuration,
              curve: _animationCurve,
              child: SvgPicture.asset('assets/images/balance_game/hand.svg'),
              builder: (context, angle, child) => Transform.rotate(
                angle: angle,
                alignment: Alignment.centerLeft,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
