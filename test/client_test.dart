import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kallisto_design_system/client/client_app.dart';
import 'package:kallisto_design_system/client/client_controller.dart';
import 'package:kallisto_design_system/client/client_gateway.dart';
import 'package:kallisto_design_system/client/client_models.dart';

const sample = ClientSnapshot(
  uid: 'client-a',
  name: 'Asha',
  nextCursor: null,
  projects: [
    ClientProject(
      id: 'p1',
      name: 'Courtyard home',
      type: 'architecture',
      status: 'draft',
      phase: 'requirements',
    ),
  ],
);

class FakeGateway extends ClientGateway {
  ClientSnapshot? result;
  ClientFailure? failure;
  int signIns = 0;
  Future<ClientSnapshot?> Function()? loader;
  final changes = StreamController<void>.broadcast();
  @override
  Stream<void> get sessionChanges => changes.stream;
  @override
  Future<void> initialize() async {}
  @override
  Future<ClientSnapshot?> load({String? cursor}) async {
    if (loader != null) return loader!();
    if (failure != null) throw failure!;
    return result;
  }

  @override
  Future<void> signIn(String email, String password) async {
    signIns++;
    result = sample;
  }

  @override
  Future<void> recover(String email) async {}
  @override
  Future<void> signOut() async {
    result = null;
  }

  @override
  void dispose() {
    changes.close();
  }
}

Future<void> app(
  WidgetTester tester,
  FakeGateway gateway,
  Size size, {
  String? route,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    KallistoClientApp(gateway: gateway, initialRoute: route),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [
    const Size(320, 720),
    const Size(768, 1024),
    const Size(1440, 1000),
  ]) {
    testWidgets('home and navigation fit ${size.width} without overflow', (
      tester,
    ) async {
      await app(tester, FakeGateway(), size);
      expect(find.text('Ask Odin'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final projects = size.width == 768
          ? find.byTooltip('Projects')
          : find.text('Projects');
      await tester.tap(projects.first);
      await tester.pumpAndSettle();
      expect(find.text('Your projects'), findsOneWidget);
      expect(find.text('Your workspace, kept private'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('sign-in validates before calling Firebase gateway', (
    tester,
  ) async {
    final gateway = FakeGateway();
    await app(tester, gateway, const Size(390, 844), route: '/client/account');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(gateway.signIns, 0);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'asha@example.test',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'test-password');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Asha'), findsOneWidget);
    expect(gateway.signIns, 1);
    expect(find.text('test-password'), findsNothing);
  });
  testWidgets('shows authoritative projects and clears them on sign-out', (
    tester,
  ) async {
    final gateway = FakeGateway()..result = sample;
    await app(
      tester,
      gateway,
      const Size(1440, 1000),
      route: '/client/projects',
    );
    expect(find.text('Courtyard home'), findsOneWidget);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();
    expect(find.text('Courtyard home'), findsNothing);
    expect(find.text('Your workspace, kept private'), findsOneWidget);
  });
  testWidgets(
    'permission denied is distinct from no projects and retry recovers',
    (tester) async {
      final gateway = FakeGateway()
        ..failure = const ClientFailure(
          ClientConnection.denied,
          'Access denied.',
        );
      await app(
        tester,
        gateway,
        const Size(390, 844),
        route: '/client/projects',
      );
      expect(find.text('Client access required'), findsOneWidget);
      expect(find.text('No projects to show yet'), findsNothing);
      gateway.failure = null;
      gateway.result = sample;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Courtyard home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'late project request cannot restore private data after sign-out',
    () async {
      final response = Completer<ClientSnapshot?>();
      final gateway = FakeGateway()..loader = () => response.future;
      final controller = ClientController(gateway);
      final pending = controller.refresh();
      await controller.signOut();
      response.complete(sample);
      await pending;
      expect(controller.snapshot, isNull);
      expect(controller.connection, ClientConnection.signedOut);
      controller.dispose();
    },
  );
  test(
    'network failure clears previous private data and supports retry',
    () async {
      final gateway = FakeGateway()..result = sample;
      final controller = ClientController(gateway);
      await controller.initialize();
      gateway.failure = const ClientFailure(
        ClientConnection.offline,
        'Offline',
      );
      await controller.refresh();
      expect(controller.snapshot, isNull);
      expect(controller.connection, ClientConnection.offline);
      gateway.failure = null;
      await controller.refresh();
      expect(controller.snapshot?.uid, 'client-a');
      controller.dispose();
    },
  );
}
