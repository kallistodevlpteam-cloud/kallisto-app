import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';
import '../client_controller.dart';
import '../client_models.dart';
import '../widgets/connection_panel.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key, required this.controller});
  final ClientController controller;
  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final _draft = TextEditingController();
  String _mode = 'Type';
  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final name = controller.snapshot?.name;
    final ready = controller.connection == ClientConnection.ready;
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KBadge(
          'YOUR PROJECT, FROM THE FIRST IDEA',
          tone: KBadgeTone.info,
        ),
        const SizedBox(height: 22),
        Text(
          name != null && name.isNotEmpty
              ? 'Welcome, $name.'
              : 'Make room for\nwhat comes next.',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontSize: 38, height: 1.13),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Text(
            'A home, a renovation, a place to build your business. Start with your idea and keep every next step together.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.6, color: KTokens.muted),
          ),
        ),
        const SizedBox(height: 28),
        KPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: KTokens.accentSoft,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_outlined,
                      color: KTokens.accent,
                      size: 19,
                    ),
                  ),
                  const Text(
                    'Ask Odin',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const KBadge('Project assistant'),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                children: [
                  for (final mode in ['Type', 'Speak', 'Manual'])
                    ChoiceChip(
                      label: Text(mode),
                      selected: _mode == mode,
                      onSelected: (_) => setState(() => _mode = mode),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_mode == 'Type')
                TextField(
                  controller: _draft,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 4000,
                  decoration: const InputDecoration(
                    labelText: 'What are you planning?',
                    alignLabelWithHint: true,
                    hintText:
                        'Tell Odin about your space, location and what matters to you.',
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _mode == 'Speak'
                            ? Icons.mic_none_outlined
                            : Icons.edit_note_outlined,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _mode == 'Speak'
                              ? 'Voice is not available yet. You will be able to review the transcript before using it in your brief.'
                              : 'Manual project intake is not available yet. Your existing project information remains in Projects.',
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: ready
                        ? null
                        : () => Navigator.pushNamed(context, '/client/account'),
                    icon: Icon(
                      ready ? Icons.arrow_upward : Icons.login,
                      size: 17,
                    ),
                    label: Text(
                      ready ? 'Odin is unavailable' : 'Sign in to continue',
                    ),
                  ),
                  Text(
                    ready
                        ? 'Text stays here until sending is available.'
                        : 'Your message has not been sent.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ConnectionPanel(controller: controller),
      ],
    );
    final guide = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A clearer way forward',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'From the first conversation to your final handover.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 22),
        for (final step in [
          (
            '01',
            'Shape your brief',
            'Keep your ideas, needs and questions together.',
          ),
          (
            '02',
            'Choose your professional',
            'Review scope and proposals before you decide.',
          ),
          (
            '03',
            'Follow the work',
            'See the design, site updates and decisions in one place.',
          ),
        ]) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.$1,
                style: const TextStyle(
                  color: KTokens.soft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.$2,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(step.$3, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),
        ],
        const Divider(),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 19,
              color: KTokens.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'You review the brief and choose what to share. Decisions remain yours.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 1000
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: main),
                const SizedBox(width: 44),
                SizedBox(
                  width: 255,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: guide,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [main, const SizedBox(height: 36), guide],
            ),
    );
  }
}
