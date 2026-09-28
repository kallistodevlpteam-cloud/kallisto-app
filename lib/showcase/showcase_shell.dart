import 'package:flutter/material.dart';
import '../design_system/components.dart';
import '../design_system/tokens.dart';
import 'sections/foundations.dart';
import 'sections/buttons.dart';
import 'sections/cards.dart';
import 'sections/layouts.dart';
import 'sections/forms.dart';
import 'sections/data_display.dart';
import 'sections/feedback.dart';
import 'sections/motion.dart';

const showcasePages = <({String title, IconData icon, String description})>[
  (
    title: 'Foundations',
    icon: Icons.tune_rounded,
    description: 'The decisions behind a calm, consistent workspace.',
  ),
  (
    title: 'Buttons & actions',
    icon: Icons.ads_click_rounded,
    description:
        'Clear hierarchy. Predictable responses. Every interaction considered.',
  ),
  (
    title: 'Cards & media',
    icon: Icons.crop_landscape_rounded,
    description:
        'Flexible containers for projects, people, documents, and imagery.',
  ),
  (
    title: 'Layouts',
    icon: Icons.space_dashboard_outlined,
    description:
        'Build the workspace from the inside out. Cards, grids, and nested composition.',
  ),
  (
    title: 'Forms & controls',
    icon: Icons.checklist_rounded,
    description: 'Useful defaults, explicit validation, and accessible input.',
  ),
  (
    title: 'Data & navigation',
    icon: Icons.table_chart_outlined,
    description: 'Make dense information easy to scan, sort, and explore.',
  ),
  (
    title: 'Feedback & overlays',
    icon: Icons.chat_bubble_outline_rounded,
    description: 'Keep people informed at every step of an interaction.',
  ),
  (
    title: 'Motion',
    icon: Icons.animation_rounded,
    description: 'Small, purposeful movements that explain what changed.',
  ),
];

class ShowcaseShell extends StatefulWidget {
  const ShowcaseShell({
    super.key,
    required this.dark,
    required this.reduceMotion,
    required this.onThemeChanged,
    required this.onMotionChanged,
  });
  final bool dark;
  final bool reduceMotion;
  final VoidCallback onThemeChanged;
  final ValueChanged<bool> onMotionChanged;
  @override
  State<ShowcaseShell> createState() => _ShowcaseShellState();
}

class _ShowcaseShellState extends State<ShowcaseShell> {
  int selected = 0;
  String search = '';
  bool collapsed = false;
  final scaffold = GlobalKey<ScaffoldState>();
  final searchController = TextEditingController();
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void select(int index) {
    setState(() => selected = index);
    scaffold.currentState?.closeDrawer();
  }

