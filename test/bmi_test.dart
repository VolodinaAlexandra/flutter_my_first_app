import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_my_first_app/bmi.dart';

void main() {
  test('calculates BMI from centimetres and metres', () {
    final cm = BmiResult.tryCalculate('185', '77')!;
    final metres = BmiResult.tryCalculate('1,85', '77')!;
    expect(cm.value.toStringAsFixed(2), '22.50');
    expect(metres.heightCm, 185);
    expect(metres.value, cm.value);
    expect(cm.recommendation, contains('Норма'));
  });

  test('uses all specified category boundaries', () {
    expect(BmiResult.recommendationFor(16), contains('Выраженный'));
    expect(BmiResult.recommendationFor(16.01), contains('Недостаточная'));
    expect(BmiResult.recommendationFor(18.5), contains('Норма'));
    expect(BmiResult.recommendationFor(25), contains('Избыточная'));
    expect(BmiResult.recommendationFor(30), startsWith('Ожирение.'));
    expect(BmiResult.recommendationFor(35), contains('резкое'));
    expect(BmiResult.recommendationFor(40), contains('Очень резкое'));
  });

  test('rejects invalid values before saving', () {
    expect(BmiResult.tryCalculate('0', '77'), isNull);
    expect(BmiResult.tryCalculate('185', '0'), isNull);
    expect(BmiResult.tryCalculate('abc', '77'), isNull);
    expect(BmiResult.tryCalculate('185.5', '77'), isNull);
    expect(BmiResult.tryCalculate('185', '77.5'), isNull);
  });
}
