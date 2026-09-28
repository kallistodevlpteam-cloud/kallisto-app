import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_controller.dart';
import '../client_models.dart';
import '../widgets/connection_panel.dart';

class ClientProjectsPage extends StatelessWidget {
  const ClientProjectsPage({super.key, required this.controller});
  final ClientController controller;
  @override
  Widget build(BuildContext context) {
    final projects = controller.snapshot?.projects ?? const <ClientProject>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Your projects',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            IconButton(
              onPressed: controller.connection == ClientConnection.loading
                  ? null
                  : controller.refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh projects',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Your briefs, decisions and progress, in one place.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        if (controller.connection != ClientConnection.ready)
          ConnectionPanel(controller: controller)
        else if (projects.isEmpty)
          const ClientEmptyState(
            icon: Icons.folder_open_outlined,
            title: 'No projects to show yet',
            description:
                'Your recorded projects will appear here. New project intake is not available yet.',
          )
        else
          KGrid(
            minWidth: 290,
            children: [
              for (final project in projects)
                KPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.architecture_outlined),
                          const Spacer(),
                          KBadge(project.status.replaceAll('_', ' ')),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        project.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        project.location ?? 'Location not recorded',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 22),
                      const Divider(),
                      const SizedBox(height: 14),
                      Text(
                        'Current phase',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project.phase,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        if (controller.snapshot?.nextCursor != null) ...[
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => controller.refresh(next: true),
            child: const Text('Load more projects'),
          ),
        ],
      ],
    );
  }
}
