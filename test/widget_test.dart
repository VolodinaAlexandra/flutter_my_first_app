import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_my_first_app/bmi.dart';
import 'package:flutter_my_first_app/calculation_repository.dart';
import 'package:flutter_my_first_app/main.dart';
import 'package:flutter_my_first_app/screens.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MemoryRepository extends CalculationRepository {
  _MemoryRepository()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  BmiResult? saved;
  List<CalculationRecord> records = [];

  @override
  Future<void> save(BmiResult result) async {
    saved = result;
  }

  @override
  Future<List<CalculationRecord>> list() async => records;
}

void main() {
  testWidgets('login and registration forms expose required fields', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Вход в приложение'), findsOneWidget);
    expect(find.text('ВОЙТИ'), findsOneWidget);

    await tester.tap(find.text('Зарегистрироваться'));
    await tester.pump();
    expect(find.text('Регистрация'), findsOneWidget);
    expect(find.text('СОЗДАТЬ АККАУНТ'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('calculator displays and saves the calculated result', (
    tester,
  ) async {
    final repository = _MemoryRepository();
    var notified = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalculatorPage(
            repository: repository,
            onSaved: () => notified = true,
          ),
        ),
      ),
    );

    expect(find.text('Личные сведения'), findsOneWidget);
    expect(find.text('190'), findsOneWidget);
    expect(find.text('85'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '185');
    await tester.enterText(find.byType(TextFormField).at(1), '77');
    await tester.tap(find.text('РАССЧИТАТЬ'));
    await tester.pumpAndSettle();

    expect(find.text('22.50'), findsOneWidget);
    expect(find.textContaining('Норма.'), findsOneWidget);
    expect(repository.saved?.heightCm, 185);
    expect(notified, isTrue);
  });

  testWidgets('profile keeps calculation history in one divided card', (
    tester,
  ) async {
    final repository = _MemoryRepository()
      ..records = [
        CalculationRecord(
          createdAt: DateTime(2026, 10, 1, 13, 45),
          heightCm: 190,
          weightKg: 85,
          bmi: 23.55,
          recommendation: 'Рекомендация 1',
        ),
        CalculationRecord(
          createdAt: DateTime(2026, 9, 30, 8, 0),
          heightCm: 185,
          weightKg: 77,
          bmi: 22.50,
          recommendation: 'Рекомендация 2',
        ),
      ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePage(
            client: repository.client,
            repository: repository,
            historyVersion: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('История расчетов'), findsOneWidget);
    expect(find.text('Активность'), findsNothing);
    expect(find.text('1 октября 2026 год, 13:45'), findsOneWidget);
    expect(find.byType(AppCard), findsNWidgets(2));
    expect(find.byType(Divider), findsNWidgets(2));
  });
}
