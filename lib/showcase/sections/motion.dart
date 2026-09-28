import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';

class MotionSection extends StatefulWidget {
  const MotionSection({super.key});
  @override
  State<MotionSection> createState() => _MotionSectionState();
}

class _MotionSectionState extends State<MotionSection> {
  bool toggled = false;
  double duration = 350;
  String curveName = 'Kallisto entrance';
  final curves = <String, Curve>{
    'Kallisto entrance': KTokens.entrance,
    'Ease in out': Curves.easeInOut,
    'Linear': Curves.linear,
    'Spring': Curves.easeOutBack,
  };
  int replay = 0;
  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final speed = KTokens.motion(
      context,
      Duration(milliseconds: duration.round()),
    );
    final curve = curves[curveName]!;
    // Opacity must remain between zero and one; spring overshoot is spatial only.
    final opacityCurve = curveName == 'Spring' ? Curves.easeOut : curve;
    final details = toggled
        ? const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Keep motion purposeful. Respect system reduced-motion preferences. Prefer short transitions that explain a relationship, a state change, or the result of an action.',
            ),
          )
        : const SizedBox(width: double.infinity);
    return Column(
      children: [
        KSection(
          title: 'Motion tokens',
          description:
              'Timing is derived from the existing CSS. Animation communicates a change without delaying the task.',
          child: KGrid(
            minWidth: 200,
            children: [
              for (final item in <(String, String, String)>[
                (
                  '150 ms',
                  'Micro interaction',
                  'Hover, focus, button feedback',
                ),
                ('200 ms', 'Standard', 'Layout and state changes'),
                ('220 ms', 'Drawer', 'Context panels and overlays'),
                ('350 ms', 'Expressive', 'Image hover and entrance'),
              ])
                KPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.$2,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$3,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        KSection(
          title: 'The motion playground',
          description:
              'Change duration and easing, then play. Use the top-right preferences menu to enable reduced motion.',
          tag: reduce ? 'Reduced motion is on' : 'Live controls',
          child: KPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('play-motion'),
                      onPressed: () => setState(() {
                        toggled = !toggled;
                        replay++;
                      }),
                      icon: const Icon(Icons.play_arrow, size: 19),
                      label: const Text('Play animation'),
                    ),
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: curveName,
                        decoration: const InputDecoration(
                          labelText: 'Easing curve',
                        ),
                        items: [
                          for (final name in curves.keys)
                            DropdownMenuItem(value: name, child: Text(name)),
                        ],
                        onChanged: (name) => setState(() => curveName = name!),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Duration · ${duration.round()} ms'),
                          Slider(
                            value: duration,
                            min: 100,
                            max: 1200,
                            divisions: 22,
                            label: '${duration.round()} ms',
                            onChanged: (value) =>
                                setState(() => duration = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                KGrid(
                  minWidth: 250,
                  children: [
                    _motionTile(
                      context,
                      'Fade',
                      'Opacity · 25% ↔ 100%',
                      AnimatedOpacity(
                        key: const ValueKey('fade-specimen'),
                        opacity: toggled ? .25 : 1,
                        duration: speed,
                        curve: opacityCurve,
                        child: _sample(context, Icons.blur_on),
                      ),
                    ),
                    _motionTile(
                      context,
                      'Slide',
                      'Position · left ↔ right',
                      AnimatedAlign(
                        alignment: toggled
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        duration: speed,
                        curve: curve,
                        child: _sample(context, Icons.swipe_right_alt),
                      ),
                    ),
                    _motionTile(
                      context,
                      'Scale',
                      'Size · 80% ↔ 100%',
                      AnimatedScale(
                        scale: toggled ? .8 : 1,
                        duration: speed,
                        curve: curve,
                        child: _sample(context, Icons.open_in_full),
                      ),
                    ),
                    _motionTile(
                      context,
                      'Rotation',
                      'Rotation · 0° ↔ 90°',
                      AnimatedRotation(
                        turns: toggled ? .25 : 0,
                        duration: speed,
                        curve: curve,
                        child: _sample(context, Icons.add),
                      ),
                    ),
                    _motionTile(
                      context,
                      'Container morph',
                      'Radius, width, and color',
                      AnimatedContainer(
                        duration: speed,
                        curve: curve,
                        width: toggled ? 140 : 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: toggled ? KTokens.success : KTokens.accent,
                          borderRadius: BorderRadius.circular(toggled ? 32 : 8),
                        ),
                        child: const Icon(Icons.check, color: Colors.white),
                      ),
                    ),
                    _motionTile(
                      context,
                      'Content switch',
                      'Fade between keyed children',
                      AnimatedSwitcher(
                        duration: speed,
                        switchInCurve: opacityCurve,
                        child: _sample(
                          context,
                          toggled ? Icons.check : Icons.more_horiz,
                          key: ValueKey(toggled),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    reduce
                        ? 'Animations resolve immediately. No nonessential movement.'
                        : 'Played $replay times · ${toggled ? 'End' : 'Start'} state',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        KSection(
          title: 'Real interaction patterns',
          description:
              'Hover or focus the card. Expand the details. Open a page to see a fade-and-slide route transition.',
          child: KGrid(
            minWidth: 280,
            children: [
              KInteractiveCard(
                label: 'Interactive hover and press sample',
                onTap: () => showDemoMessage(
                  context,
                  'Card pressed · release returns to its resting scale',
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.touch_app_outlined, size: 28),
                      const SizedBox(height: 20),
                      Text(
                        'Hover. Focus. Press.',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A quiet border, soft elevation, and a subtle press scale. Keyboard activation works too.',
                      ),
                    ],
                  ),
                ),
              ),
              KPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Page transition',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Keep continuity when moving between related screens.',
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push<void>(
                        PageRouteBuilder<void>(
                          transitionDuration: speed,
                          reverseTransitionDuration: speed,
                          pageBuilder:
                              (
                                context,
                                animation,
                                secondaryAnimation,
                              ) => Scaffold(
                                appBar: AppBar(
                                  title: const Text('Transition preview'),
                                ),
                                body: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 460,
                                      ),
                                      child: KPanel(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_outline,
                                              size: 40,
                                              color: KTokens.success,
                                            ),
                                            const SizedBox(height: 20),
                                            Text(
                                              'A continuous experience.',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.headlineMedium,
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'The next screen enters with a short fade and slide.',
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 24),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text(
                                                'Back to motion',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position:
                                          Tween<Offset>(
                                            begin: const Offset(.06, 0),
                                            end: Offset.zero,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: animation,
                                              curve: curve,
                                            ),
                                          ),
                                      child: child,
                                    ),
                                  ),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Open transition'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        KSection(
          title: 'Expand & collapse',
          description:
              'Animated size lets nearby content move naturally as details appear.',
          child: KPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => toggled = !toggled),
                  icon: AnimatedRotation(
                    turns: toggled ? .5 : 0,
                    duration: speed,
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                  label: Text(toggled ? 'Hide details' : 'Show details'),
                ),
                if (reduce)
                  details
                else
                  AnimatedSize(
                    duration: speed,
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: details,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sample(BuildContext context, IconData icon, {Key? key}) => Container(
    key: key,
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 28),
  );
  Widget _motionTile(
    BuildContext context,
    String name,
    String detail,
    Widget child,
  ) => KPanel(
    padding: const EdgeInsets.all(16),
    color: KTokens.quiet(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 105,
          width: double.infinity,
          child: Center(child: child),
        ),
        const SizedBox(height: 12),
        Text(name, style: Theme.of(context).textTheme.titleMedium),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}
