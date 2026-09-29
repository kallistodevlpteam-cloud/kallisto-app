import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kallisto_design_system/client/pages/odin_page.dart';
import 'client_test.dart' show FakeGateway;

class OdinGateway extends FakeGateway {
  int sent = 0;
  @override
  Future<Map<String, dynamic>> odinCapabilities() async => {
    'available': true,
    'notice_version': 'v1',
    'notice_text': 'Test processing notice',
    'daily_call_limit': 16,
    'projects': <Object>[],
  };
  @override
  Future<List<dynamic>> odinRuns() async => [];
  @override
  Future<String> odinConsent(String version, String key) async => 'consent';
  @override
  Future<Map<String, dynamic>> odinSend(
    String text,
    String key,
    String consent, {
    String? conversation,
    String? project,
    bool planning = false,
  }) async {
    sent++;
    return {'run_id': 'run', 'conversation_id': 'thread'};
  }

  @override
  Future<Map<String, dynamic>> odinRun(String id) async => {
    'run_id': 'run',
    'conversation_id': 'thread',
    'row_version': 1,
    'status': 'succeeded',
    'input_text': 'Hello',
    'answer': 'Saved answer',
    'steps': <Object>[],
  };
}

void main() {
  testWidgets(
    'Odin keeps home text, requires processing choice and renders real saved answer on phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gateway = OdinGateway();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OdinPage(gateway: gateway, initialText: 'Hello'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Hello',
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Send to Odin'),
            )
            .onPressed,
        isNull,
      );
      expect(gateway.sent, 0);
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Send to Odin'));
      await tester.tap(find.text('Send to Odin'));
      await tester.pumpAndSettle();
      expect(gateway.sent, 1);
      expect(find.text('Saved answer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
