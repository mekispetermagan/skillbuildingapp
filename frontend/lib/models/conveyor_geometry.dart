import 'conveyor_config.dart';

abstract interface class ConveyorGeometry {
  ConveyorConfig get config;
  double get width;
  double get height;
  double get leftBeltX;
  double get rightBeltX;
  double get leftBeltWidth;
}
