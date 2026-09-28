import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';

class ButtonsSection extends StatefulWidget {
  const ButtonsSection({super.key});
  @override
  State<ButtonsSection> createState() => _ButtonsSectionState();
}

class _ButtonsSectionState extends State<ButtonsSection> {
  bool loading = false;
  bool saved = false;
  bool favourite = false;
  int view = 0;
  Future<void> simulateSave() async {
    if (loading) return;
    setState(() => loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      loading = false;
      saved = true;
    });
    showDemoMessage(
      context,
      'Sample saved. This only changes the showcase state.',
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      KSection(
        title: 'One action, the right emphasis',
        description:
            'Primary, neutral, outline, ghost, and destructive variants. Hover, focus, and press to compare.',
        child: KPanel(
          child: Wrap(
            spacing: 14,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    showDemoMessage(context, 'Primary action selected'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New project'),
              ),
              FilledButton(
                onPressed: () =>
                    showDemoMessage(context, 'Neutral action selected'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onSurface,
                  foregroundColor: KTokens.panel(context),
                ),
                child: const Text('Continue'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    showDemoMessage(context, 'Preview opened in this demo'),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Preview'),
              ),
              TextButton(
                onPressed: () =>
                    showDemoMessage(context, 'Text action selected'),
                child: const Text('View details →'),
              ),
              FilledButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Remove sample item?'),
                    content: const Text(
                      'This is a confirmation pattern. No project or record will be deleted.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          showDemoMessage(
                            this.context,
                            'Sample removal confirmed',
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: KTokens.danger,
                        ),
                        child: const Text('Remove sample'),
                      ),
                    ],
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: KTokens.danger,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
        ),
      ),
      KSection(
        title: 'Interaction states',
        description:
            'A loading action rejects repeat clicks, then resolves to a clear success state.',
        tag: 'Try it',
        child: KGrid(
          minWidth: 250,
          children: [
            KSpecimen(
              name: 'Async action',
              detail: 'Idle → loading → saved · 900 ms demo',
              child: KPanel(
                child: Center(
                  child: FilledButton.icon(
                    key: const ValueKey('save-demo'),
                    onPressed: loading ? null : simulateSave,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            saved ? Icons.check : Icons.save_outlined,
                            size: 18,
                          ),
                    label: Text(
                      loading
                          ? 'Saving…'
                          : saved
                          ? 'Saved · try again'
                          : 'Save changes',
                    ),
                  ),
                ),
              ),
            ),
            const KSpecimen(
              name: 'Disabled',
              detail: 'Unavailable actions remain visibly inactive.',
              child: KPanel(
                child: Center(
                  child: FilledButton(
                    onPressed: null,
                    child: Text('Submit proposal'),
                  ),
                ),
              ),
            ),
            KSpecimen(
              name: 'Toggle action',
              detail: 'Selected state announced to assistive tech.',
              child: KPanel(
                child: Center(
                  child: Semantics(
                    toggled: favourite,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => favourite = !favourite),
                      icon: Icon(
                        favourite ? Icons.bookmark : Icons.bookmark_outline,
                        size: 18,
                      ),
                      label: Text(
                        favourite
                            ? 'Saved to collection'
                            : 'Save to collection',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      KSection(
        title: 'Sizes & icon actions',
        description:
            'Compact visual density with at least 44 px interactive targets.',
        child: KPanel(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final item in <(String, double)>[
                ('Small', 44),
                ('Medium', 48),
                ('Large', 56),
              ])
                OutlinedButton(
                  onPressed: () =>
                      showDemoMessage(context, '${item.$1} button pressed'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(90, item.$2),
                  ),
                  child: Text(item.$1),
                ),
              IconButton.filled(
                tooltip: 'Add item',
                onPressed: () => showDemoMessage(context, 'Add action'),
                icon: const Icon(Icons.add),
              ),
              IconButton.outlined(
                tooltip: 'Download sample',
                onPressed: () => showDemoMessage(
                  context,
                  'Download button specimen; no document requested.',
                ),
                icon: const Icon(Icons.download_outlined),
              ),
              PopupMenuButton<String>(
                tooltip: 'More actions',
                onSelected: (value) =>
                    showDemoMessage(context, '$value selected'),
                itemBuilder: (context) => [
                  for (final title in ['Duplicate', 'Rename', 'Archive'])
                    PopupMenuItem(value: title, child: Text(title)),
                ],
              ),
            ],
          ),
        ),
      ),
      KSection(
        title: 'Segmented controls',
        description:
            'A compact group of related choices with one active selection.',
        child: KPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.grid_view, size: 18),
                    label: Text('Grid'),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.view_list_outlined, size: 18),
                    label: Text('List'),
                  ),
                ],
                selected: {view},
                onSelectionChanged: (values) =>
                    setState(() => view = values.first),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: KTokens.motion(context),
                child: view == 0
                    ? Row(
                        key: const ValueKey('grid'),
                        children: [
                          for (var i = 0; i < 3; i++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Container(
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: KTokens.quiet(context),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.crop_landscape,
                                    color: KTokens.soft,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('list'),
                        children: [
                          for (var i = 0; i < 3; i++)
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.folder_outlined),
                              title: Text('Sample project ${i + 1}'),
                              trailing: const Icon(Icons.chevron_right),
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
