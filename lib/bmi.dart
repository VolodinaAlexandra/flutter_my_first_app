class BmiResult {
  const BmiResult({
    required this.heightCm,
    required this.weightKg,
    required this.value,
    required this.recommendation,
  });

  final int heightCm;
  final int weightKg;
  final double value;
  final String recommendation;

  static BmiResult? tryCalculate(String heightInput, String weightInput) {
    final rawHeight = double.tryParse(heightInput.trim().replaceAll(',', '.'));
    final weight = int.tryParse(weightInput.trim());
    if (rawHeight == null || !rawHeight.isFinite || weight == null) return null;
    // Numbers up to 3 are metres; larger numbers are centimetres.
    final heightCm = rawHeight <= 3
        ? (rawHeight * 100).round()
        : rawHeight.round();
    if (heightCm < 50 ||
        heightCm > 300 ||
        weight < 20 ||
        weight > 500 ||
        (rawHeight > 3 && rawHeight != heightCm)) {
      return null;
    }
    final metres = heightCm / 100;
    final bmi = weight / (metres * metres);
    return BmiResult(
      heightCm: heightCm,
      weightKg: weight,
      value: bmi,
      recommendation: recommendationFor(bmi),
    );
  }

  static String recommendationFor(double bmi) {
    if (bmi <= 16) {
      return 'Выраженный дефицит массы тела. Советуем набрать вес для здоровья.';
    }
    if (bmi < 18.5) {
      return 'Недостаточная масса тела. Рекомендуется увеличить массу тела.';
    }
    if (bmi < 25) {
      return 'Норма. Ваш вес в здоровом диапазоне — поддерживайте его!';
    }
    if (bmi < 30) {
      return 'Избыточная масса тела или предожирение. Желательно снизить вес для улучшения самочувствия.';
    }
    if (bmi < 35) {
      return 'Ожирение. Рекомендуется уменьшить вес под контролем специалиста.';
    }
    if (bmi < 40) {
      return 'Ожирение резкое. Необходимо снижение веса с медицинской поддержкой.';
    }
    return 'Очень резкое ожирение. Требуется срочная коррекция веса под наблюдением врача.';
  }
}
