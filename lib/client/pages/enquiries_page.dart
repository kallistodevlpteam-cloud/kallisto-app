import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_gateway.dart';
import '../client_models.dart';
import '../sharing_models.dart';

class ClientEnquiriesPage extends StatefulWidget {
  const ClientEnquiriesPage({super.key, required this.gateway, this.enquiryId});
  final ClientGateway gateway;
  final String? enquiryId;
  @override
  State<ClientEnquiriesPage> createState() => _ClientEnquiriesPageState();
}

class _ClientEnquiriesPageState extends State<ClientEnquiriesPage> {
  List<ClientEnquiry> _items = [];
  String? _cursor;
  String _error = '';
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool next = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final page = widget.enquiryId == null
          ? await widget.gateway.enquiries(cursor: next ? _cursor : null)
          : EnquiryPage([
              await widget.gateway.enquiry(widget.enquiryId!),
            ], null);
      if (mounted) {
        setState(() {
          _items = [if (next) ..._items, ...page.items];
          _cursor = page.cursor;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _items = [];
          _cursor = null;
          _error = error is ClientFailure
              ? error.message
              : 'Could not load enquiries. Please retry.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextButton.icon(
        onPressed: () =>
            Navigator.pushReplacementNamed(context, '/client/providers'),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Providers'),
      ),
      Text('Your enquiries', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 12),
      const Text(
        'Each enquiry keeps the exact brief disclosed to its recipient. Sharing does not appoint a provider.',
      ),
      const SizedBox(height: 24),
      if (_busy) const LinearProgressIndicator(),
      if (_error.isNotEmpty) ...[
        Text(_error),
        OutlinedButton(
          onPressed: _busy ? null : () => _load(),
          child: const Text('Retry'),
        ),
      ],
      if (!_busy && _error.isEmpty && _items.isEmpty)
        const KPanel(
          child: Text(
            'No enquiries yet. Preview and share a confirmed brief from a provider profile.',
          ),
        ),
      for (final item in _items)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: KPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                KBadge(item.status),
                const SizedBox(height: 12),
                if (widget.enquiryId == null)
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/client/enquiries/${Uri.encodeComponent(item.id)}',
                    ),
                    child: const Text('View shared brief'),
                  ),
                if (widget.enquiryId != null) ...[
                  for (final entry in item.details.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${entry.key.replaceFirst('brief.', '').replaceAll('_', ' ')}: ${entry.value}',
                      ),
                    ),
                  const Text('Offer comparison is not available yet.'),
                  if (item.conversationId != null)
                    OutlinedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/messages/${Uri.encodeComponent(item.conversationId!)}',
                      ),
                      child: const Text('Open enquiry conversation'),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/client/projects/${Uri.encodeComponent(item.projectId)}',
                    ),
                    child: const Text('Open project'),
                  ),
                ],
              ],
            ),
          ),
        ),
      if (_cursor != null)
        OutlinedButton(
          onPressed: _busy ? null : () => _load(next: true),
          child: const Text('Load more enquiries'),
        ),
    ],
  );
}
