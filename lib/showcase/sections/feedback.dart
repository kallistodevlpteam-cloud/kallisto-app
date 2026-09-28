import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';

class FeedbackSection extends StatefulWidget {
  const FeedbackSection({super.key});
  @override
  State<FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<FeedbackSection> {
  String state = 'Empty';
  int retries = 0;
  void showSheet({bool side = false}) {
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  side ? 'Project inspector' : 'Quick actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Close panel',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const KBadge('Sample content', tone: KBadgeTone.info),
          const SizedBox(height: 20),
          const Text(
            'Secondary information stays close to the workspace without replacing its context.',
          ),
          const SizedBox(height: 24),
          const KPanel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.description_outlined),
              title: Text('Concept drawings'),
              subtitle: Text('Version 03 · sample'),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (side) {
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close inspector',
        transitionDuration: KTokens.motion(context, KTokens.drawer),
        pageBuilder: (context, animation, secondaryAnimation) => Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: KTokens.panel(context),
            child: SafeArea(
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width.clamp(0, 380),
                height: double.infinity,
                child: SingleChildScrollView(child: content),
              ),
            ),
          ),
        ),
        transitionBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: KTokens.entrance),
                  ),
              child: child,
            ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
            ? AnimationStyle.noAnimation
            : const AnimationStyle(duration: KTokens.drawer),
        builder: (context) =>
            SafeArea(child: SingleChildScrollView(child: content)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      KSection(
        title: 'Every state has a design',
        description:
            'Loading, empty, error, success, permission denied, and offline are first-class component states.',
        tag: 'State explorer',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in [
                  'Loading',
                  'Empty',
                  'Error',
                  'Success',
                  'Permission denied',
                  'Offline',
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: state == label,
                    onSelected: (_) => setState(() => state = label),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            KPanel(
              child: SizedBox(
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: KTokens.motion(context),
                  child: Padding(
                    key: ValueKey(state),
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: _stateBody(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      KSection(
        title: 'Messages in context',
        description: 'Concise, explicit messages with a clear next step.',
        child: KGrid(
          minWidth: 280,
          children: [
            for (final item in <(String, String, IconData, KBadgeTone)>[
              (
                'Saved successfully',
                'Your sample preference has been updated.',
                Icons.check_circle_outline,
                KBadgeTone.success,
              ),
              (
                'Review required',
                'Check the latest drawing version before continuing.',
                Icons.info_outline,
                KBadgeTone.warning,
              ),
              (
                'Something went wrong',
                'The sample operation could not be completed.',
                Icons.error_outline,
                KBadgeTone.danger,
              ),
            ])
              KPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KBadge(item.$1, tone: item.$4, icon: item.$3),
                    const SizedBox(height: 12),
                    Text(item.$2),
                  ],
                ),
              ),
          ],
        ),
      ),
      KSection(
        title: 'Dialogs, drawers & sheets',
        description:
            'Open each overlay. Escape, the close control, or the backdrop dismisses it and restores context.',
        child: KPanel(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  animationStyle: MediaQuery.disableAnimationsOf(context)
                      ? AnimationStyle.noAnimation
                      : const AnimationStyle(duration: KTokens.standard),
                  builder: (context) => AlertDialog(
                    title: const Text('Share this sample?'),
                    content: const Text(
                      'This dialog demonstrates a confirmation pattern. No file or message will be shared.',
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
                            'Sample confirmation received',
                          );
                        },
                        child: const Text('Confirm sample'),
                      ),
                    ],
                  ),
                ),
                icon: const Icon(Icons.web_asset_outlined, size: 18),
                label: const Text('Open dialog'),
              ),
              OutlinedButton.icon(
                onPressed: () => showSheet(side: true),
                icon: const Icon(Icons.view_sidebar_outlined, size: 18),
                label: const Text('Open drawer'),
              ),
              OutlinedButton.icon(
                onPressed: showSheet,
                icon: const Icon(Icons.vertical_align_bottom, size: 18),
                label: const Text('Open bottom sheet'),
              ),
              OutlinedButton.icon(
                onPressed: () => showDemoMessage(
                  context,
                  'Sample action completed successfully.',
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Show toast'),
              ),
              const Tooltip(
                message:
                    'Tooltips provide short context for unfamiliar controls.',
                child: Chip(
                  avatar: Icon(Icons.info_outline, size: 16),
                  label: Text('Hover for tooltip'),
                ),
              ),
            ],
          ),
        ),
      ),
      const KSection(
        title: 'Expandable content',
        description:
            'An accordion progressively reveals supporting information.',
        child: KPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ExpansionTile(
                title: Text('What belongs in a project card?'),
                childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  Text(
                    'A recognizable title, relevant image, current status, and the metadata needed to choose the next action.',
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('How are document versions displayed?'),
                childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                children: [
                  Text(
                    'The version is explicit. Approval of one submitted version does not imply approval of later revisions.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _stateBody(BuildContext context) {
    if (state == 'Loading') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              semanticsLabel: 'Loading sample content',
            ),
          ),
          const SizedBox(height: 20),
          const Text('Loading project details…'),
          const SizedBox(height: 24),
          for (final width in [240.0, 180.0, 210.0])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: width,
                height: 12,
                decoration: BoxDecoration(
                  color: KTokens.quiet(context),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      );
    }
    final (icon, title, description) = switch (state) {
      'Error' => (
        Icons.cloud_off_outlined,
        'Unable to load projects',
        'Check your connection and try again.',
      ),
      'Success' => (
        Icons.check_circle_outline,
        'You’re all set',
        'The sample action completed successfully.',
      ),
      'Permission denied' => (
        Icons.lock_outline,
        'Access is restricted',
        'An authorized project role is required to view this content.',
      ),
      'Offline' => (
        Icons.wifi_off,
        'You’re currently offline',
        'Reconnect before making changes to project records.',
      ),
      _ => (
        Icons.folder_open_outlined,
        'A clear space for your work',
        'Projects will appear here when they are available.',
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: KTokens.quiet(context),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(description, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          if (state == 'Error' || state == 'Offline')
            OutlinedButton.icon(
              onPressed: () => setState(() {
                retries++;
                state = 'Success';
              }),
              icon: const Icon(Icons.refresh, size: 17),
              label: const Text('Retry sample'),
            )
          else if (state == 'Empty')
            OutlinedButton(
              onPressed: () => setState(() => state = 'Success'),
              child: const Text('Try an example'),
            ),
          if (retries > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '$retries sample retries',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
