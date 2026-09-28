import 'package:flutter/material.dart';
import '../design_system/tokens.dart';
import 'client_controller.dart';
import 'client_gateway.dart';
import 'client_models.dart';
import 'pages/account_page.dart';
import 'pages/settings_page.dart';
import 'pages/providers_page.dart';
import 'pages/enquiries_page.dart';
import 'pages/home_page.dart';
import 'pages/projects_page.dart';
import 'pages/intake_page.dart';
import 'pages/brief_review_page.dart';
import 'pages/project_overview_page.dart';
import 'widgets/connection_panel.dart';

class KallistoClientApp extends StatefulWidget {
  const KallistoClientApp({super.key, this.gateway, this.initialRoute});
  final ClientGateway? gateway;
  final String? initialRoute;
  @override
  State<KallistoClientApp> createState() => _KallistoClientAppState();
}

class _KallistoClientAppState extends State<KallistoClientApp> {
  late final ClientController controller;
  @override
  void initState() {
    super.initState();
    controller = ClientController(widget.gateway ?? FirebaseClientGateway());
    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kallisto',
    debugShowCheckedModeBanner: false,
    theme: KTokens.theme(Brightness.light),
    initialRoute: widget.initialRoute,
    onGenerateRoute: (settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => ListenableBuilder(
        listenable: controller,
        builder: (_, _) =>
            _ClientShell(controller: controller, path: settings.name ?? '/'),
      ),
    ),
  );
}

const _destinations = [
  ('Home', Icons.home_outlined, '/client/home'),
  ('Projects', Icons.folder_open_outlined, '/client/projects'),
  ('Providers', Icons.people_outline, '/client/providers'),
  ('Messages', Icons.chat_bubble_outline, '/client/messages'),
  ('Account', Icons.person_outline, '/client/account'),
];

