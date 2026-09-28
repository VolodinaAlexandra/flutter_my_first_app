import 'package:supabase_flutter/supabase_flutter.dart';

import 'bmi.dart';

class CalculationRecord {
  const CalculationRecord({
    required this.createdAt,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    required this.recommendation,
  });

  final DateTime createdAt;
  final int heightCm;
  final int weightKg;
  final double bmi;
  final String recommendation;

  factory CalculationRecord.fromJson(Map<String, dynamic> json) =>
      CalculationRecord(
        createdAt: DateTime.parse(json['created_at'] as String),
        heightCm: (json['height'] as num).toInt(),
        weightKg: (json['weight'] as num).toInt(),
        bmi: (json['body_mass_index'] as num).toDouble(),
        recommendation: json['recommendation'] as String? ?? '',
      );
}

class CalculationRepository {
  const CalculationRepository(this.client);

  final SupabaseClient client;

  String get _userId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw StateError('Пользователь не авторизован');
    return id;
  }

  Future<void> save(BmiResult result) async {
    await client.from('body_mass_index_calculations').insert({
      'height': result.heightCm,
      'weight': result.weightKg,
      'body_mass_index': result.value,
      'recommendation': result.recommendation,
      'user_id': _userId,
    });
  }

  Future<List<CalculationRecord>> list() async {
    final rows = await client
        .from('body_mass_index_calculations')
        .select('created_at,height,weight,body_mass_index,recommendation')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows.map(CalculationRecord.fromJson).toList();
  }
}
