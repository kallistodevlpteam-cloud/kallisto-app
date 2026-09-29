import 'dart:convert';
import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_gateway.dart';
import '../client_models.dart';
import '../settings_models.dart';

const clientSettingsSections = <String, String>{
  'profile': 'Your profile',
  'appearance': 'Appearance',
  'billing': 'Billing details',
  'communication': 'Communication',
  'language_region': 'Language & region',
  'notifications': 'Notifications',
  'privacy': 'Privacy preferences',
  'security': 'Security notifications',
  'project_preferences': 'Project preferences',
  'odin': 'Odin preferences',
};

class ClientSettingsPage extends StatefulWidget {
  const ClientSettingsPage({
    super.key,
    required this.gateway,
    required this.section,
    this.onSaved,
  });
  final ClientGateway gateway;
  final String section;
  final void Function(ClientSettings)? onSaved;
  @override
  State<ClientSettingsPage> createState() => _ClientSettingsPageState();
}

class _ClientSettingsPageState extends State<ClientSettingsPage> {
  ClientSettings? _saved;
  Map<String, dynamic> _values = {};
  String _message = '';
  bool _busy = false;
  String? _fingerprint, _key;
  var _form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      final result = widget.section == 'profile'
          ? await widget.gateway.profile()
          : await widget.gateway.settings(widget.section);
      if (mounted) {
        setState(() {
          _saved = result;
          _values = Map.of(result.values);
          _form = GlobalKey<FormState>();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not load preferences. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saved == null) return;
    _form.currentState!.save();
    final fingerprint = jsonEncode([_saved!.version, _values]);
    if (_fingerprint != fingerprint) {
      _fingerprint = fingerprint;
      _key = clientIntentId();
    }
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      final result = widget.section == 'profile'
          ? await widget.gateway.saveProfile(
              _saved!,
              _values['display_name'] as String,
              _key!,
            )
          : await widget.gateway.saveSettings(_saved!, _values, _key!);
      widget.onSaved?.call(result);
      if (mounted) {
        setState(() {
          _saved = result;
          _values = Map.of(result.values);
          _form = GlobalKey<FormState>();
          _message = 'Preferences saved.';
        });
      }
    } on ClientFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Could not save. Your changes are still shown; retry to continue.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _choice(String field, String label, List<String> choices) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: DropdownButtonFormField<String>(
      initialValue: _values[field] as String?,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: choices
          .map(
            (v) =>
                DropdownMenuItem(value: v, child: Text(v.replaceAll('_', ' '))),
          )
          .toList(),
      onChanged: _busy
          ? null
          : (value) => setState(() => _values[field] = value),
    ),
  );
  Widget _toggle(String field, String label) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    value: _values[field] == true,
    onChanged: _busy ? null : (value) => setState(() => _values[field] = value),
  );
  List<Widget> _fields() => switch (widget.section) {
    'profile' => [
      TextFormField(
        initialValue: _values['display_name'] as String?,
        enabled: !_busy,
        maxLength: 120,
        decoration: const InputDecoration(labelText: 'Display name'),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Enter your name.' : null,
        onSaved: (v) => _values['display_name'] = v!.trim(),
      ),
      Text('Email: ${_values['email'] ?? 'Not supplied'}'),
      Text(
        _values['email_verified'] == true
            ? 'Email verified by Firebase'
            : 'Email verification not confirmed',
      ),
      const Text('Avatar uploads and contact changes are not connected yet.'),
      TextButton(
        onPressed: () =>
            Navigator.pushNamed(context, '/client/settings/language_region'),
        child: const Text('Language & region'),
      ),
    ],
    'appearance' => [
      _choice('theme', 'Theme', ['light', 'dark', 'system']),
      _choice('density', 'Density', ['comfortable', 'compact']),
      _toggle('reduce_motion', 'Reduce motion'),
      const Text(
        'Changes apply after you save. Device text scaling remains in effect.',
      ),
    ],
    'billing' => [
      const Text(
        'Your billing contact preferences. This does not create an invoice or payment.',
      ),
      for (final field in ['name', 'email', 'phone_e164', 'address'])
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: TextFormField(
            initialValue:
                (_values['billing_contact'] as Map?)?[field] as String?,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: {
                'name': 'Billing name',
                'email': 'Billing email',
                'phone_e164': 'Phone (+country code)',
                'address': 'Billing address',
              }[field],
            ),
            maxLength: field == 'address'
                ? 2000
                : field == 'email'
                ? 254
                : 120,
            onSaved: (v) {
              final contact = Map<String, dynamic>.from(
                _values['billing_contact'] as Map? ?? {},
              );
              if (v == null || v.trim().isEmpty) {
                contact.remove(field);
              } else {
                contact[field] = v.trim();
              }
              _values['billing_contact'] = contact;
            },
          ),
        ),
      TextFormField(
        initialValue: _values['invoice_delivery_email'] as String?,
        enabled: !_busy,
        decoration: const InputDecoration(
          labelText: 'Invoice delivery email (optional)',
        ),
        onSaved: (v) {
          if (v == null || v.trim().isEmpty) {
            _values.remove('invoice_delivery_email');
          } else {
            _values['invoice_delivery_email'] = v.trim();
          }
        },
      ),
    ],
    'communication' => [
      const Text(
        'Language is managed in Language & region. Channel preferences do not guarantee email or push delivery.',
      ),
      const SizedBox(height: 20),
      _choice('preferred_language', 'Preferred language', ['en', 'ml']),
      _choice('preferred_channel', 'Preferred channel', [
        'in_app',
        'email',
        'push',
      ]),
    ],
    'language_region' => [
      _choice('language', 'Preferred language', ['en', 'ml']),
      const Text(
        'This saves your language preference. Malayalam interface translation is not yet available.',
      ),
      const SizedBox(height: 20),
      TextFormField(
        initialValue: _values['timezone'] as String?,
        decoration: const InputDecoration(
          labelText: 'IANA time zone',
          hintText: 'Asia/Kolkata',
        ),
        enabled: !_busy,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Enter a time zone.' : null,
        onSaved: (v) => _values['timezone'] = v!.trim(),
      ),
      const SizedBox(height: 20),
      _choice('date_format', 'Date format', ['DD_MM_YYYY', 'YYYY_MM_DD']),
      _choice('unit_preference', 'Preferred units', [
        'metric',
        'imperial',
        'mixed',
      ]),
    ],
    'notifications' => [
      const Text(
        'These are delivery preferences. Email and push require configured delivery services.',
      ),
      _toggle('in_app', 'In-app notifications'),
      _toggle('email', 'Email notifications'),
      _toggle('push', 'Push notifications'),
      const Text('Existing reminder preferences are preserved.'),
    ],
    'privacy' => [
      _toggle('optional_analytics_consent', 'Optional analytics'),
      _toggle('marketing_consent', 'Marketing communications'),
      const Text(
        'These preferences do not grant permission for AI processing, voice recording or publication.',
      ),
    ],
    'security' => [
      _toggle('security_notification_enabled', 'Security notifications'),
      const Text(
        'Password recovery and sign-out are available from your account. This setting does not change authentication methods.',
      ),
    ],
    'project_preferences' => [
      _choice('default_view', 'Preferred project view', [
        'overview',
        'design',
        'build',
        'money',
        'files',
      ]),
      _choice('default_units', 'Preferred project units', [
        'metric',
        'imperial',
        'mixed',
      ]),
      const Text(
        'Preferences do not change project quantities or access permissions.',
      ),
    ],
    'odin' => [
      _choice('preferred_mode', 'Preferred mode', ['text', 'voice', 'manual']),
      _choice('preferred_language', 'Preferred language', ['en', 'ml']),
      _toggle('spoken_replies_enabled', 'Speak final responses'),
      const Text(
        'Odin text chat and planning are available from Home with processing permission. Voice preferences take effect when voice is connected; manual intake remains available.',
      ),
    ],
    _ => [],
  };
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: _busy
              ? null
              : () =>
                    Navigator.pushReplacementNamed(context, '/client/account'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Account'),
        ),
        Text(
          clientSettingsSections[widget.section] ?? 'Settings',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 24),
        if (_busy) const LinearProgressIndicator(),
        if (_message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(_message, semanticsLabel: _message),
          ),
        if (_saved == null && !_busy)
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        if (_saved != null)
          KPanel(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._fields(),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: _busy ? null : _save,
                        child: const Text('Save preferences'),
                      ),
                      OutlinedButton(
                        onPressed: _busy ? null : _load,
                        child: const Text('Discard changes & reload'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
