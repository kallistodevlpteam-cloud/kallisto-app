import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_gateway.dart';
import '../workflow_models.dart';

class IntakeListPanel extends StatefulWidget {
  const IntakeListPanel({super.key, required this.gateway});
  final ClientGateway gateway;
  @override
  State<IntakeListPanel> createState() => _IntakeListPanelState();
}

class _IntakeListPanelState extends State<IntakeListPanel> {
  List<IntakeSummary>? _items;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final items = await widget.gateway.intakes();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) => KPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your saved drafts',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text('Return to your ideas and update a brief at your own pace.'),
        const SizedBox(height: 12),
        if (_failed)
          TextButton(
            onPressed: _load,
            child: const Text('Drafts could not load. Retry'),
          )
        else if (_items == null)
          const LinearProgressIndicator()
        else if (_items!.isEmpty)
          const Text('No saved drafts yet.')
        else
          for (final draft in _items!)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_note_outlined),
              title: Text(
                draft.projectId == null
                    ? 'Project draft'
                    : 'Linked project brief',
              ),
              subtitle: Text('Revision ${draft.revision} · ${draft.status}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: ['active', 'paused'].contains(draft.status)
                  ? () => Navigator.pushNamed(
                      context,
                      '/client/intakes/${draft.id}',
                    )
                  : null,
            ),
      ],
    ),
  );
}
