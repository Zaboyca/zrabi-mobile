import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import 'register_screen.dart';
import 'social_login_buttons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ok = await context.read<AuthController>().login(
          email: _email.text,
          password: _password.text,
        );

    if (!mounted) {
      return;
    }

    if (ok) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    final message = context.read<AuthController>().errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'zrabi.by',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Заказы и специалисты рядом',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Укажите email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => busy ? null : _submit(),
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Пароль'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Укажите пароль';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: busy ? null : _submit,
                      child: busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Войти'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SocialLoginButtons(
              onSuccess: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
              child: const Text('Создать аккаунт'),
            ),
          ],
        ),
      ),
    );
  }
}
