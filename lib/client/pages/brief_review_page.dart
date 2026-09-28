import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_gateway.dart';
import '../client_models.dart';
import '../intake_fields.dart';
import '../workflow_models.dart';

class BriefReviewPage extends StatefulWidget {
  const BriefReviewPage({
    super.key,
    required this.gateway,
    required this.projectId,
    this.versionId,
  });
  final ClientGateway gateway;
  final String projectId;
  final String? versionId;
  @override
  State<BriefReviewPage> createState() => _BriefReviewPageState();
}

class _BriefReviewPageState extends State<BriefReviewPage> {
  RequirementView? _brief;
  bool _busy = false, _reviewed = false;
  String _message = '', _key = clientIntentId();
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
      final brief = await widget.gateway.requirements(
        widget.projectId,
        versionId: widget.versionId,
      );
      if (mounted) {
        setState(() {
          if (_brief?.hash != brief.hash) {
            _reviewed = false;
            _key = clientIntentId();
          }
          _brief = brief;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _message = e is ClientFailure
              ? e.message
              : 'Could not load your brief. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    if (_busy || !_reviewed || _brief == null || !_brief!.canConfirm) return;
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      await widget.gateway.confirm(widget.projectId, _brief!, _key);
      final updated = await widget.gateway.requirements(
        widget.projectId,
        versionId: _brief!.versionId,
      );
      if (mounted) {
        setState(() {
          _brief = updated;
          _message = 'This exact brief version is confirmed.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _message = e is ClientFailure
              ? e.message
              : 'Confirmation could not finish. Retry to check the same version safely.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brief = _brief;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review your brief',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        const Text(
          'Take a moment to check every detail. Confirmation applies only to the version shown here.',
        ),
        const SizedBox(height: 24),
        if (brief == null)
          KPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Loading your project brief'),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('Retry loading'),
                ),
              ],
            ),
          )
        else ...[
          KPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    KBadge('Version ${brief.number}'),
                    KBadge(
                      brief.confirmed ? 'Confirmed' : 'Awaiting your review',
                      tone: brief.confirmed
                          ? KBadgeTone.success
                          : KBadgeTone.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  brief.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                for (final entry in brief.values.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          briefLabel(entry.key),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(briefDisplay(entry.key, entry.value)),
                      ],
                    ),
                  ),
                if (brief.answerStates.values.any(
                  (s) => !['missing', 'provided'].contains(s),
                )) ...[
                  const Divider(),
                  Text(
                    'Still open',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final entry in brief.answerStates.entries.where(
                    (e) => !['missing', 'provided'].contains(e.value),
                  ))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '${briefLabel(entry.key)} — ${switch (entry.value) {
                          'explicit_unknown' => 'Unknown',
                          'deferred' => 'Decide later',
                          _ => 'Prefer not to answer',
                        }}',
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!brief.confirmed && brief.canConfirm)
            KPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm this brief',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your project remains in the requirements phase. Sharing with a provider, accepting an offer, spending and starting work each require their own decision.',
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _reviewed,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _reviewed = v ?? false),
                    title: Text(
                      'I reviewed version ${brief.number} and confirm it reflects my project brief.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy || !_reviewed ? null : _confirm,
                    child: Text(_busy ? 'Confirming…' : 'Confirm this version'),
                  ),
                ],
              ),
            ),
          if (!brief.confirmed && !brief.canConfirm)
            const Text(
              'This is a previous version. Open the current project brief to continue.',
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/client/projects/${widget.projectId}',
                ),
                child: const Text('Open project overview'),
              ),
              TextButton(
                onPressed: _busy ? null : _load,
                child: const Text('Reload this version'),
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
    );
  }
}
