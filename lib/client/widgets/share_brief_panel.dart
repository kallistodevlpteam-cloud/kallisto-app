import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_gateway.dart';
import '../client_models.dart';
import '../provider_models.dart';
import '../sharing_models.dart';

class ShareBriefPanel extends StatefulWidget {
  const ShareBriefPanel({
    super.key,
    required this.gateway,
    required this.provider,
  });
  final ClientGateway gateway;
  final LeadProvider provider;
  @override
  State<ShareBriefPanel> createState() => _ShareBriefPanelState();
}

class _ShareBriefPanelState extends State<ShareBriefPanel> {
  List<ClientProject> _projects = [];
  String? _project, _cursor, _sent;
  String _error = '', _key = clientIntentId();
  bool _busy = false, _reviewed = false;
  BriefDisclosure? _preview;
  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _busy = true);
    try {
      final page = await widget.gateway.load(cursor: _cursor);
      if (mounted) {
        setState(() {
          _projects = [..._projects, ...?page?.projects];
          _cursor = page?.nextCursor;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load your projects.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _prepare() async {
    if (_project == null || _busy) return;
    setState(() {
      _busy = true;
      _error = '';
      _preview = null;
      _reviewed = false;
    });
    try {
      final brief = await widget.gateway.requirements(_project!);
      if (!brief.confirmed) {
        if (mounted) {
          setState(
            () => _error =
                'Confirm the current brief in your project before sharing it.',
          );
        }
        return;
      }
      final preview = await widget.gateway.previewShare(
        _project!,
        widget.provider.recipientUid,
        brief,
      );
      if (mounted) {
        setState(() {
          _preview = preview;
          _key = clientIntentId();
        });
      }
    } on ClientFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not prepare the disclosure. Nothing was sent.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    if (_preview == null || !_reviewed || _busy) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final enquiry = await widget.gateway.shareBrief(_preview!, _key);
      if (mounted) setState(() => _sent = enquiry);
    } on ClientFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'The result is uncertain. Retry this same disclosure to recover its outcome.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => KPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share a confirmed brief',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'Recipient: ${widget.provider.name}. Sharing creates an enquiry; it does not appoint this provider or approve payment.',
        ),
        const SizedBox(height: 16),
        if (_busy) const LinearProgressIndicator(),
        if (_error.isNotEmpty) Text(_error),
        if (_sent != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText('Brief shared. Enquiry: $_sent'),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/client/enquiries/${Uri.encodeComponent(_sent!)}',
                ),
                child: const Text('Open enquiry'),
              ),
            ],
          )
        else ...[
          DropdownButtonFormField<String>(
            initialValue: _project,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Your project'),
            items: _projects
                .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                .toList(),
            onChanged: _busy
                ? null
                : (value) => setState(() {
                    _project = value;
                    _preview = null;
                    _reviewed = false;
                  }),
          ),
          if (_projects.isEmpty && !_busy)
            const Text('Create and confirm a project brief first.'),
          if (_cursor != null)
            TextButton(
              onPressed: _busy ? null : _loadProjects,
              child: const Text('Load more projects'),
            ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _busy || _project == null ? null : _prepare,
            child: const Text('Preview exact disclosure'),
          ),
          if (_preview case final preview?) ...[
            const SizedBox(height: 20),
            Text(
              'Only the following confirmed details will be sent:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('Title: ${preview.content['title']}'),
            Text('Summary: ${preview.content['scope_summary']}'),
            for (final entry
                in (preview.content['permitted_details']
                        as Map<String, dynamic>)
                    .entries)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${entry.key.replaceFirst('brief.', '').replaceAll('_', ' ')}: ${entry.value}',
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'No audio, intake history or attachments are included in this disclosure.',
            ),
            SelectableText(
              'Brief version: ${preview.versionId}\nDisclosure: ${preview.manifestHash}',
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'I reviewed these details and want to share them with ${widget.provider.name}.',
              ),
              value: _reviewed,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _reviewed = value ?? false),
            ),
            FilledButton(
              onPressed: _busy || !_reviewed ? null : _send,
              child: const Text('Share this brief with provider'),
            ),
          ],
        ],
      ],
    ),
  );
}
