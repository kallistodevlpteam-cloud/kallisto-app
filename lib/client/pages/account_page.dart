import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_controller.dart';
import '../client_models.dart';
import '../widgets/connection_panel.dart';
import 'enrollment_panel.dart';
import 'settings_page.dart';

class ClientAccountPage extends StatefulWidget {
  const ClientAccountPage({super.key, required this.controller});
  final ClientController controller;
  @override
  State<ClientAccountPage> createState() => _ClientAccountPageState();
}

class _ClientAccountPageState extends State<ClientAccountPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _recovering = false;
  bool _register = false;
  String _recoveryMessage = '';
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _recover() async {
    if (!_email.text.trim().contains('@') || _recovering) {
      setState(() => _recoveryMessage = 'Enter your email address first.');
      return;
    }
    setState(() {
      _recovering = true;
      _recoveryMessage = '';
    });
    try {
      await widget.controller.gateway.recover(_email.text);
      if (mounted) {
        setState(
          () => _recoveryMessage =
              'If recovery is available for this account, check your email for the next step.',
        );
      }
    } on ClientFailure catch (error) {
      if (mounted) setState(() => _recoveryMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _recoveryMessage = 'Recovery is unavailable. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _recovering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your account', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'A secure home for your Kallisto workspace.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        if (controller.connection == ClientConnection.loading)
          const KPanel(child: LinearProgressIndicator())
        else if (controller.connection == ClientConnection.enrollment)
          EnrollmentPanel(
            key: ValueKey(controller.snapshot?.uid),
            controller: controller,
          )
        else if (controller.snapshot != null)
          KPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.account_circle_outlined, size: 40),
                const SizedBox(height: 14),
                Text(
                  controller.snapshot!.name.isEmpty
                      ? 'Your client account'
                      : controller.snapshot!.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const KBadge('Client workspace'),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/help'),
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Help & support'),
                ),
                for (final section in clientSettingsSections.entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(section.value),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/client/settings/${section.key}',
                    ),
                  ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: controller.signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: KPanel(
              child: AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _register
                            ? 'Create your Kallisto account'
                            : 'Sign in to Kallisto',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _register
                            ? 'Start with your email and a secure password.'
                            : 'Use the email address registered to your account.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                        ),
                        validator: (value) =>
                            value != null &&
                                RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                ).hasMatch(value.trim())
                            ? null
                            : 'Enter a valid email address.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (value) =>
                            value == null ||
                                value.isEmpty ||
                                (_register && value.length < 8)
                            ? (_register
                                  ? 'Use at least 8 characters.'
                                  : 'Enter your password.')
                            : null,
                      ),
                      if (controller.message.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          controller.message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: controller.busy
                              ? null
                              : () async {
                                  if (_form.currentState!.validate()) {
                                    final password = _password.text;
                                    _password.clear();
                                    await controller.signIn(
                                      _email.text,
                                      password,
                                      register: _register,
                                    );
                                  }
                                },
                          child: Text(
                            controller.busy
                                ? 'Please wait…'
                                : (_register ? 'Create account' : 'Sign in'),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: controller.busy
                            ? null
                            : () => setState(() {
                                _register = !_register;
                                _recoveryMessage = '';
                              }),
                        child: Text(
                          _register
                              ? 'Already registered? Sign in'
                              : 'New here? Create an account',
                        ),
                      ),
                      if (!_register)
                        TextButton(
                          onPressed: _recovering ? null : _recover,
                          child: const Text('Forgot your password?'),
                        ),
                      if (_recoveryMessage.isNotEmpty) Text(_recoveryMessage),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (controller.connection == ClientConnection.denied) ...[
          const SizedBox(height: 18),
          ConnectionPanel(controller: controller),
        ],
      ],
    );
  }
}
