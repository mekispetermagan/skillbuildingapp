import 'operations_practice.dart';
import 'operator_conveyor_world.dart';

class MathNotation {
  final String multiplicationSymbol;
  final String divisionSymbol;

  const MathNotation({
    this.multiplicationSymbol = '×',
    this.divisionSymbol = '÷',
  });

  String elementaryOperatorSymbol(ElementaryOperator operator) =>
      switch (operator) {
        ElementaryOperator.addition => '+',
        ElementaryOperator.subtraction => '−',
        ElementaryOperator.multiplication => multiplicationSymbol,
        ElementaryOperator.division => divisionSymbol,
      };

  String arithmeticOperatorSymbol(ArithmeticOperator operator) =>
      switch (operator) {
        ArithmeticOperator.add => '+',
        ArithmeticOperator.subtract => '−',
        ArithmeticOperator.multiply => multiplicationSymbol,
        ArithmeticOperator.divide => divisionSymbol,
      };
}

const westernMathNotation = MathNotation();
const hungarianMathNotation = MathNotation(
  multiplicationSymbol: '·',
  divisionSymbol: ':',
);
