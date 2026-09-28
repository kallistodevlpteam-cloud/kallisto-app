import 'package:flutter/material.dart';
import 'design_system/tokens.dart';
import 'showcase/showcase_shell.dart';
import 'client/client_app.dart';

void main() => runApp(const KallistoClientApp());

class KallistoShowcase extends StatefulWidget {
  const KallistoShowcase({super.key});
  @override
  State<KallistoShowcase> createState() => _KallistoShowcaseState();
}

class _KallistoShowcaseState extends State<KallistoShowcase> {
  bool dark = false;
  bool reduceMotion = false;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kallisto · Design system',
    debugShowCheckedModeBanner: false,
    theme: KTokens.theme(Brightness.light),
    darkTheme: KTokens.theme(Brightness.dark),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    themeAnimationDuration: reduceMotion ? Duration.zero : KTokens.standard,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations:
            reduceMotion || MediaQuery.disableAnimationsOf(context),
      ),
      child: child!,
    ),
    home: ShowcaseShell(
      dark: dark,
      reduceMotion: reduceMotion,
      onThemeChanged: () => setState(() => dark = !dark),
      onMotionChanged: (value) => setState(() => reduceMotion = value),
    ),
  );
}