  Widget navigation({bool rail = false, bool inDrawer = false}) => Container(
    width: rail ? 64 : KTokens.sidebar,
    decoration: BoxDecoration(
      color: KTokens.panel(context),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: rail ? 12 : 20,
            vertical: 24,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'k',
                  style: TextStyle(
                    fontSize: 26,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: KTokens.panel(context),
                  ),
                ),
              ),
              if (!rail) ...[
                const SizedBox(width: 9),
                const Flexible(
                  child: Text(
                    'kallisto',
                    style: TextStyle(
                      fontSize: 25,
                      letterSpacing: -1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!rail)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              'DESIGN SYSTEM  /  FLUTTER',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10, letterSpacing: 1.2),
            ),
          ),
        if (!rail)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: searchController,
              onChanged: (value) =>
                  setState(() => search = value.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: 'Find a collection',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          searchController.clear();
                          setState(() => search = '');
                        },
                        icon: const Icon(Icons.close, size: 16),
                      ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (var i = 0; i < showcasePages.length; i++)
                if (search.isEmpty ||
                    showcasePages[i].title.toLowerCase().contains(search))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Tooltip(
                      message: rail ? showcasePages[i].title : '',
                      child: Material(
                        color: selected == i
                            ? KTokens.quiet(context)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          key: ValueKey('nav-$i'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => select(i),
                          child: Semantics(
                            selected: selected == i,
                            button: true,
                            label: rail ? showcasePages[i].title : null,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: rail ? 12 : 14,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    showcasePages[i].icon,
                                    size: 19,
                                    color: selected == i
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                                  if (!rail) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        showcasePages[i].title,
                                        style: TextStyle(
                                          fontWeight: selected == i
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    if (selected == i)
                                      Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
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
              if (!showcasePages.any(
                (page) => page.title.toLowerCase().contains(search),
              ))
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No collections found. Try “cards” or “motion”.'),
                ),
            ],
          ),
        ),
        if (!rail)
          Padding(
            padding: const EdgeInsets.all(16),
            child: KPanel(
              padding: const EdgeInsets.all(12),
              color: KTokens.quiet(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.code, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Built with Flutter',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Interactive specimens from the Kallisto workspace.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        if (!inDrawer && MediaQuery.sizeOf(context).width >= 1100)
          IconButton(
            tooltip: rail ? 'Expand sidebar' : 'Collapse sidebar',
            onPressed: () => setState(() => collapsed = !collapsed),
            icon: Icon(
              rail
                  ? Icons.keyboard_double_arrow_right
                  : Icons.keyboard_double_arrow_left,
            ),
          ),
        const SizedBox(height: 12),
      ],
    ),
  );

  Widget page() => switch (selected) {
    0 => FoundationsSection(
      onBrowseCards: () => select(2),
      onBrowseMotion: () => select(7),
    ),
    1 => const ButtonsSection(),
    2 => const CardsSection(),
    3 => const LayoutsSection(),
    4 => const FormsSection(),
    5 => const DataDisplaySection(),
    6 => const FeedbackSection(),
    _ => const MotionSection(),
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 760;
      final rail = collapsed || constraints.maxWidth < 1100;
      return Scaffold(
        key: scaffold,
        backgroundColor: widget.dark ? const Color(0xFF090D16) : KTokens.chrome,
        drawer: Drawer(
          width: 280,
          child: SafeArea(child: navigation(inDrawer: true)),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(mobile ? 0 : 8),
            child: Row(
              children: [
                if (!mobile) ...[
                  navigation(rail: rail),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(mobile ? 0 : 16),
                    child: ColoredBox(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Column(
                        children: [
                          Container(
                            constraints: const BoxConstraints(minHeight: 56),
                            padding: EdgeInsets.symmetric(
                              horizontal: mobile ? 12 : 24,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: KTokens.panel(context),
                              border: Border(
                                bottom: BorderSide(
                                  color: KTokens.border(context),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (mobile)
                                  IconButton(
                                    tooltip: 'Open navigation',
                                    onPressed: () =>
                                        scaffold.currentState?.openDrawer(),
                                    icon: const Icon(Icons.menu),
                                  ),
                                if (!mobile) ...[
                                  Text(
                                    'Design system',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text('/'),
                                  ),
                                ],
                                Expanded(
                                  child: Text(
                                    showcasePages[selected].title,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (constraints.maxWidth > 600) ...[
                                  const KBadge(
                                    'Interactive library',
                                    tone: KBadgeTone.success,
                                    icon: Icons.circle_outlined,
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                IconButton(
                                  tooltip: widget.dark
                                      ? 'Use light theme'
                                      : 'Use dark theme',
                                  onPressed: widget.onThemeChanged,
                                  icon: Icon(
                                    widget.dark
                                        ? Icons.light_mode_outlined
                                        : Icons.dark_mode_outlined,
                                    size: 20,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: 'Showcase preferences',
                                  onSelected: (value) => widget.onMotionChanged(
                                    !widget.reduceMotion,
                                  ),
                                  itemBuilder: (context) => [
                                    CheckedPopupMenuItem(
                                      value: 'motion',
                                      checked: widget.reduceMotion,
                                      child: const Text('Reduce motion'),
                                    ),
                                  ],
                                  icon: const Icon(Icons.tune, size: 20),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: KTokens.motion(context),
                              child: SingleChildScrollView(
                                key: ValueKey(selected),
                                padding: EdgeInsets.symmetric(
                                  horizontal: mobile ? 18 : 32,
                                  vertical: mobile ? 24 : 36,
                                ),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: KTokens.workspace,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'THE KALLISTO LANGUAGE',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 1.5,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${(selected + 1).toString().padLeft(2, '0')} / 08',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          showcasePages[selected].title,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineLarge,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          showcasePages[selected].description,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 28),
                                        page(),
                                        const Divider(),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          child: Text(
                                            'Kallisto / Flutter component library · All project content is illustrative.',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
