import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bmi.dart';
import 'calculation_repository.dart';

const appGreen = Color(0xFF49B252);
const appBackground = Color(0xFFF7F7F7);
const _muted = Color(0xFF888888);
const _error = Color(0xFFD66B6B);

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.client});

  final SupabaseClient? client;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _registering = !_registering;
      _message = null;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final client = widget.client;
    if (client == null) {
      setState(() => _message = 'Укажите параметры Supabase для подключения.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_registering) {
        final response = await client.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {
            'first_name': _firstName.text.trim(),
            'last_name': _lastName.text.trim(),
          },
        );
        if (mounted && response.session == null) {
          setState(
            () => _message = 'Аккаунт создан, но автоматический вход недоступен. Обратитесь к администратору приложения.',
          );
        }
      } else {
        await client.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = _authError(e));
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _message = 'Не удалось связаться с сервером. Повторите попытку.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _authError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login')) return 'Неверный email или пароль!';
    if (message.contains('already registered')) {
      return 'Этот email уже зарегистрирован.';
    }
    if (message.contains('email not confirmed')) {
      return 'Аккаунт ожидает активации. Обратитесь к администратору приложения.';
    }
    if (message.contains('password')) return 'Проверьте пароль: ${e.message}';
    return e.message;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                children: [
                  SizedBox(height: height * (_registering ? .16 : .18)),
                  Text(
                    _registering ? 'Регистрация' : 'Вход в приложение',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: appGreen,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_registering) ...[
                            AppField(
                              label: 'Имя',
                              hint: 'Введите ваше имя',
                              controller: _firstName,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => _requiredName(v, 'имя'),
                            ),
                            AppField(
                              label: 'Фамилия',
                              hint: 'Введите вашу фамилию',
                              controller: _lastName,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => _requiredName(v, 'фамилию'),
                            ),
                          ],
                          AppField(
                            label: 'Email',
                            hint: 'example@gmail.com',
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final email = v?.trim() ?? '';
                              return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(email)
                                  ? null
                                  : 'Введите корректный email';
                            },
                          ),
                          AppField(
                            label: 'Пароль',
                            hint: 'Введите пароль',
                            controller: _password,
                            obscureText: true,
                            validator: (v) => (v?.length ?? 0) >= 6
                                ? null
                                : 'Пароль должен содержать не менее 6 символов',
                          ),
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: _busy ? null : _switchMode,
                            child: Text(
                              _registering
                                  ? 'Вернуться к странице входа'
                                  : 'Зарегистрироваться',
                              style: const TextStyle(
                                color: appGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  GreenButton(
                    label: _registering ? 'СОЗДАТЬ АККАУНТ' : 'ВОЙТИ',
                    busy: _busy,
                    onPressed: _submit,
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _error, fontSize: 12),
                    ),
                  ],
                  if (widget.client == null) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Для входа передайте SUPABASE_URL и SUPABASE_PUBLISHABLE_KEY при запуске.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredName(String? value, String label) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Введите $label';
    if (name.length > 60) return 'Не более 60 символов';
    return null;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.client});

  final SupabaseClient client;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  int _historyVersion = 0;

  @override
  Widget build(BuildContext context) {
    final repository = CalculationRepository(widget.client);
    return Scaffold(
      body: SafeArea(
        child: _tab == 0
            ? CalculatorPage(
                repository: repository,
                onSaved: () => setState(() => _historyVersion++),
              )
            : ProfilePage(
                client: widget.client,
                repository: repository,
                historyVersion: _historyVersion,
              ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 62,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 8)],
          ),
          child: Row(
            children: [_navItem('Калькулятор', 0), _navItem('Профиль', 1)],
          ),
        ),
      ),
    );
  }

  Widget _navItem(String label, int index) => Expanded(
    child: TextButton(
      onPressed: () => setState(() => _tab = index),
      child: Text(
        label,
        style: TextStyle(
          color: _tab == index ? const Color(0xFF333333) : _muted,
          fontSize: 14,
        ),
      ),
    ),
  );
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({
    super.key,
    required this.repository,
    required this.onSaved,
  });

  final CalculationRepository repository;
  final VoidCallback onSaved;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _height = TextEditingController();
  final _weight = TextEditingController();
  BmiResult? _result;
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    FocusScope.of(context).unfocus();
    final result = BmiResult.tryCalculate(_height.text, _weight.text);
    if (result == null) {
      setState(() {
        _result = null;
        _message = 'Введите рост от 50 до 300 см и вес от 20 до 500 кг.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.repository.save(result);
      if (!mounted) return;
      setState(() => _result = result);
      widget.onSaved();
    } catch (_) {
      if (mounted) {
        setState(() {
          _result = result;
          _message = 'Результат рассчитан, но не сохранён. Проверьте интернет и доступ к таблице.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            children: [
              SizedBox(height: height * .15),
              const Text(
                'Индекс массы тела',
                style: TextStyle(
                  color: appGreen,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Личные сведения',
                      style: TextStyle(
                        color: appGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppField(
                      label: 'Рост (см)',
                      hint: '190',
                      controller: _height,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    AppField(
                      label: 'Вес (кг)',
                      hint: '85',
                      controller: _weight,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GreenButton(
                label: 'РАССЧИТАТЬ',
                busy: _busy,
                onPressed: _calculate,
              ),
              if (_message != null) ...[
                const SizedBox(height: 14),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _error, fontSize: 12),
                ),
              ],
              if (_result != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7E9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x25000000),
                        blurRadius: 9,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ваш индекс массы тела:',
                          style: TextStyle(
                            color: appGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _result!.value.toStringAsFixed(2),
                        style: const TextStyle(
                          color: appGreen,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _result!.recommendation,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.client,
    required this.repository,
    required this.historyVersion,
  });

  final SupabaseClient client;
  final CalculationRepository repository;
  final int historyVersion;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<List<CalculationRecord>> _history;

  @override
  void initState() {
    super.initState();
    _history = widget.repository.list();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.historyVersion != widget.historyVersion) {
      _history = widget.repository.list();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.client.auth.currentUser;
    final first = (user?.userMetadata?['first_name'] as String?)?.trim() ?? '';
    final last = (user?.userMetadata?['last_name'] as String?)?.trim() ?? '';
    final name = '$first $last'.trim();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: RefreshIndicator(
          onRefresh: () async {
            final future = widget.repository.list();
            setState(() => _history = future);
            await future;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(26, 36, 26, 28),
            children: [
              AppCard(
                child: Column(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Transform.scale(
                          scale: 1.7,
                          alignment: const Alignment(0, -0.5),
                          child: Image.asset(
                            'assets/profile_avatar.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name.isEmpty ? 'Пользователь' : name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async => widget.client.auth.signOut(),
                      child: const Text(
                        'Выйти',
                        style: TextStyle(color: appGreen),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'История расчетов',
                      style: TextStyle(
                        color: appGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(height: 30, color: Color(0xFFD0D0D0)),
                    FutureBuilder<List<CalculationRecord>>(
                      future: _history,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Column(
                            children: [
                              const Text('Не удалось загрузить историю.'),
                              TextButton(
                                onPressed: () => setState(
                                  () => _history = widget.repository.list(),
                                ),
                                child: const Text('Повторить'),
                              ),
                            ],
                          );
                        }
                        final records = snapshot.data ?? [];
                        if (records.isEmpty) {
                          return const Text('Пока нет сохранённых расчётов.');
                        }
                        return Column(
                          children: [
                            for (
                              var index = 0;
                              index < records.length;
                              index++
                            ) ...[
                              if (index > 0)
                                const Divider(
                                  height: 30,
                                  color: Color(0xFFD0D0D0),
                                ),
                              _HistoryEntry(record: records[index]),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({required this.record});

  final CalculationRecord record;

  @override
  Widget build(BuildContext context) {
    final local = record.createdAt.toLocal();
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    final date = '${local.day} ${months[local.month - 1]} ${local.year} год';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Время расчёта', style: TextStyle(color: _muted)),
        Text(
          '$date, $time',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _metric('Рост', '${record.heightCm}'),
            _metric('Вес', '${record.weightKg}'),
            _metric('Индекс массы тела', record.bmi.toStringAsFixed(2)),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Рекомендация', style: TextStyle(color: _muted)),
        Text(
          record.recommendation,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _metric(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(
          color: Color(0x29000000),
          blurRadius: 11,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorMaxLines: 2,
        labelStyle: const TextStyle(color: _muted, fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 9),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD0D0D0)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: appGreen, width: 2),
        ),
      ),
    ),
  );
}

class GreenButton extends StatelessWidget {
  const GreenButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: appGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}
