import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../legal/legal_links.dart';
import 'social_login_buttons.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  bool _acceptedLegal = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_acceptedLegal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нужно принять соглашение и подтвердить возраст'),
        ),
      );
      return;
    }

    final ok = await context.read<AuthController>().register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          passwordConfirmation: _passwordConfirmation.text,
        );

    if (!mounted) {
      return;
    }

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Регистрация выполнена')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
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
      appBar: AppBar(title: const Text('Регистрация')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Имя'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Укажите имя';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
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
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Пароль'),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'Минимум 8 символов';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordConfirmation,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => busy ? null : _submit(),
                    decoration: const InputDecoration(labelText: 'Повтор пароля'),
                    validator: (value) {
                      if (value != _password.text) {
                        return 'Пароли не совпадают';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  RegisterLegalConsent(
                    value: _acceptedLegal,
                    onChanged: (value) {
                      setState(() => _acceptedLegal = value ?? false);
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
                          : const Text('Зарегистрироваться'),
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
          ],
        ),
      ),
    );
  }
}
