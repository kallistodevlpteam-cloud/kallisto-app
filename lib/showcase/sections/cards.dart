import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    this.title = 'The courtyard residence',
    this.asset = 'residence.jpg',
    this.compact = false,
  });
  final String title;
  final String asset;
  final bool compact;
  @override
  Widget build(BuildContext context) => KInteractiveCard(
    label: 'View $title',
    onTap: () => showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Project preview',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close preview',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: KImage(asset, height: 260),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Illustrative project card. Project metadata, documents, and approvals in the production app come from the authorized backend.',
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            KImage(asset, height: compact ? 130 : 190),
            Positioned(
              top: 12,
              left: 12,
              child: Material(
                color: KTokens.panel(context),
                borderRadius: BorderRadius.circular(7),
                child: const KBadge('Concept design', tone: KBadgeTone.info),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: KTokens.panel(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_outward, size: 17),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Residential architecture · Kochi',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.square_foot, size: 16),
                  SizedBox(width: 5),
                  Expanded(child: Text('2,400 sq ft')),
                  Text('2026', style: TextStyle(color: KTokens.soft)),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class CardsSection extends StatefulWidget {
  const CardsSection({super.key});
  @override
  State<CardsSection> createState() => _CardsSectionState();
}

class _CardsSectionState extends State<CardsSection> {
  bool saved = false;
  bool selected = false;
  String filter = 'All cards';
  final filters = const [
    'All cards',
    'Image cards',
    'Content cards',
    'Nested cards',
  ];
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final label in filters)
            ChoiceChip(
              label: Text(label),
              selected: filter == label,
              onSelected: (_) => setState(() => filter = label),
            ),
        ],
      ),
      const SizedBox(height: 24),
      if (filter == 'All cards' || filter == 'Image cards') ...[
        KSection(
          title: 'Images that carry context',
          description:
              'Project cover, horizontal media, and full-bleed imagery. Tap a project to open its preview.',
          tag: 'Media',
          child: KGrid(
            minWidth: 280,
            children: [
              const KSpecimen(
                name: 'Project / cover image',
                detail: 'Cover → status → title → metadata',
                child: ProjectCard(),
              ),
              KSpecimen(
                name: 'Editorial / image overlay',
                detail: 'Scrim ensures readable white text.',
                child: KInteractiveCard(
                  label: 'Open visualisation collection',
                  onTap: () => showDemoMessage(
                    context,
                    'Visualisation collection selected',
                  ),
                  child: Stack(
                    children: [
                      const KImage('visualisations.jpg', height: 300),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: .86),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STUDIO COLLECTION',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                letterSpacing: 1.4,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Ideas, made visible.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Explore visualisations  ↗',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              KSpecimen(
                name: 'Document / image thumbnail',
                detail: 'Media paired with version and file metadata.',
                child: KPanel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: const KImage('floor-plans.jpg', height: 160),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const KBadge(
                              'Drawing · v03',
                              icon: Icons.description_outlined,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Ground floor plan',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PDF · 2.4 MB · Sample asset',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => showDemoMessage(
                                context,
                                'Document preview is a UI specimen.',
                              ),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Preview drawing'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        KSection(
          title: 'Horizontal media card',
          description:
              'Image and content sit side by side on wide screens and stack on compact screens.',
          child: KPanel(
            padding: EdgeInsets.zero,
            child: LayoutBuilder(
              builder: (context, box) {
                final details = Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const KBadge('Portfolio', tone: KBadgeTone.info),
                      const SizedBox(height: 14),
                      Text(
                        'A quiet place to call home.',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Natural materials, thoughtful proportions, and light-filled spaces.',
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () =>
                            showDemoMessage(context, 'Portfolio card selected'),
                        icon: const Icon(Icons.arrow_outward, size: 16),
                        label: const Text('Explore project'),
                      ),
                    ],
                  ),
                );
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: box.maxWidth >= 650
                      ? Row(
                          children: [
                            const Expanded(
                              child: KImage('residence.jpg', height: 265),
                            ),
                            Expanded(child: details),
                          ],
                        )
                      : Column(
                          children: [
                            const KImage('residence.jpg', height: 200),
                            details,
                          ],
                        ),
                );
              },
            ),
          ),
        ),
      ],
      if (filter == 'All cards' || filter == 'Content cards')
        KSection(
          title: 'More than a container',
          description:
              'Specialist, metric, task, selectable, and activity cards use the same visual foundations.',
          tag: 'Content',
          child: KGrid(
            minWidth: 260,
            children: [
              KSpecimen(
                name: 'Specialist profile',
                detail: 'Avatar, verification, expertise, save action.',
                child: KPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 27,
                            backgroundImage: AssetImage(
                              'assets/images/avatar.jpg',
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: saved
                                ? 'Unsave specialist'
                                : 'Save specialist',
                            isSelected: saved,
                            onPressed: () => setState(() => saved = !saved),
                            icon: const Icon(Icons.bookmark_border),
                            selectedIcon: const Icon(Icons.bookmark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Priya · Sample profile',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      const KBadge(
                        'Verified · sample',
                        tone: KBadgeTone.success,
                        icon: Icons.verified_outlined,
                      ),
                      const SizedBox(height: 12),
                      const Text('Architecture & interior design'),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('8 yrs\nexperience')),
                          Expanded(
                            child: Text(
                              '24\nprojects',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Kochi\nlocation',
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              KSpecimen(
                name: 'Metric',
                detail: 'One number with a meaningful label.',
                child: KPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.folder_outlined, size: 20),
                          Spacer(),
                          KBadge('Sample'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '12',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Active projects'),
                      const SizedBox(height: 24),
                      Text(
                        'Across 3 project phases',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(
                        value: .65,
                        minHeight: 5,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ],
                  ),
                ),
              ),
              KSpecimen(
                name: 'Task / progress',
                detail: 'Assignee, status, due date, and progress.',
                child: KPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const KBadge('In progress', tone: KBadgeTone.info),
                      const SizedBox(height: 16),
                      Text(
                        'Review concept drawings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Confirm the sample drawing set is ready for internal review.',
                      ),
                      const SizedBox(height: 20),
                      const LinearProgressIndicator(value: .6, minHeight: 5),
                      const SizedBox(height: 10),
                      const Text('3 of 5 items complete'),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            child: Text('AP', style: TextStyle(fontSize: 10)),
                          ),
                          SizedBox(width: 8),
                          Expanded(child: Text('Design team')),
                          Icon(Icons.schedule, size: 15),
                          SizedBox(width: 4),
                          Text('Today'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              KSpecimen(
                name: 'Selectable card',
                detail: 'Entire card is keyboard and touch accessible.',
                child: Semantics(
                  selected: selected,
                  child: KInteractiveCard(
                    label: 'Select architecture service',
                    onTap: () => setState(() => selected = !selected),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      color: selected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .08)
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.architecture, size: 28),
                              const Spacer(),
                              Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : KTokens.soft,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Architecture',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Planning, concept design, and detailed drawings.',
                          ),
                          const SizedBox(height: 18),
                          Text(
                            selected ? 'Selected' : 'Select this service',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              KSpecimen(
                name: 'Activity',
                detail: 'Actor, event, and exact version context.',
                child: KPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            child: Icon(Icons.history, size: 18),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Design team',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Added a new concept drawing'),
                      const SizedBox(height: 12),
                      const KBadge(
                        'Concept plan · v03',
                        icon: Icons.insert_drive_file_outlined,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sample event · just now',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              KSpecimen(
                name: 'Minimal / outline',
                detail: 'A quiet surface for secondary content.',
                child: KPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 28),
                      const SizedBox(height: 18),
                      Text(
                        'Add a reference',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Keep useful drawings and material references together.',
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => showDemoMessage(
                          context,
                          'Reference action selected',
                        ),
                        child: const Text('Browse references →'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      if (filter == 'All cards' || filter == 'Nested cards')
        KSection(
          title: 'Cards inside cards',
          description:
              'One parent surface groups related child cards. Different surface tones keep the hierarchy clear.',
          tag: 'Composition',
          child: KPanel(
            color: KTokens.quiet(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Project workspace',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const KBadge('Sample composition'),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('The courtyard residence / Design development'),
                const SizedBox(height: 20),
                KGrid(
                  minWidth: 245,
                  children: [
                    const ProjectCard(compact: true),
                    KPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project documents',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          for (final name in [
                            'Concept plans',
                            'Material palette',
                            'Site photographs',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: KPanel(
                                padding: const EdgeInsets.all(12),
                                color: KTokens.quiet(context),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.description_outlined,
                                      size: 19,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(name)),
                                    const Icon(Icons.chevron_right, size: 16),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
