import 'dart:convert';
import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_gateway.dart';
import '../client_models.dart';
import '../message_models.dart';

class ClientSupportPage extends StatefulWidget {
  const ClientSupportPage({super.key, required this.gateway, this.caseId});
  final ClientGateway gateway;
  final String? caseId;
  @override
  State<ClientSupportPage> createState() => _ClientSupportPageState();
}

class _ClientSupportPageState extends State<ClientSupportPage> {
  final _subject = TextEditingController(),
      _description = TextEditingController();
  final _form = GlobalKey<FormState>();
  String _category = 'account', _error = '', _status = '';
  String? _cursor, _fingerprint, _key;
  bool _loading = false, _saving = false;
  List<SupportCase> _cases = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load({bool next = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final page = widget.caseId == null
          ? await widget.gateway.supportCases(cursor: next ? _cursor : null)
          : ClientPage([
              await widget.gateway.supportCase(widget.caseId!),
            ], null);
      if (mounted) {
        setState(() {
          _cases = [if (next) ..._cases, ...page.items];
          _cursor = page.cursor;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _cases = [];
          _cursor = null;
          _error = error is ClientFailure
              ? error.message
              : 'Could not load support cases. Please retry.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (_saving || !_form.currentState!.validate()) return;
    final fingerprint = jsonEncode([
      _category,
      _subject.text.trim(),
      _description.text.trim(),
    ]);
    if (_fingerprint != fingerprint) {
      _fingerprint = fingerprint;
      _key = clientIntentId();
    }
    setState(() {
      _saving = true;
      _status = '';
    });
    try {
      final id = await widget.gateway.createSupportCase(
        _category,
        _subject.text.trim(),
        _description.text.trim(),
        _key!,
      );
      if (mounted) {
        _subject.clear();
        _description.clear();
        _fingerprint = null;
        Navigator.pushNamed(
          context,
          '/support/cases/${Uri.encodeComponent(id)}',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _status = error is ClientFailure
              ? error.message
              : 'The result is uncertain. Retry with the same details to recover the case.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.caseId == null ? 'Help & support' : 'Support case',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 12),
      const Text(
        'Report an account or project problem. A saved case is separate from email delivery; response times are not guaranteed.',
      ),
      if (widget.caseId == null) ...[
        const SizedBox(height: 24),
        KPanel(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report a problem',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items:
                      [
                            'account',
                            'technical',
                            'project',
                            'upload',
                            'privacy',
                            'other',
                          ]
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subject,
                  enabled: !_saving,
                  maxLength: 240,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a subject.' : null,
                ),
                TextFormField(
                  controller: _description,
                  enabled: !_saving,
                  minLines: 3,
                  maxLines: 8,
                  maxLength: 8000,
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                    helperText:
                        'Do not include passwords, API keys or payment details.',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Describe the problem.'
                      : null,
                ),
                if (_status.isNotEmpty) Text(_status),
                FilledButton(
                  onPressed: _saving ? null : _create,
                  child: Text(_saving ? 'Saving…' : 'Create support case'),
                ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 24),
      OutlinedButton(
        onPressed: _loading ? null : () => _load(),
        child: const Text('Refresh cases'),
      ),
      if (_loading) const LinearProgressIndicator(),
      if (_error.isNotEmpty) Text(_error),
      if (!_loading && _error.isEmpty && _cases.isEmpty)
        const KPanel(child: Text('No support cases yet.')),
      for (final item in _cases)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: KPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subject,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                KBadge('${item.category} · ${item.status}'),
                if (widget.caseId != null) ...[
                  const SizedBox(height: 16),
                  SelectableText(item.description),
                  const SizedBox(height: 16),
                  SelectableText('Case: ${item.id}'),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/messages/${Uri.encodeComponent(item.conversationId)}',
                    ),
                    child: const Text('Open support conversation'),
                  ),
                ] else
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/support/cases/${Uri.encodeComponent(item.id)}',
                    ),
                    child: const Text('View case'),
                  ),
              ],
            ),
          ),
        ),
      if (_cursor != null)
        OutlinedButton(
          onPressed: _loading ? null : () => _load(next: true),
          child: const Text('Load more cases'),
        ),
    ],
  );
}
