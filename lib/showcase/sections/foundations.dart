import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';

class FoundationsSection extends StatelessWidget {
  const FoundationsSection({
    super.key,
    required this.onBrowseCards,
    required this.onBrowseMotion,
  });
  final VoidCallback onBrowseCards;
  final VoidCallback onBrowseMotion;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      KPanel(
        padding: EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, box) {
            final copy = Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KBadge(
                    'A shared visual language',
                    tone: KBadgeTone.info,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Precise by design.\nCalm in every detail.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Explore the foundations and building blocks of the Kallisto workspace — translated into native Flutter widgets.',
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: onBrowseCards,
                        icon: const Icon(Icons.arrow_outward, size: 16),
                        label: const Text('Explore components'),
                      ),
                      OutlinedButton(
                        onPressed: onBrowseMotion,
                        child: const Text('Play with motion'),
                      ),
                    ],
                  ),
                ],
              ),
            );
            final photo = ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: const KImage(
                'residence.jpg',
                height: 310,
                label: 'Modern residence from the Kallisto project assets',
              ),
            );
            return box.maxWidth > 720
                ? Row(
                    children: [
                      Expanded(flex: 6, child: copy),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: photo,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      copy,
                      Padding(padding: const EdgeInsets.all(8), child: photo),
                    ],
                  );
          },
        ),
      ),
      const SizedBox(height: 32),
      KSection(
        title: 'Color, with purpose',
        description:
            'Neutral foundations. One clear accent. Semantic colors communicate status alongside text.',
        tag: '01 · Color',
        child: KGrid(
          minWidth: 140,
          children: [
            for (final item in <(String, Color, String)>[
              ('Ink', KTokens.ink, 'Primary text'),
              ('Canvas', KTokens.page, 'Page background'),
              ('Surface', KTokens.surface, 'Cards & panels'),
              ('Subtle', KTokens.subtle, 'Hover & sections'),
              ('Accent', KTokens.accent, 'Primary actions'),
              ('Success', KTokens.success, 'Positive feedback'),
              ('Warning', KTokens.warning, 'Needs attention'),
              ('Danger', KTokens.danger, 'Errors & destructive'),
            ])
              KPanel(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: item.$2,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: KTokens.line),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.$1,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '#${item.$2.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(item.$3, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
          ],
        ),
      ),
      KSection(
        title: 'Hanken Grotesk',
        description:
            'The same typeface as the web app, bundled locally. Strong headings, readable details.',
        tag: '02 · Typography',
        child: KPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in <(String, double, FontWeight)>[
                ('Display / 32 / Bold', 32, FontWeight.w700),
                ('Heading / 24 / Bold', 24, FontWeight.w700),
                ('Section / 20 / Bold', 20, FontWeight.w700),
                ('Title / 15 / Semibold', 15, FontWeight.w600),
                ('Body / 13.5 / Regular', 13.5, FontWeight.w400),
                ('Caption / 12 / Regular', 12, FontWeight.w400),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: LayoutBuilder(
                    builder: (context, box) => box.maxWidth > 600
                        ? Row(
                            children: [
                              SizedBox(
                                width: 190,
                                child: Text(
                                  item.$1,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'A workspace for better work.',
                                  style: TextStyle(
                                    fontSize: item.$2,
                                    fontWeight: item.$3,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$1,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'A workspace for better work.',
                                style: TextStyle(
                                  fontSize: item.$2,
                                  fontWeight: item.$3,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
      KSection(
        title: 'Space & shape',
        description:
            'A consistent spacing scale and a small family of corner radii keep everything related.',
        tag: '03 · Geometry',
        child: KGrid(
          minWidth: 300,
          children: [
            KPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spacing scale',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  for (final space in KTokens.spacing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text('${space.toInt()} px'),
                          ),
                          Container(
                            width: space * 3,
                            height: 12,
                            decoration: BoxDecoration(
                              color: KTokens.accent.withValues(alpha: .2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            KPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Corner radii',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      for (final radius in [8.0, 12.0, 16.0])
                        Column(
                          children: [
                            Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                color: KTokens.quiet(context),
                                border: Border.all(
                                  color: KTokens.border(context),
                                ),
                                borderRadius: BorderRadius.circular(radius),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text('${radius.toInt()} px'),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '8 · Controls and media\n12 · Cards and grouped content\n16 · Dialogs and large panels',
                  ),
                  const SizedBox(height: 16),
                  const KBadge(
                    '44–48 px accessible touch targets',
                    icon: Icons.touch_app_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      KSection(
        title: 'Icons & identity',
        description:
            'A Flutter Material outline icon mapping for the web app’s Lucide icon language.',
        tag: '04 · Iconography',
        child: KPanel(
          child: Wrap(
            spacing: 24,
            runSpacing: 20,
            children: [
              for (final item in <(String, IconData)>[
                ('Projects', Icons.folder_outlined),
                ('Enquiries', Icons.inbox_outlined),
                ('Documents', Icons.description_outlined),
                ('Calendar', Icons.calendar_today_outlined),
                ('People', Icons.people_outline),
                ('Verified', Icons.verified_outlined),
                ('Settings', Icons.settings_outlined),
                ('Search', Icons.search),
                ('Odin', Icons.auto_awesome_outlined),
              ])
                SizedBox(
                  width: 70,
                  child: Column(
                    children: [
                      Icon(item.$2, size: 24),
                      const SizedBox(height: 10),
                      Text(
                        item.$1,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}
