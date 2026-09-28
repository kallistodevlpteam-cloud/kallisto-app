import 'dart:convert';
import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_gateway.dart';
import '../client_controller.dart';
import '../client_models.dart';
import '../intake_fields.dart';
import '../workflow_models.dart';

class ClientIntakePage extends StatefulWidget {
  const ClientIntakePage({
    super.key,
    required this.gateway,
    this.intakeId,
    this.controller,
  });
  final ClientGateway gateway;
  final String? intakeId;
  final ClientController? controller;
  @override
  State<ClientIntakePage> createState() => _ClientIntakePageState();
}

class _ClientIntakePageState extends State<ClientIntakePage> {
  final _form = GlobalKey<FormState>();
  final _editors = {
    for (final field in briefFields) field.path: TextEditingController(),
  };
  final Map<String, String> _states = {};
  final _createKey = clientIntentId();
  String _group = 'The idea',
      _message = '',
      _saveKey = '',
      _saveFingerprint = '',
      _prepareKey = '';
  int? _prepareRevision;
  IntakeDraft? _draft;
  bool _busy = false, _dirty = false;
  @override
  void initState() {
    super.initState();
    widget.controller?.beforeLeaveEditor = _mayLeave;
    if (widget.intakeId != null) _load();
  }

  @override
  void dispose() {
    if (widget.controller?.beforeLeaveEditor == _mayLeave) {
      widget.controller?.beforeLeaveEditor = null;
    }
    for (final c in _editors.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _mayLeave() async {
    if (_busy) return false;
    if (!_dirty) return true;
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keep your changes?'),
        content: const Text(
          'Save this draft before leaving, or discard only your unsaved edits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard edits'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save and leave'),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    if (action == 'discard') return true;
    if (action == 'save') {
      await _submit();
      return mounted && !_dirty;
    }
    return false;
  }

  void _adopt(IntakeDraft value) {
    _draft = value;
    for (final field in briefFields) {
      final v = value.values[field.path];
      _editors[field.path]!.text = v == null
          ? ''
          : field.kind == BriefFieldKind.money
          ? ((v as int) / 100).toStringAsFixed(2)
          : v is List
          ? v.join('\n')
          : v.toString();
      _states[field.path] = value.answerStates[field.path] ?? 'missing';
    }
    _dirty = false;
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      final value = await widget.gateway.intake(_draft?.id ?? widget.intakeId!);
      if (mounted) setState(() => _adopt(value));
    } catch (e) {
      if (mounted) setState(() => _message = _error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _error(Object e) => e is ClientFailure
      ? e.message
      : 'This step could not finish. Please retry; your entered details remain here.';
  Future<void> _create() async {
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      final id = await widget.gateway.createIntake(_createKey);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/client/intakes/$id');
      }
    } catch (e) {
      if (mounted) setState(() => _message = _error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Object? _value(BriefField f) {
    final s = _editors[f.path]!.text.trim();
    if (f.kind == BriefFieldKind.count) return int.parse(s);
    if (f.kind == BriefFieldKind.money) {
      final parts = s.split('.');
      return int.parse(parts[0]) * 100 +
          (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
    }
    if (f.kind == BriefFieldKind.boolean) return s == 'true';
    if (f.kind == BriefFieldKind.list) {
      return s
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return s;
  }

  String? _validate(BriefField f, String? input) {
    if (_states[f.path] != 'provided') return null;
    final s = input?.trim() ?? '';
    if (s.isEmpty) return 'Enter a value or choose an answer status.';
    if (f.kind == BriefFieldKind.count &&
        (!RegExp(r'^\d{1,7}$').hasMatch(s) || int.parse(s) > 1000000)) {
      return 'Enter a whole number from 0 to 1,000,000.';
    }
    if (f.kind == BriefFieldKind.money &&
        (!RegExp(r'^\d{1,13}(\.\d{1,2})?$').hasMatch(s))) {
      return 'Enter rupees with up to two decimal places.';
    }
    if (f.path.endsWith('.country') && !RegExp(r'^[A-Z]{2}$').hasMatch(s)) {
      return 'Use a two-letter uppercase country code.';
    }
    if (f.kind == BriefFieldKind.list &&
        (s.split('\n').length > 50 ||
            s.split('\n').any((s) => s.length > 1000))) {
      return 'Use up to 50 items, each up to 1,000 characters.';
    }
    return null;
  }

  Future<bool> _save() async {
    // Validate every step, including fields outside the currently visible section.
    for (final f in briefFields) {
      if (_validate(f, _editors[f.path]!.text) != null) {
        setState(() {
          _group = f.group;
          _message = '${f.label}: ${_validate(f, _editors[f.path]!.text)}';
        });
        return false;
      }
    }
    final operations = <Map<String, Object?>>[];
    for (final f in briefFields) {
      final state = _states[f.path] ?? 'missing';
      final oldState = _draft!.answerStates[f.path] ?? 'missing';
      final value = state == 'provided' ? _value(f) : null;
      if (state == oldState &&
          jsonEncode(value) == jsonEncode(_draft!.values[f.path])) {
        continue;
      }
      operations.add({
        'op': switch (state) {
          'provided' => 'set',
          'explicit_unknown' => 'mark_unknown',
          'deferred' => 'defer',
          'declined' => 'decline',
          _ => 'clear',
        },
        'field_path': f.path,
        if (state == 'provided') 'value': value,
        'expected_field_revision': _draft!.fieldRevisions[f.path] ?? 0,
      });
    }
    if (operations.any(
          (op) =>
              (op['field_path'] as String).startsWith('brief.budget.') &&
              op['op'] == 'set',
        ) &&
        _draft!.values['brief.budget.currency'] != 'INR') {
      operations.add({
        'op': 'set',
        'field_path': 'brief.budget.currency',
        'value': 'INR',
        'expected_field_revision':
            _draft!.fieldRevisions['brief.budget.currency'] ?? 0,
      });
    }
    if (operations.isEmpty) {
      setState(() {
        _dirty = false;
        _message = 'Your draft is saved.';
      });
      return true;
    }
    final fingerprint = jsonEncode([_draft!.revision, operations]);
    if (fingerprint != _saveFingerprint) {
      _saveFingerprint = fingerprint;
      _saveKey = clientIntentId();
    }
    await widget.gateway.saveIntake(_draft!, operations, _saveKey);
    final updated = await widget.gateway.intake(_draft!.id);
    if (!mounted) return false;
    setState(() {
      _adopt(updated);
      _message = 'Your draft is saved.';
    });
    return true;
  }

  Future<void> _submit({bool prepare = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      if (!await _save() || !mounted) return;
      if (prepare) {
        if (_draft!.values['brief.project.name'] == null ||
            _draft!.values['brief.project.project_type'] == null) {
          setState(() {
            _group = 'The idea';
            _message =
                'Add a project name and project type before preparing your brief.';
          });
          return;
        }
        if (_prepareRevision != _draft!.revision) {
          _prepareKey = clientIntentId();
          _prepareRevision = _draft!.revision;
        }
        final result = await widget.gateway.prepare(_draft!, _prepareKey);
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/client/projects/${result.projectId}/requirements?version_id=${result.versionId}',
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _message = _error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reload() async {
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reload saved draft?'),
          content: const Text(
            'Your unsaved edits will be discarded. Your saved draft will remain.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reload saved draft'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    await _load();
  }

  String _statusKey = '', _statusIntent = '';
  Future<void> _changeStatus(bool paused) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      if (_dirty && !await _save()) return;
      final intent = '${_draft!.rowVersion}:$paused';
      if (_statusIntent != intent) {
        _statusIntent = intent;
        _statusKey = clientIntentId();
      }
      await widget.gateway.setIntakePaused(_draft!, paused, _statusKey);
      final updated = await widget.gateway.intake(_draft!.id);
      if (mounted) setState(() => _adopt(updated));
    } catch (e) {
      if (mounted) setState(() => _message = _error(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(BriefField f) {
    final state = _states[f.path] ?? 'missing';
    final options = f.kind == BriefFieldKind.boolean
        ? const {'true': 'Yes', 'false': 'No'}
        : f.options;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (options.isNotEmpty)
            DropdownButtonFormField<String>(
              key: ValueKey('${f.path}:$state:${_draft!.revision}'),
              initialValue: state == 'provided' ? _editors[f.path]!.text : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: f.label),
              items: options.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _editors[f.path]!.text = value ?? '';
                      _states[f.path] = 'provided';
                      _dirty = true;
                    }),
            )
          else
            TextFormField(
              controller: _editors[f.path],
              enabled: !_busy,
              maxLines:
                  [
                    BriefFieldKind.paragraph,
                    BriefFieldKind.list,
                  ].contains(f.kind)
                  ? 4
                  : 1,
              maxLength: f.kind == BriefFieldKind.list ? null : f.limit,
              keyboardType:
                  [BriefFieldKind.money, BriefFieldKind.count].contains(f.kind)
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: f.label,
                alignLabelWithHint: true,
                helperText: f.kind == BriefFieldKind.list
                    ? 'One item per line'
                    : null,
              ),
              validator: (v) => _validate(f, v),
              onChanged: (v) => setState(() {
                _states[f.path] = v.trim().isEmpty ? 'missing' : 'provided';
                _dirty = true;
              }),
            ),
          const SizedBox(height: 4),
          PopupMenuButton<String>(
            tooltip: 'Answer status for ${f.label}',
            enabled: !_busy,
            onSelected: (value) => setState(() {
              _states[f.path] = value;
              if (value != 'provided') _editors[f.path]!.clear();
              _dirty = true;
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'missing', child: Text('Leave blank')),
              PopupMenuItem(
                value: 'explicit_unknown',
                child: Text('I do not know yet'),
              ),
              PopupMenuItem(value: 'deferred', child: Text('Decide later')),
              PopupMenuItem(
                value: 'declined',
                child: Text('Prefer not to answer'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Text(switch (state) {
                'provided' => 'Answer added  ·  Change status',
                'explicit_unknown' => 'Unknown  ·  Change status',
                'deferred' => 'Decide later  ·  Change status',
                'declined' => 'Prefer not to answer  ·  Change status',
                _ => 'Optional  ·  Choose answer status',
              }, style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) {
        setState(
          () => _message =
              'Save your draft before leaving, or reload to discard unsaved edits.',
        );
      }
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KBadge('YOUR PROJECT BRIEF', tone: KBadgeTone.info),
        const SizedBox(height: 16),
        Text(
          'Make the idea yours.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        const Text(
          'Tell us what matters. You can leave details open, save your progress, and return when you are ready.',
        ),
        const SizedBox(height: 24),
        if (_draft == null)
          KPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.intakeId == null
                      ? 'Start a private draft'
                      : 'Loading your saved draft',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Preparing a brief creates your project. You will review the exact brief before confirming it.',
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : widget.intakeId == null
                      ? _create
                      : _load,
                  child: Text(
                    _busy
                        ? 'Please wait…'
                        : widget.intakeId == null
                        ? 'Start my brief'
                        : 'Retry loading',
                  ),
                ),
              ],
            ),
          )
        else if (_draft!.status != 'active')
          KPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This draft is ${_draft!.status}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your saved inputs and prepared brief are preserved.',
                ),
                const SizedBox(height: 20),
                if (_draft!.status == 'paused')
                  FilledButton(
                    onPressed: _busy ? null : () => _changeStatus(false),
                    child: const Text('Resume this draft'),
                  ),
              ],
            ),
          )
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final group in briefFields.map((f) => f.group).toSet())
                ChoiceChip(
                  label: Text(group),
                  selected: _group == group,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() => _group = group),
                ),
            ],
          ),
          const SizedBox(height: 20),
          KPanel(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_group, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  KGrid(
                    minWidth: 330,
                    children: [
                      for (final field in briefFields.where(
                        (f) => f.group == _group,
                      ))
                        _field(field),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(
                onPressed: _busy ? null : () => _submit(prepare: true),
                child: Text(_busy ? 'Please wait…' : 'Prepare & review brief'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _submit,
                child: const Text('Save draft'),
              ),
              TextButton(
                onPressed: _busy ? null : _reload,
                child: const Text('Reload saved draft'),
              ),
              TextButton(
                onPressed: _busy ? null : () => _changeStatus(true),
                child: const Text('Save & pause draft'),
              ),
              Text(
                _dirty
                    ? 'Unsaved changes'
                    : 'Saved · revision ${_draft!.revision}',
              ),
            ],
          ),
        ],
        if (_message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Semantics(liveRegion: true, child: Text(_message)),
          ),
      ],
    ),
  );
}
