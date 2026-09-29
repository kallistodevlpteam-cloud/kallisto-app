import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_gateway.dart';
import '../client_models.dart';
import '../workflow_models.dart';

class ProjectOverviewPage extends StatefulWidget {
  const ProjectOverviewPage({
    super.key,
    required this.gateway,
    required this.projectId,
  });
  final ClientGateway gateway;
  final String projectId;
  @override
  State<ProjectOverviewPage> createState() => _ProjectOverviewPageState();
}

class _ProjectOverviewPageState extends State<ProjectOverviewPage> {
  ProjectDetail? _project;
  String _error = '';
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final project = await widget.gateway.project(widget.projectId);
      if (mounted) setState(() => _project = project);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ClientFailure
              ? e.message
              : 'Could not load this project. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/client/projects'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('All projects'),
        ),
        const SizedBox(height: 16),
        if (project == null) ...[
          Text(
            'Your project',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 20),
          if (_busy) const LinearProgressIndicator(),
        ] else ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              KBadge(project.project.status.replaceAll('_', ' ')),
              KBadge(
                project.project.phase.replaceAll('_', ' '),
                tone: KBadgeTone.info,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            project.project.name,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          Text(
            project.project.location ?? 'Location not recorded',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 28),
          KGrid(
            minWidth: 300,
            children: [
              KPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.description_outlined),
                    const SizedBox(height: 14),
                    Text(
                      'Your project brief',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project.currentVersion == project.confirmedVersion
                          ? 'The current brief is confirmed.'
                          : 'Review and confirm the current version when you are ready.',
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/client/projects/${widget.projectId}/requirements',
                      ),
                      child: const Text('Review brief'),
                    ),
                    if (project.intakeId != null)
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/client/intakes/${project.intakeId}',
                        ),
                        child: const Text('Edit working draft'),
                      ),
                  ],
                ),
              ),
              KPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.route_outlined),
                    const SizedBox(height: 14),
                    Text(
                      'Your next step',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project.currentVersion == project.confirmedVersion
                          ? 'Explore eligible providers and review exactly what you share from your confirmed brief.'
                          : 'Check your requirements and leave any undecided details open.',
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/odin?project_id=${Uri.encodeQueryComponent(widget.projectId)}',
                      ),
                      child: const Text('Ask Odin about this project'),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/client/providers'),
                      child: const Text('Explore providers'),
                    ),
                    if (project.policyUnavailable) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'The project remains in requirements. Its lifecycle policy is not configured; later phase transitions are unavailable.',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          KPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Everything has its place',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Documents, design reviews, schedule, site progress, payments and handover will connect to this same project. Those workflows are not available in this build.',
                ),
              ],
            ),
          ),
        ],
        if (_error.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error)),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: _busy ? null : _load,
          child: const Text('Refresh project'),
        ),
      ],
    );
  }
}