class _ClientShell extends StatelessWidget {
  const _ClientShell({required this.controller, required this.path});
  final ClientController controller;
  final String path;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.parse(path);
    final parts = uri.pathSegments;
    final enquiryRoute =
        parts.length >= 2 &&
        parts.length <= 3 &&
        parts[0] == 'client' &&
        parts[1] == 'enquiries';
    final providerDetail =
        parts.length == 3 && parts[0] == 'client' && parts[1] == 'providers';
    final settingsPage =
        parts.length == 3 &&
        parts[0] == 'client' &&
        parts[1] == 'settings' &&
        clientSettingsSections.containsKey(parts[2]);
    final intake =
        parts.length == 3 && parts[0] == 'client' && parts[1] == 'intakes';
    final newProject = uri.path == '/client/projects/new';
    final project =
        parts.length == 3 &&
        parts[0] == 'client' &&
        parts[1] == 'projects' &&
        !newProject;
    final brief =
        parts.length == 4 &&
        parts[0] == 'client' &&
        parts[1] == 'projects' &&
        parts[3] == 'requirements';
    final index = enquiryRoute
        ? 2
        : providerDetail
        ? 2
        : settingsPage
        ? 4
        : intake || newProject || brief || project
        ? 1
        : path == '/'
        ? 0
        : _destinations.indexWhere((item) => item.$3 == path);
    final selected = index < 0 ? 0 : index;
    void navigate(int next) async {
      if (path != _destinations[next].$3) {
        if (controller.beforeLeaveEditor != null &&
            !await controller.beforeLeaveEditor!()) {
          return;
        }
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, _destinations[next].$3);
      }
    }

    final Widget page;
    if (enquiryRoute) {
      page = controller.connection != ClientConnection.ready
          ? ConnectionPanel(controller: controller)
          : ClientEnquiriesPage(
              key: ValueKey('${controller.snapshot?.uid}:$path'),
              gateway: controller.gateway,
              enquiryId: parts.length == 3 ? parts[2] : null,
            );
    } else if (providerDetail) {
      page = controller.connection != ClientConnection.ready
          ? ConnectionPanel(controller: controller)
          : ClientProvidersPage(
              key: ValueKey('${controller.snapshot?.uid}:$path'),
              gateway: controller.gateway,
              providerId: parts[2],
            );
    } else if (settingsPage) {
      page = controller.connection != ClientConnection.ready
          ? ConnectionPanel(controller: controller)
          : ClientSettingsPage(
              key: ValueKey('${controller.snapshot?.uid}:$path'),
              gateway: controller.gateway,
              section: parts[2],
            );
    } else if (intake || newProject || brief || project) {
      page = controller.connection != ClientConnection.ready
          ? ConnectionPanel(controller: controller)
          : project
          ? ProjectOverviewPage(
              key: ValueKey('${controller.snapshot?.uid}:$path'),
              gateway: controller.gateway,
              projectId: parts[2],
            )
          : brief
          ? BriefReviewPage(
              key: ValueKey('${controller.snapshot?.uid}:$path'),
              gateway: controller.gateway,
              projectId: parts[2],
              versionId: uri.queryParameters['version_id'],
            )
          : ClientIntakePage(
              key: ValueKey('${controller.snapshot?.uid}:$path'),
              gateway: controller.gateway,
              controller: controller,
              intakeId: intake ? parts[2] : null,
            );
    } else {
      page = switch (index) {
        0 => ClientHomePage(controller: controller),
        1 => ClientProjectsPage(controller: controller),
        2 =>
          controller.connection != ClientConnection.ready
              ? ConnectionPanel(controller: controller)
              : ClientProvidersPage(
                  key: ValueKey(controller.snapshot?.uid),
                  gateway: controller.gateway,
                ),
        3 => _PendingPage(
          controller: controller,
          title: 'Your conversations',
          icon: Icons.chat_bubble_outline,
          description:
              'Messaging is not available yet. Project conversations will appear here once secure messaging is connected.',
        ),
        4 => ClientAccountPage(controller: controller),
        _ => const ClientEmptyState(
          icon: Icons.search_off,
          title: 'Page not found',
          description: 'Choose a destination from the navigation to continue.',
        ),
      };
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final phone = constraints.maxWidth < 600;
        final desktop = constraints.maxWidth >= 1100;
        final content = Expanded(
          child: Column(
            children: [
              Container(
                height: 64,
                padding: EdgeInsets.symmetric(horizontal: phone ? 20 : 32),
                decoration: const BoxDecoration(
                  color: KTokens.surface,
                  border: Border(bottom: BorderSide(color: KTokens.line)),
                ),
                child: Row(
                  children: [
                    if (phone)
                      const Text(
                        'kallisto',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 23,
                          letterSpacing: -1,
                        ),
                      )
                    else
                      Text(
                        'CLIENT WORKSPACE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.4,
                          color: KTokens.muted,
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Your account',
                      onPressed: () => navigate(4),
                      icon: const Icon(Icons.account_circle_outlined),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey(path),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          phone ? 20 : 40,
                          phone ? 28 : 48,
                          phone ? 20 : 40,
                          40,
                        ),
                        child: page,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        return Scaffold(
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!phone)
                  Container(
                    width: desktop ? KTokens.sidebar : 80,
                    decoration: const BoxDecoration(
                      color: KTokens.surface,
                      border: Border(right: BorderSide(color: KTokens.line)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            desktop ? 26 : 20,
                            26,
                            16,
                            38,
                          ),
                          child: Text(
                            desktop ? 'kallisto' : 'k.',
                            style: const TextStyle(
                              fontSize: 29,
                              letterSpacing: -1.4,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        for (var i = 0; i < _destinations.length; i++)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: desktop ? 14 : 12,
                              vertical: 4,
                            ),
                            child: Tooltip(
                              excludeFromSemantics: true,
                              message: _destinations[i].$1,
                              child: Material(
                                color: i == selected
                                    ? KTokens.accentSoft
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  KTokens.radiusSm,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    KTokens.radiusSm,
                                  ),
                                  onTap: () => navigate(i),
                                  child: Semantics(
                                    button: true,
                                    selected: i == selected,
                                    label: desktop ? null : _destinations[i].$1,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: desktop ? 14 : 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _destinations[i].$2,
                                            size: 22,
                                            color: i == selected
                                                ? KTokens.accent
                                                : KTokens.muted,
                                          ),
                                          if (desktop) ...[
                                            const SizedBox(width: 12),
                                            Text(
                                              _destinations[i].$1,
                                              style: TextStyle(
                                                fontWeight: i == selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: i == selected
                                                    ? KTokens.accent
                                                    : KTokens.ink,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (desktop)
                          Padding(
                            padding: const EdgeInsets.all(26),
                            child: Text(
                              'A place for every\nstep of your project.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                content,
              ],
            ),
          ),
          bottomNavigationBar: phone
              ? NavigationBar(
                  selectedIndex: selected,
                  onDestinationSelected: navigate,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    for (final item in _destinations)
                      NavigationDestination(
                        icon: Icon(item.$2),
                        label: item.$1,
                      ),
                  ],
                )
              : null,
        );
      },
    );
  }
}

class _PendingPage extends StatelessWidget {
  const _PendingPage({
    required this.controller,
    required this.title,
    required this.description,
    required this.icon,
  });
  final ClientController controller;
  final String title;
  final String description;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 28),
      if (controller.connection != ClientConnection.ready)
        ConnectionPanel(controller: controller)
      else
        ClientEmptyState(
          icon: icon,
          title: 'Not available yet',
          description: description,
        ),
    ],
  );
}
