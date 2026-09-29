import 'dart:async';
import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_gateway.dart';
import '../client_models.dart';

class OdinPage extends StatefulWidget {
  const OdinPage({
    super.key,
    required this.gateway,
    this.runId,
    this.initialText = '',
    this.projectId,
  });
  final ClientGateway gateway;
  final String? runId, projectId;
  final String initialText;
  @override
  State<OdinPage> createState() => _OdinPageState();
}

class _OdinPageState extends State<OdinPage> {
  late final TextEditingController _text;
  Timer? _timer;
  Map<String, dynamic>? _cap, _run;
  List<dynamic> _history = [];
  String? _project, _conversation, _consent, _intent, _intentText;
  String _error = '';
  bool _busy = false, _accepted = false, _planning = false, _polling = false;
  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.initialText);
    _project = widget.projectId;
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    super.dispose();
  }

  String _failure(Object e) => e is ClientFailure
      ? e.message
      : 'Could not complete this request. Your text is retained; please retry.';
  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final cap = await widget.gateway.odinCapabilities();
      final history = await widget.gateway.odinRuns();
      final currentId = widget.runId ?? _run?['run_id'] as String?;
      final run = currentId == null
          ? null
          : await widget.gateway.odinRun(currentId);
      if (!mounted) return;
      setState(() {
        _cap = cap;
        _history = history;
        _run = run;
        _conversation = run?['conversation_id'] as String?;
        _project = run?['project_id'] as String? ?? _project;
      });
      if (run != null) _schedule();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _failure(e);
          _run = null;
          _history = [];
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (_run != null && ['queued', 'running'].contains(_run!['status'])) {
      _timer = Timer(const Duration(seconds: 3), _poll);
    }
  }

  Future<void> _poll() async {
    if (_polling || !mounted || _run == null) return;
    _polling = true;
    try {
      final run = await widget.gateway.odinRun(_run!['run_id'] as String);
      if (mounted) {
        setState(() {
          _run = run;
          _history = [
            run,
            ..._history.where((r) => r['run_id'] != run['run_id']),
          ];
          _error = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _failure(e);
          _run = null;
          _history = [];
        });
      }
    } finally {
      _polling = false;
      if (mounted) _schedule();
    }
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (_busy || text.isEmpty || text.length > 4000 || !_accepted) return;
    if (_intentText != text) {
      _intent = clientIntentId();
      _intentText = text;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      _consent ??= await widget.gateway.odinConsent(
        _cap!['notice_version'] as String,
        clientIntentId(),
      );
      final created = await widget.gateway.odinSend(
        text,
        _intent!,
        _consent!,
        conversation: _conversation,
        project: _project,
        planning: _planning,
      );
      final run = await widget.gateway.odinRun(created['run_id'] as String);
      if (mounted) {
        setState(() {
          _run = run;
          _history = [
            run,
            ..._history.where((r) => r['run_id'] != run['run_id']),
          ];
          _conversation = created['conversation_id'] as String;
          _text.clear();
          _intent = null;
          _intentText = null;
        });
        _schedule();
      }
    } catch (e) {
      if (mounted) setState(() => _error = _failure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _action(String action) async {
    if (_busy || _run == null) return;
    setState(() => _busy = true);
    try {
      await widget.gateway.odinAction(
        _run!['run_id'] as String,
        action,
        _run!['row_version'] as int,
        clientIntentId(),
      );
      await _poll();
    } catch (e) {
      if (mounted) setState(() => _error = _failure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw() async {
    if (_busy || _cap == null) return;
    setState(() => _busy = true);
    try {
      await widget.gateway.withdrawOdinConsent(
        _cap!['notice_version'] as String,
        clientIntentId(),
      );
      if (mounted) {
        setState(() {
          _accepted = false;
          _consent = null;
          _error =
              'AI processing permission withdrawn. Saved conversations remain available.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _failure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final running =
        _run != null && ['queued', 'running'].contains(_run!['status']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ask Odin', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        const Text(
          'Plan your project and understand your next steps. Suggestions are not approvals, quotations or verified engineering advice.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: _busy || running
                  ? null
                  : () => Navigator.pushReplacementNamed(
                      context,
                      '/odin',
                      arguments: _text.text,
                    ),
              child: const Text('New conversation'),
            ),
            const KBadge('Gemma · chat'),
            const KBadge('Nemotron · project planning'),
            TextButton(
              onPressed: _busy ? null : _load,
              child: const Text('Refresh history'),
            ),
          ],
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error.isNotEmpty) Text(_error),
        if (_cap != null && _cap!['available'] != true)
          Text(_cap!['reason'] as String? ?? 'Odin is not configured.'),
        if (_run != null) ...[
          const SizedBox(height: 20),
          KPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You', style: Theme.of(context).textTheme.titleMedium),
                Text(_run!['input_text'] as String? ?? ''),
                const SizedBox(height: 16),
                KBadge(_run!['status'] as String),
                Text('Model: ${_run!['model'] ?? 'Odin'}'),
                if (running)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Odin is working… You can leave and reopen this run.',
                    ),
                  ),
                for (final step in (_run!['steps'] as List? ?? []))
                  Text(step['summary'] as String? ?? ''),
                if (_run!['answer'] != null) ...[
                  const SizedBox(height: 16),
                  Text('Odin', style: Theme.of(context).textTheme.titleMedium),
                  Semantics(
                    label: _run!['answer'] as String,
                    child: ExcludeSemantics(
                      child: SelectableText(_run!['answer'] as String),
                    ),
                  ),
                ],
                if (_run!['error_code'] != null)
                  Text(
                    'Processing stopped: ${_run!['error_code']}. Your input is saved.',
                  ),
                for (final source in (_run!['sources'] as List? ?? []))
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/client/projects/${source['resource_id']}',
                    ),
                    child: Text('Source: ${source['label']}'),
                  ),
                if (running)
                  OutlinedButton(
                    onPressed: _busy ? null : () => _action('cancel'),
                    child: const Text('Stop Odin'),
                  ),
                if (_run!['status'] == 'failed')
                  OutlinedButton(
                    onPressed: _busy ? null : () => _action('resume'),
                    child: const Text('Retry saved run'),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (_cap?['available'] == true) ...[
          KPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_accepted)
                  Text(_cap!['notice_text'] as String)
                else
                  ExpansionTile(
                    title: const Text('Cloud processing permission selected'),
                    children: [Text(_cap!['notice_text'] as String)],
                  ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _accepted,
                  onChanged: running || _busy
                      ? null
                      : (v) => setState(() => _accepted = v!),
                  title: const Text(
                    'Allow Ollama to process the text and selected project context I send to Odin.',
                  ),
                ),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _project,
                  decoration: const InputDecoration(
                    labelText: 'Project context',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('General conversation'),
                    ),
                    for (final p in (_cap!['projects'] as List? ?? []))
                      DropdownMenuItem(
                        value: p['project_id'] as String,
                        child: Text(p['name'] as String),
                      ),
                  ],
                  onChanged: running || _busy || _conversation != null
                      ? null
                      : (v) => setState(() => _project = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _planning,
                  onChanged: running || _busy
                      ? null
                      : (v) => setState(() => _planning = v),
                  title: const Text('Detailed project planning'),
                  subtitle: const Text(
                    'Uses NVIDIA Nemotron for a planning response.',
                  ),
                ),
                TextField(
                  controller: _text,
                  minLines: 3,
                  maxLines: 8,
                  maxLength: 4000,
                  enabled: !running && !_busy,
                  decoration: const InputDecoration(labelText: 'Message Odin'),
                ),
                FilledButton(
                  onPressed: _busy || running || !_accepted ? null : _send,
                  child: const Text('Send to Odin'),
                ),
                Text(
                  'Development usage: ${_cap!['daily_call_limit']} reserved model calls per account/day (8 reserved per run). Voice and attachments are not connected yet.',
                ),
              ],
            ),
          ),
        ],
        TextButton(
          onPressed: _busy ? null : _withdraw,
          child: const Text('Withdraw AI processing permission'),
        ),
        const SizedBox(height: 24),
        Text(
          'Saved runs (up to 20)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (_history.isEmpty && !_busy) const Text('No saved Odin runs yet.'),
        for (final run in _history)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              run['input_text'] as String,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(run['status'] as String),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.pushNamed(context, '/odin/runs/${run['run_id']}'),
          ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/client/projects/new'),
          child: const Text('Continue with a manual brief'),
        ),
      ],
    );
  }
}
