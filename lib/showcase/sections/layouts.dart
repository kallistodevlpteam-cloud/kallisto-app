import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';
import 'cards.dart';

class LayoutsSection extends StatefulWidget {
  const LayoutsSection({super.key});
  @override
  State<LayoutsSection> createState() => _LayoutsSectionState();
}

class _LayoutsSectionState extends State<LayoutsSection> {
  int layout = 0;
  bool inspector = true;
  double previewWidth = 1120;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      KSection(
        title: 'The workspace frame',
        description:
            'The web app’s 240 px sidebar, 56 px rail, 48 px topbar, and 340 px Odin panel form the source layout vocabulary.',
        child: KPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final value in [
                    'Sidebar · 240',
                    'Rail · 56',
                    'Topbar · 48',
                    'Odin · 340',
                    'Content · max 1120',
                  ])
                    KBadge(value),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, box) {
                  final desktop = box.maxWidth >= 660;
                  return Container(
                    height: 300,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: KTokens.quiet(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (desktop) ...[
                          Container(
                            width: 115,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: KTokens.panel(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                const Text(
                                  'kallisto',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                for (final name in [
                                  'Overview',
                                  'Projects',
                                  'Documents',
                                  'Team',
                                ])
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 18),
                                    child: Text(
                                      name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: KPanel(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (!desktop) ...[
                                      const Icon(Icons.menu, size: 16),
                                      const SizedBox(width: 8),
                                    ],
                                    const Expanded(
                                      child: Text(
                                        'Project workspace',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Toggle layout inspector',
                                      onPressed: () => setState(
                                        () => inspector = !inspector,
                                      ),
                                      icon: const Icon(
                                        Icons.view_sidebar_outlined,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: _wireBlock(
                                                context,
                                                'Main content',
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _wireBlock(
                                                    context,
                                                    'Card',
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: _wireBlock(
                                                    context,
                                                    'Card',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (inspector && desktop) ...[
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          width: 100,
                                          child: _wireBlock(
                                            context,
                                            'Odin\ninspector',
                                            height: double.infinity,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              Text(
                'This miniature illustrates the source shell. The showcase adapts its own navigation at 760 / 1100 px to stay usable on phones.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      KSection(
        title: 'Responsive composition lab',
        description:
            'Choose a pattern and resize the preview. Content and images reflow together.',
        tag: 'Interactive',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in <(int, String)>[
                  (0, 'Card grid'),
                  (1, 'Split workspace'),
                  (2, 'Board'),
                  (3, 'List + detail'),
                ])
                  ChoiceChip(
                    label: Text(item.$2),
                    selected: layout == item.$1,
                    onSelected: (_) => setState(() => layout = item.$1),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            KPanel(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.devices_outlined, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: previewWidth,
                      min: 320,
                      max: 1120,
                      divisions: 20,
                      label: '${previewWidth.round()} px',
                      onChanged: (value) =>
                          setState(() => previewWidth = value),
                    ),
                  ),
                  Text('${previewWidth.round()} px'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.topLeft,
              child: AnimatedContainer(
                duration: KTokens.motion(context),
                width: previewWidth,
                child: KPanel(
                  color: KTokens.quiet(context),
                  padding: const EdgeInsets.all(12),
                  child: AnimatedSwitcher(
                    duration: KTokens.motion(context),
                    child: KeyedSubtree(
                      key: ValueKey(layout),
                      child: switch (layout) {
                        0 => const KGrid(
                          minWidth: 220,
                          children: [
                            ProjectCard(compact: true),
                            ProjectCard(
                              title: 'Concept & spatial study',
                              asset: 'floor-plans.jpg',
                              compact: true,
                            ),
                            ProjectCard(
                              title: 'Material explorations',
                              asset: 'visualisations.jpg',
                              compact: true,
                            ),
                          ],
                        ),
                        1 => _split(context),
                        2 => KGrid(
                          minWidth: 210,
                          children: [
                            for (final column in [
                              'To do',
                              'In progress',
                              'In review',
                            ])
                              KPanel(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      column,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    for (final task in [
                                      'Concept plans',
                                      'Material selection',
                                    ])
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: KPanel(
                                          padding: const EdgeInsets.all(12),
                                          color: KTokens.quiet(context),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(task),
                                              const SizedBox(height: 12),
                                              const KBadge('Sample task'),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        _ => _split(context, list: true),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      KSection(
        title: 'Layout rules',
        description:
            'Use constraints rather than a fixed canvas. Preserve hierarchy as space changes.',
        child: KGrid(
          minWidth: 250,
          children: [
            for (final item in <(String, String, IconData)>[
              (
                'Bounded content',
                '1120 px maximum keeps reading and action distances manageable.',
                Icons.width_normal_outlined,
              ),
              (
                'Intrinsic height',
                'Cards grow with content and large text instead of clipping it.',
                Icons.height,
              ),
              (
                'Nested surfaces',
                'Outer groups use a subtle surface; inner cards use the main surface.',
                Icons.layers_outlined,
              ),
            ])
              KPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.$3),
                    const SizedBox(height: 16),
                    Text(
                      item.$1,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(item.$2),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _split(BuildContext context, {bool list = false}) => LayoutBuilder(
    builder: (context, box) {
      final main = list
          ? KPanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < 4; i++)
                    ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text('Sample project ${i + 1}'),
                      subtitle: const Text('Concept design'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showDemoMessage(
                        context,
                        'Sample project ${i + 1} selected',
                      ),
                    ),
                ],
              ),
            )
          : const ProjectCard(compact: true);
      final side = KPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const KBadge('Illustrative data', tone: KBadgeTone.info),
            const SizedBox(height: 16),
            const Text('Residential architecture\nKochi, Kerala\n2,400 sq ft'),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Related documents'),
            const SizedBox(height: 12),
            KPanel(
              color: KTokens.quiet(context),
              padding: const EdgeInsets.all(12),
              child: const Row(
                children: [
                  Icon(Icons.description_outlined, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Concept plan · v03')),
                ],
              ),
            ),
          ],
        ),
      );
      return box.maxWidth > 620
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: main),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: side),
              ],
            )
          : Column(children: [main, const SizedBox(height: 16), side]);
    },
  );

  Widget _wireBlock(BuildContext context, String label, {double height = 58}) =>
      Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .15),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
}
