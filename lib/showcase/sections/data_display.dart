import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';

class DataDisplaySection extends StatefulWidget {
  const DataDisplaySection({super.key});
  @override
  State<DataDisplaySection> createState() => _DataDisplaySectionState();
}

class _DataDisplaySectionState extends State<DataDisplaySection> {
  bool ascending = true;
  String query = '';
  int tab = 0;
  int currentStep = 1;
  final selected = <String>{};
  static const records = <(String, String, String)>[
    ('Courtyard residence', 'Architecture', 'In progress'),
    ('Hill house', 'Interiors', 'In review'),
    ('Lakeside studio', 'Architecture', 'Draft'),
    ('Urban retreat', 'Landscape', 'In progress'),
  ];
  @override
  Widget build(BuildContext context) {
    final rows =
        records
            .where((row) => row.$1.toLowerCase().contains(query.toLowerCase()))
            .toList()
          ..sort(
            (a, b) => ascending ? a.$1.compareTo(b.$1) : b.$1.compareTo(a.$1),
          );
    return Column(
      children: [
        KSection(
          title: 'Status vocabulary',
          description:
              'Status uses text and optional iconography, never color alone. All values below are specimens.',
          child: const KPanel(
            child: Wrap(
              spacing: 10,
              runSpacing: 12,
              children: [
                KBadge('Draft', icon: Icons.edit_outlined),
                KBadge(
                  'Submitted',
                  tone: KBadgeTone.info,
                  icon: Icons.send_outlined,
                ),
                KBadge(
                  'Pending',
                  tone: KBadgeTone.warning,
                  icon: Icons.schedule,
                ),
                KBadge('Approved', tone: KBadgeTone.success, icon: Icons.check),
                KBadge('Rejected', tone: KBadgeTone.danger, icon: Icons.close),
                KBadge('Withdrawn', icon: Icons.undo),
              ],
            ),
          ),
        ),
        KSection(
          title: 'Project table',
          description:
              'Search, sort by name, and select rows. On small screens the table scrolls horizontally.',
          tag: 'Interactive',
          child: KPanel(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 260,
                        child: TextField(
                          onChanged: (value) => setState(() => query = value),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search sample projects',
                          ),
                        ),
                      ),
                      KBadge('${selected.length} selected'),
                    ],
                  ),
                ),
                const Divider(),
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No projects match this search.'),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      sortColumnIndex: 0,
                      sortAscending: ascending,
                      showCheckboxColumn: true,
                      headingRowColor: WidgetStatePropertyAll(
                        KTokens.quiet(context),
                      ),
                      columns: [
                        DataColumn(
                          label: const Text('Project name'),
                          onSort: (_, value) =>
                              setState(() => ascending = value),
                        ),
                        const DataColumn(label: Text('Service')),
                        const DataColumn(label: Text('Status')),
                      ],
                      rows: [
                        for (final row in rows)
                          DataRow(
                            selected: selected.contains(row.$1),
                            onSelectChanged: (value) => setState(
                              () => value!
                                  ? selected.add(row.$1)
                                  : selected.remove(row.$1),
                            ),
                            cells: [
                              DataCell(Text(row.$1)),
                              DataCell(Text(row.$2)),
                              DataCell(
                                KBadge(
                                  row.$3,
                                  tone: row.$3 == 'Draft'
                                      ? KBadgeTone.neutral
                                      : row.$3 == 'In review'
                                      ? KBadgeTone.warning
                                      : KBadgeTone.info,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${rows.length} sample projects · illustrative data',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        KSection(
          title: 'Tabs & breadcrumbs',
          description:
              'Preserve a clear location and switch between related views.',
          child: KPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => tab = 0),
                      child: const Text('Projects'),
                    ),
                    const Icon(Icons.chevron_right, size: 14),
                    const Text('Courtyard residence'),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in <(int, String)>[
                      (0, 'Overview'),
                      (1, 'Documents'),
                      (2, 'Activity'),
                    ])
                      ChoiceChip(
                        label: Text(item.$2),
                        selected: tab == item.$1,
                        onSelected: (_) => setState(() => tab = item.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: KTokens.motion(context),
                  child: KPanel(
                    key: ValueKey(tab),
                    color: KTokens.quiet(context),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        [
                          'A project overview keeps scope, team, and next actions together.',
                          'Document versions preserve the exact submitted files and their history.',
                          'Activity records preserve actors, timestamps, and the action context.',
                        ][tab],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        KSection(
          title: 'Steps & activity timeline',
          description:
              'A visual stepper demonstrates navigation only; it does not authorize a real phase transition.',
          child: KGrid(
            minWidth: 300,
            children: [
              KPanel(
                padding: EdgeInsets.zero,
                child: Stepper(
                  currentStep: currentStep,
                  onStepTapped: (index) => setState(() => currentStep = index),
                  controlsBuilder: (context, details) =>
                      const SizedBox.shrink(),
                  steps: [
                    for (final item in <(int, String)>[
                      (0, 'Requirements'),
                      (1, 'Concept design'),
                      (2, 'Client review'),
                    ])
                      Step(
                        title: Text(item.$2),
                        content: const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Sample step content'),
                        ),
                        isActive: item.$1 <= currentStep,
                        state: item.$1 < currentStep
                            ? StepState.complete
                            : StepState.indexed,
                      ),
                  ],
                ),
              ),
              KPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent activity',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 20),
                    for (final item in <(String, String, IconData)>[
                      (
                        'Drawing version added',
                        'Concept plan · v03',
                        Icons.description_outlined,
                      ),
                      (
                        'Review requested',
                        'Exact version shared for review',
                        Icons.rate_review_outlined,
                      ),
                      (
                        'Requirements acknowledged',
                        'Requirement version · v02',
                        Icons.check_circle_outline,
                      ),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: KTokens.quiet(context),
                              child: Icon(item.$3, size: 17),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.$1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    item.$2,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  Text(
                                    'Sample event',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
