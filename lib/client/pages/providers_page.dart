import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_gateway.dart';
import '../client_models.dart';
import '../provider_models.dart';
import '../widgets/share_brief_panel.dart';

class ClientProvidersPage extends StatefulWidget {
  const ClientProvidersPage({
    super.key,
    required this.gateway,
    this.providerId,
  });
  final ClientGateway gateway;
  final String? providerId;
  @override
  State<ClientProvidersPage> createState() => _ClientProvidersPageState();
}

class _ClientProvidersPageState extends State<ClientProvidersPage> {
  final _coverage = TextEditingController();
  String? _category, _cursor;
  String _error = '';
  bool _busy = false;
  List<LeadProvider> _items = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _coverage.dispose();
    super.dispose();
  }

  Future<void> _load({bool next = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final id = widget.providerId;
      final page = id == null
          ? await widget.gateway.providers(
              category: _category,
              coverage: _coverage.text.trim().isEmpty
                  ? null
                  : _coverage.text.trim(),
              cursor: next ? _cursor : null,
            )
          : ProviderPage([await widget.gateway.provider(id)], null);
      if (mounted) {
        setState(() {
          _items = [if (next) ..._items, ...page.items];
          _cursor = page.cursor;
        });
      }
    } on ClientFailure catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _items = [];
          _cursor = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load providers. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _card(LeadProvider provider) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: KPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(provider.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(provider.summary),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.services
                .map((s) => KBadge(s.replaceAll('_', ' ')))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Verified scope: ${provider.qualifications.map((s) => s.replaceAll('_', ' ')).join(', ')}',
          ),
          Text(
            'Coverage: ${provider.coverage.isEmpty ? 'No coverage published' : provider.coverage.join(', ')}',
          ),
          const SizedBox(height: 16),
          if (widget.providerId == null)
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                '/client/providers/${Uri.encodeComponent(provider.id)}',
              ),
              child: const Text('View profile'),
            ),
          if (widget.providerId != null)
            ShareBriefPanel(gateway: widget.gateway, provider: provider),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.providerId == null)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/client/enquiries'),
            child: const Text('Your enquiries'),
          ),
        ),
      if (widget.providerId != null)
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Providers'),
        ),
      Text(
        widget.providerId == null
            ? 'Find your professional'
            : 'Provider profile',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'Published lead providers with current verified scope. Your brief stays private until you explicitly share it.',
      ),
      const SizedBox(height: 24),
      if (widget.providerId == null)
        KPanel(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Service'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All services'),
                  ),
                  for (final code in [
                    'architectural_design',
                    'interior_design',
                    'construction_coordination',
                    'construction_execution',
                    'renovation',
                    'other',
                  ])
                    DropdownMenuItem(
                      value: code,
                      child: Text(code.replaceAll('_', ' ')),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _coverage,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Coverage code',
                  hintText: 'Leave empty for all regions',
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: _busy ? null : () => _load(),
                  child: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 24),
      if (_busy) const LinearProgressIndicator(),
      if (_error.isNotEmpty)
        KPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_error),
              TextButton(
                onPressed: _busy ? null : () => _load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      if (!_busy && _error.isEmpty && _items.isEmpty)
        KPanel(
          child: Text(
            _cursor == null
                ? 'No eligible providers found for these filters.'
                : 'No matching providers on this page. Continue to check the next page.',
          ),
        ),
      ..._items.map(_card),
      if (_cursor != null)
        OutlinedButton(
          onPressed: _busy ? null : () => _load(next: true),
          child: const Text('Load more providers'),
        ),
    ],
  );
}
