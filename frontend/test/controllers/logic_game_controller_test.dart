import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:literacy_game/audio/asset_audio_player.dart';
import 'package:literacy_game/controllers/logic_game_controller.dart';
import 'package:literacy_game/models/logic_game.dart';

class _FakeAudioPlayer implements AssetAudioPlayer {
  final playedPaths = <String>[];

  @override
  Future<void> play(String assetPath) async => playedPaths.add(assetPath);

  @override
  Future<void> stop() async {}
}

void main() {
  test('creates five distinct objects and one property in easy mode', () {
    final controller = LogicGameController(
      _FakeAudioPlayer(),
      random: Random(1),
    );

    expect(controller.difficulty, LogicDifficulty.easy);
    expect(controller.objects, hasLength(5));
    expect(controller.objects.map((item) => item.id).toSet(), hasLength(5));
    expect(controller.properties, hasLength(1));
    expect(controller.placements, isEmpty);
  });

  test('difficulty selects distinct property kinds and preserves rewards', () {
    final controller = LogicGameController(
      _FakeAudioPlayer(),
      random: Random(2),
    );

    controller.setDifficulty(LogicDifficulty.medium);
    expect(controller.properties, hasLength(2));
    expect(
      controller.properties.map((item) => item.kind).toSet(),
      hasLength(2),
    );

    controller.setDifficulty(LogicDifficulty.hard);
    expect(controller.properties, hasLength(3));
    expect(
      controller.properties.map((item) => item.kind).toSet(),
      hasLength(3),
    );
    expect(controller.score, 0);
  });

  test('circle centers have radius spacing and a downward hard triangle', () {
    const config = LogicGameConfig();
    final medium = config.geometry(
      difficulty: LogicDifficulty.medium,
      width: 700,
      height: 350,
    );
    final hard = config.geometry(
      difficulty: LogicDifficulty.hard,
      width: 700,
      height: 350,
    );

    expect(
      _distance(medium.circles[0], medium.circles[1]),
      closeTo(medium.circles[0].radius, 0.0001),
    );
    expect(
      _distance(hard.circles[0], hard.circles[1]),
      closeTo(hard.circles[0].radius, 0.0001),
    );
    expect(
      _distance(hard.circles[0], hard.circles[2]),
      closeTo(hard.circles[0].radius, 0.0001),
    );
    expect(hard.circles[2].center.y, greaterThan(hard.circles[0].center.y));
  });

  test('locks a placement and reports incorrect membership', () async {
    final controller = LogicGameController(
      _FakeAudioPlayer(),
      random: Random(3),
    );
    const width = 700.0;
    const height = 350.0;
    final object = controller.objects.first;
    final expectsInside = controller.properties.single.matches(object);
    final geometry = controller.config.geometry(
      difficulty: controller.difficulty,
      width: width,
      height: height,
    );
    final wrongPosition = expectsInside
        ? const LogicPoint(10, 10)
        : geometry.circles.single.center;

    await controller.place(
      objectId: object.id,
      position: wrongPosition,
      diagramWidth: width,
      diagramHeight: height,
    );
    await controller.place(
      objectId: object.id,
      position: geometry.circles.single.center,
      diagramWidth: width,
      diagramHeight: height,
    );

    expect(controller.placements, hasLength(1));
    expect(controller.placements.single.isCorrect, isFalse);
    expect(controller.incorrectAttempts, 1);
  });

  test('five correct placements award a reward and can win', () async {
    final audio = _FakeAudioPlayer();
    final controller = LogicGameController(
      audio,
      config: const LogicGameConfig(
        winningScore: 1,
        exerciseFeedbackDuration: Duration.zero,
      ),
      random: Random(4),
    );
    controller.setDifficulty(LogicDifficulty.hard);
    const width = 700.0;
    const height = 350.0;
    final geometry = controller.config.geometry(
      difficulty: controller.difficulty,
      width: width,
      height: height,
    );

    for (final object in controller.objects) {
      final membership = [
        for (final property in controller.properties) property.matches(object),
      ];
      final position = _findPoint(geometry, membership);
      await controller.place(
        objectId: object.id,
        position: position,
        diagramWidth: width,
        diagramHeight: height,
      );
    }

    expect(controller.state, LogicGameState.won);
    expect(controller.score, 1);
    expect(controller.incorrectAttempts, 0);
    expect(audio.playedPaths.last, contains('fanfare'));
  });
}

double _distance(LogicCircle first, LogicCircle second) {
  final dx = first.center.x - second.center.x;
  final dy = first.center.y - second.center.y;
  return sqrt(dx * dx + dy * dy);
}

LogicPoint _findPoint(LogicDiagramGeometry geometry, List<bool> membership) {
  for (var y = 2.0; y < geometry.height; y += 2) {
    for (var x = 2.0; x < geometry.width; x += 2) {
      final point = LogicPoint(x, y);
      final actual = [
        for (final circle in geometry.circles)
          _pointDistance(point, circle.center) <= circle.radius,
      ];
      if (listEquals(actual, membership)) return point;
    }
  }
  throw StateError('No diagram region matches $membership');
}

double _pointDistance(LogicPoint first, LogicPoint second) {
  final dx = first.x - second.x;
  final dy = first.y - second.y;
  return sqrt(dx * dx + dy * dy);
}
