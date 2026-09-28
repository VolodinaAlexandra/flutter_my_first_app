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

  @override
  Future<void> save(BmiResult result) async {
    saved = result;
  }
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

    await tester.enterText(find.byType(TextFormField).at(0), '185');
    await tester.enterText(find.byType(TextFormField).at(1), '77');
    await tester.tap(find.text('РАССЧИТАТЬ'));
    await tester.pumpAndSettle();

    expect(find.text('22.50'), findsOneWidget);
    expect(find.textContaining('Норма.'), findsOneWidget);
    expect(repository.saved?.heightCm, 185);
    expect(notified, isTrue);
  });
}
