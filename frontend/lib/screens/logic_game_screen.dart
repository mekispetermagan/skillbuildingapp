import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/l10n.dart';
import '../models/logic_game.dart';
import '../models/view_data.dart';
import '../widgets/feature_app_bar.dart';
import '../widgets/reward_gem_row.dart';
import '../widgets/single_select_segments.dart';

typedef LogicPlacementCallback =
    void Function({
      required int objectId,
      required LogicPoint position,
      required double diagramWidth,
      required double diagramHeight,
    });

class LogicGameScreen extends StatelessWidget {
  final LogicGameViewData viewData;
  final VoidCallback onBack;
  final ValueChanged<LogicDifficulty> onSetDifficulty;
  final LogicPlacementCallback onPlace;

  const LogicGameScreen({
    required this.viewData,
    required this.onBack,
    required this.onSetDifficulty,
    required this.onPlace,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FeatureAppBar(
      title: context.l10n.activityLogicGame,
      onBack: onBack,
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SingleSelectSegments<LogicDifficulty>(
              choices: [
                SegmentChoice(
                  value: LogicDifficulty.easy,
                  label: context.l10n.difficultyEasy,
                ),
                SegmentChoice(
                  value: LogicDifficulty.medium,
                  label: context.l10n.difficultyMedium,
                ),
                SegmentChoice(
                  value: LogicDifficulty.hard,
                  label: context.l10n.difficultyHard,
                ),
              ],
              selected: viewData.difficulty,
              onSelected: onSetDifficulty,
            ),
            const SizedBox(height: 12),
            _ObjectRow(viewData: viewData),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: AspectRatio(
                    aspectRatio: viewData.config.diagramAspectRatio,
                    child: _DiagramDropTarget(
                      viewData: viewData,
                      onPlace: onPlace,
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

class _ObjectRow extends StatelessWidget {
  final LogicGameViewData viewData;

  const _ObjectRow({required this.viewData});

  @override
  Widget build(BuildContext context) {
    final placements = {
      for (final placement in viewData.placements)
        placement.objectId: placement,
    };
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final object in viewData.objects)
          SizedBox.square(
            dimension: viewData.config.objectSize,
            child: switch (placements[object.id]) {
              LogicPlacement placement => Center(
                child: Text(
                  placement.isCorrect ? '✅' : '❌',
                  style: const TextStyle(fontSize: 34),
                ),
              ),
              null => Draggable<int>(
                data: object.id,
                maxSimultaneousDrags: viewData.canPlace ? 1 : 0,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: Material(
                  color: Colors.transparent,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -1),
                    child: SizedBox.square(
                      dimension: viewData.config.objectSize,
                      child: _ObjectImage(object: object),
                    ),
                  ),
                ),
                childWhenDragging: const SizedBox.shrink(),
                child: _ObjectImage(object: object),
              ),
            },
          ),
      ],
    );
  }
}

class _DiagramDropTarget extends StatefulWidget {
  final LogicGameViewData viewData;
  final LogicPlacementCallback onPlace;

  const _DiagramDropTarget({required this.viewData, required this.onPlace});

  @override
  State<_DiagramDropTarget> createState() => _DiagramDropTargetState();
}

class _DiagramDropTargetState extends State<_DiagramDropTarget> {
  final _targetKey = GlobalKey();

  @override
  Widget build(BuildContext context) => DragTarget<int>(
    key: _targetKey,
    onWillAcceptWithDetails: (_) => widget.viewData.canPlace,
    onAcceptWithDetails: (details) {
      final box = _targetKey.currentContext!.findRenderObject()! as RenderBox;
      final size = box.size;
      final dropPosition = box.globalToLocal(details.offset);
      widget.onPlace(
        objectId: details.data,
        position: LogicPoint(dropPosition.dx, dropPosition.dy),
        diagramWidth: size.width,
        diagramHeight: size.height,
      );
    },
    builder: (context, _, _) => LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final geometry = widget.viewData.config.geometry(
          difficulty: widget.viewData.difficulty,
          width: size.width,
          height: size.height,
        );
        final objectsById = {
          for (final object in widget.viewData.objects) object.id: object,
        };
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _VennPainter(geometry.circles)),
              ),
              for (final (index, property)
                  in widget.viewData.properties.indexed)
                _PropertyLabel(
                  property: property,
                  circle: geometry.circles[index],
                  below:
                      widget.viewData.difficulty == LogicDifficulty.hard &&
                      index == 2,
                  gap: widget.viewData.config.labelGap,
                  size: widget.viewData.config.labelSize,
                ),
              for (final placement in widget.viewData.placements)
                Positioned(
                  left:
                      placement.position.x -
                      widget.viewData.config.objectSize / 2,
                  top: placement.position.y - widget.viewData.config.objectSize,
                  width: widget.viewData.config.objectSize,
                  height: widget.viewData.config.objectSize,
                  child: _ObjectImage(object: objectsById[placement.objectId]!),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _ObjectImage extends StatelessWidget {
  final LogicObject object;

  const _ObjectImage({required this.object});

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/images/logic_game/obj_${object.assetCode}.svg',
    fit: BoxFit.contain,
  );
}

class _PropertyLabel extends StatelessWidget {
  final LogicProperty property;
  final LogicCircle circle;
  final bool below;
  final double gap;
  final double size;

  const _PropertyLabel({
    required this.property,
    required this.circle,
    required this.below,
    required this.gap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) => Positioned(
    left: circle.center.x - size / 2,
    top: below
        ? circle.center.y + circle.radius + gap
        : circle.center.y - circle.radius - gap - size,
    width: size,
    height: size,
    child: switch (property.kind) {
      LogicPropertyKind.character => SvgPicture.asset(
        'assets/images/logic_game/label_0${property.value}.svg',
      ),
      LogicPropertyKind.color => DecoratedBox(
        decoration: BoxDecoration(
          color: _objectColors[property.value],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2),
        ),
      ),
      LogicPropertyKind.sunglasses => SvgPicture.asset(
        'assets/images/logic_game/label_2.svg',
      ),
      LogicPropertyKind.bicycle => SvgPicture.asset(
        'assets/images/logic_game/label_3.svg',
      ),
    },
  );
}

const _objectColors = [
  Color(0xFFF44336),
  Color(0xFFFFEB3B),
  Color(0xFF2196F3),
  Color(0xFF4CAF50),
];

class _VennPainter extends CustomPainter {
  final List<LogicCircle> circles;

  const _VennPainter(this.circles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final (index, circle) in circles.indexed) {
      final center = Offset(circle.center.x, circle.center.y);
      canvas.drawCircle(
        center,
        circle.radius,
        Paint()
          ..color = _objectColors[index].withValues(alpha: 0.16)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        circle.radius,
        Paint()
          ..color = const Color(0xFF424242)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_VennPainter oldDelegate) =>
      oldDelegate.circles != circles;
}
