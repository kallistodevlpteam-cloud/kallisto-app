import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kallisto_design_system/client/widgets/share_brief_panel.dart';
import 'package:kallisto_design_system/client/provider_models.dart';
import 'package:kallisto_design_system/client/sharing_models.dart';
import 'package:kallisto_design_system/client/workflow_models.dart';
import 'client_test.dart' show FakeGateway, sample;

class ShareGateway extends FakeGateway {
  int sends = 0;
  @override
  Future<RequirementView> requirements(
    String projectId, {
    String? versionId,
  }) async => const RequirementView(
    id: 'r',
    versionId: 'v',
    hash: 'hash',
    number: 1,
    expectedVersion: 1,
    title: 'Courtyard home',
    values: {},
    confirmed: true,
  );
  @override
  Future<BriefDisclosure> previewShare(
    String projectId,
    String recipient,
    RequirementView brief,
  ) async => const BriefDisclosure(
    'p1',
    'sp',
    'v',
    'hash',
    'manifest',
    2,
    {'id': 'policy', 'version': '1'},
    {'detail_field_paths': <String>[], 'attachment_refs': <Object>[]},
    {
      'title': 'Courtyard home',
      'scope_summary': 'Selected confirmed details',
      'permitted_details': {'brief.project.name': 'Courtyard home'},
    },
  );
  @override
  Future<String> shareBrief(BriefDisclosure preview, String key) async {
    sends++;
    return 'enquiry';
  }
}

void main() {
  testWidgets('preview requires exact explicit confirmation before send', (
    tester,
  ) async {
    final gateway = ShareGateway()..result = sample;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ShareBriefPanel(
              gateway: gateway,
              provider: const LeadProvider(
                'profile',
                'Practice',
                'Summary',
                [],
                [],
                [],
                'sp',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Courtyard home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview exact disclosure'));
    await tester.pumpAndSettle();
    expect(gateway.sends, 0);
    final send = find.widgetWithText(
      FilledButton,
      'Share this brief with provider',
    );
    expect(tester.widget<FilledButton>(send).onPressed, isNull);
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(gateway.sends, 1);
    expect(find.text('Open enquiry'), findsOneWidget);
  });
}
