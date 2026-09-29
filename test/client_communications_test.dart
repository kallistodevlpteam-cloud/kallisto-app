import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kallisto_design_system/client/client_models.dart';
import 'package:kallisto_design_system/client/message_models.dart';
import 'package:kallisto_design_system/client/pages/messages_page.dart';
import 'package:kallisto_design_system/client/pages/support_page.dart';
import 'client_test.dart' show FakeGateway;

class CommunicationsGateway extends FakeGateway {
  bool fail = false;
  final keys = <String>[];
  final sent = <ThreadMessage>[];
  @override
  Future<ClientThread> conversation(String id) async =>
      ClientThread(id, 'Account help', 'support', 'open');
  @override
  Future<ClientPage<ThreadMessage>> messages(
    String id, {
    String? cursor,
  }) async => ClientPage(List.of(sent), null);
  @override
  Future<void> sendMessage(String id, String text, String key) async {
    keys.add(key);
    if (fail) {
      throw const ClientFailure(
        ClientConnection.offline,
        'Delivery uncertain. Retry.',
      );
    }
    sent.add(ThreadMessage('message', text, 'Account holder', 1, null));
  }

  @override
  Future<ClientPage<SupportCase>> supportCases({String? cursor}) async =>
      const ClientPage([], null);
  @override
  Future<String> createSupportCase(
    String category,
    String subject,
    String description,
    String key,
  ) async {
    keys.add(key);
    return 'case';
  }
}

void main() {
  testWidgets(
    'uncertain message keeps draft and reuses identity without claiming sent',
    (tester) async {
      final gateway = CommunicationsGateway()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientMessagesPage(
                gateway: gateway,
                conversationId: 'thread',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Please help with enrollment.',
      );
      await tester.ensureVisible(find.text('Send message'));
      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();
      expect(find.text('Delivery uncertain. Retry.'), findsOneWidget);
      expect(gateway.sent, isEmpty);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Please help with enrollment.',
      );
      gateway.fail = false;
      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();
      expect(gateway.keys[0], gateway.keys[1]);
      expect(find.text('Message saved.'), findsOneWidget);
      expect(gateway.sent, hasLength(1));
      await tester.enterText(
        find.byType(TextField),
        'Please help with enrollment.',
      );
      await tester.ensureVisible(find.text('Send message'));
      await tester.tap(find.text('Send message'));
      await tester.pumpAndSettle();
      expect(gateway.keys[2], isNot(gateway.keys[1]));
      expect(gateway.sent, hasLength(2));
    },
  );
  testWidgets('support form fits a phone and validates required information', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = CommunicationsGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClientSupportPage(gateway: gateway),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create support case'));
    await tester.tap(find.text('Create support case'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a subject.'), findsOneWidget);
    expect(find.text('Describe the problem.'), findsOneWidget);
    expect(gateway.keys, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
