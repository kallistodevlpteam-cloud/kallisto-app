import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_controller.dart';
import '../client_models.dart';

class ConnectionPanel extends StatelessWidget {
  const ConnectionPanel({
    super.key,
    required this.controller,
    this.compact = false,
  });
  final ClientController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = controller.connection;
    if (state == ClientConnection.ready) return const SizedBox.shrink();
    final title = switch (state) {
      ClientConnection.loading => 'Opening your workspace',
      ClientConnection.signedOut => 'Your workspace, kept private',
      ClientConnection.enrollment => 'Finish setting up your account',
      ClientConnection.denied => 'Client access required',
      ClientConnection.offline => 'Let’s reconnect',
      _ => 'Unable to open your workspace',
    };
    final detail = controller.message.isNotEmpty
        ? controller.message
        : state == ClientConnection.signedOut
        ? 'Sign in to see your projects, conversations and decisions.'
        : state == ClientConnection.enrollment
        ? 'Your sign-in is ready. Finish setting up your client workspace to start a project.'
        : 'Checking your account and project access.';
    return KPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state == ClientConnection.loading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              state == ClientConnection.offline
                  ? Icons.wifi_off_outlined
                  : Icons.lock_outline,
              size: 22,
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
                if (!compact && state != ClientConnection.loading) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (state == ClientConnection.signedOut ||
                          state == ClientConnection.enrollment)
                        FilledButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/client/account'),
                          child: Text(
                            state == ClientConnection.enrollment
                                ? 'Finish account setup'
                                : 'Sign in',
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: controller.refresh,
                          icon: const Icon(Icons.refresh, size: 17),
                          label: const Text('Retry'),
                        ),
                      if (state == ClientConnection.denied)
                        TextButton(
                          onPressed: controller.signOut,
                          child: const Text('Use another account'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ClientEmptyState extends StatelessWidget {
  const ClientEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => KPanel(
    padding: const EdgeInsets.all(28),
    child: SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    ),
  );
}
