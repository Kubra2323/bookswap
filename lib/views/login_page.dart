import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../viewmodels/auth_view_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('BookSwap', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 8),
                    const Text('Second-hand textbooks for AGÜ students.'),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'University email',
                        hintText: 'name@agu.edu.tr',
                      ),
                      validator: validateUniversityEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: validatePassword,
                    ),
                    if (vm.error != null) ...[
                      const SizedBox(height: 12),
                      Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: vm.busy ? null : () => _submit(vm.signIn),
                      child: vm.busy
                          ? const SizedBox(
                              height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Sign in'),
                    ),
                    TextButton(
                      onPressed: vm.busy ? null : () => _submit(vm.register),
                      child: const Text('Create account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit(Future<void> Function(String email, String password) action) {
    if (_formKey.currentState?.validate() ?? false) {
      action(_email.text, _password.text);
    }
  }
}

/// Firestore rules and Cloud Functions require a verified email, so we wait here.
class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('We sent a link to ${vm.user?.email ?? 'your email'}. Open it, then come back.'),
            if (vm.error != null) ...[
              const SizedBox(height: 12),
              Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: vm.busy ? null : vm.refreshUser,
              child: const Text('I verified my email'),
            ),
            TextButton(
              onPressed: vm.busy ? null : vm.resendVerification,
              child: const Text('Send the link again'),
            ),
            TextButton(onPressed: vm.signOut, child: const Text('Use another account')),
          ],
        ),
      ),
    );
  }
}
