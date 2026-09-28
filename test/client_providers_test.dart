import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kallisto_design_system/client/pages/providers_page.dart';
import 'package:kallisto_design_system/client/provider_models.dart';
import 'client_test.dart' show FakeGateway;

class DirectoryGateway extends FakeGateway {
  @override
  Future<ProviderPage> providers({
    String? category,
    String? coverage,
    String? cursor,
  }) async => const ProviderPage([], null);
}

void main() {
  testWidgets('empty real-data directory fits a phone without invented cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ClientProvidersPage(gateway: DirectoryGateway()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No eligible providers found for these filters.'),
      findsOneWidget,
    );
    expect(find.text('View profile'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
