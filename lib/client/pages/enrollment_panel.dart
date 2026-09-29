import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_controller.dart';
import '../client_gateway.dart';
import '../client_models.dart';
import '../workflow_models.dart';

class EnrollmentPanel extends StatefulWidget {
  const EnrollmentPanel({super.key, required this.controller});
  final ClientController controller;
  @override
  State<EnrollmentPanel> createState() => _EnrollmentPanelState();
}

class _EnrollmentPanelState extends State<EnrollmentPanel> {
  final _name = TextEditingController();
  EnrollmentNotice? _notice;
  bool _loading = true, _accepted = false, _busy = false;
  String _message = '', _key = clientIntentId(), _submittedName = '';
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = '';
    });
    try {
      final notice = await widget.controller.gateway.enrollmentNotice();
      if (mounted) {
        setState(() {
          _notice = notice;
          _accepted = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Could not load the account notice. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty || name.length > 120) {
      setState(() => _message = 'Enter your name (up to 120 characters).');
      return;
    }
    if (!_accepted || _notice == null || _busy) return;
    if (_submittedName != name) {
      _key = clientIntentId();
      _submittedName = name;
    }
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      await widget.controller.gateway.enroll(name, _notice!, _key);
      await widget.controller.refresh();
    } on ClientFailure catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Account setup could not finish. Retry to continue safely.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 640),
    child: KPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Finish setting up your account',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          const Text(
            'Your sign-in is ready. Set up your personal client workspace to start a project.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            enabled: !_busy,
            maxLength: 120,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(labelText: 'Your name'),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const LinearProgressIndicator()
          else if (_notice == null) ...[
            const Text(
              'Your sign-in is working. Workspace creation is waiting for Kallisto’s enrollment notice to be configured. Retrying will work after that configuration is published.',
            ),
            TextButton(
              onPressed: _load,
              child: const Text('Retry account setup'),
            ),
          ] else ...[
            Text(_notice!.text),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'I have reviewed this notice and want to create my client workspace.',
              ),
              value: _accepted,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _accepted = v ?? false),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _accepted && !_busy ? _submit : null,
              child: Text(
                _busy ? 'Creating workspace…' : 'Create client workspace',
              ),
            ),
          ],
          if (_message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message),
            ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/help'),
            icon: const Icon(Icons.help_outline),
            label: const Text('Get account help'),
          ),
          TextButton(
            onPressed: _busy ? null : widget.controller.signOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
    ),
  );
}
