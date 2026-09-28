import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kallisto_design_system/client/pages/settings_page.dart';
import 'package:kallisto_design_system/client/settings_models.dart';
import 'package:kallisto_design_system/client/client_models.dart';
import 'client_test.dart' show FakeGateway;

class SettingsGateway extends FakeGateway {
  ClientSettings stored = const ClientSettings('privacy', 0, {
    'optional_analytics_consent': false,
    'marketing_consent': false,
  });
  final keys = <String>[];
  bool fail = false;
  @override
  Future<ClientSettings> settings(String section) async => stored;
  @override
  Future<ClientSettings> saveSettings(
    ClientSettings previous,
    Map<String, dynamic> values,
    String key,
  ) async {
    keys.add(key);
    if (fail) {
      throw const ClientFailure(
        ClientConnection.offline,
        'Network unavailable.',
      );
    }
    return stored = ClientSettings(
      previous.section,
      previous.version + 1,
      Map.of(values),
    );
  }
}

void main() {
  testWidgets('preferences save, reload and remain usable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = SettingsGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClientSettingsPage(gateway: gateway, section: 'privacy'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marketing communications'));
    await tester.pump();
    await tester.tap(find.text('Save preferences'));
    await tester.pumpAndSettle();
    expect(gateway.stored.values['marketing_consent'], true);
    await tester.tap(find.text('Discard changes & reload'));
    await tester.pumpAndSettle();
    expect(
      tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).last.value,
      true,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('uncertain save preserves the values and retry identity', (
    tester,
  ) async {
    final gateway = SettingsGateway()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientSettingsPage(gateway: gateway, section: 'privacy'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marketing communications'));
    await tester.pump();
    await tester.tap(find.text('Save preferences'));
    await tester.pumpAndSettle();
    expect(find.text('Network unavailable.'), findsOneWidget);
    gateway.fail = false;
    await tester.tap(find.text('Save preferences'));
    await tester.pumpAndSettle();
    expect(gateway.keys[0], gateway.keys[1]);
    expect(gateway.stored.values['marketing_consent'], true);
  });
}
