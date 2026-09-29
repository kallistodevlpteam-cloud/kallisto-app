import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kallisto_design_system/client/pages/intake_page.dart';
import 'package:kallisto_design_system/client/pages/brief_review_page.dart';
import 'package:kallisto_design_system/client/workflow_models.dart';
import 'package:kallisto_design_system/design_system/tokens.dart';
import 'client_test.dart' show FakeGateway;

class WorkflowGateway extends FakeGateway {
  List<Map<String, Object?>>? saved;
  int confirmations = 0;
  IntakeDraft draft = const IntakeDraft(
    id: 'draft',
    revision: 0,
    values: {},
    fieldRevisions: {},
    answerStates: {},
    inputRefs: [],
  );
  @override
  Future<IntakeDraft> intake(String id) async => draft;
  @override
  Future<void> saveIntake(
    IntakeDraft draft,
    List<Map<String, Object?>> operations,
    String key,
  ) async {
    saved = operations;
    this.draft = IntakeDraft(
      id: 'draft',
      revision: 1,
      values: {
        for (final op in operations)
          if (op['op'] == 'set') op['field_path']! as String: op['value'],
      },
      fieldRevisions: const {},
      answerStates: {
        for (final op in operations)
          op['field_path']! as String: op['op'] == 'set'
              ? 'provided'
              : 'explicit_unknown',
      },
      inputRefs: const [],
    );
  }

  @override
  Future<RequirementView> requirements(
    String projectId, {
    String? versionId,
  }) async => RequirementView(
    id: 'requirements',
    versionId: 'brief-v1',
    hash: 'a' * 64,
    number: 1,
    expectedVersion: 1,
    title: 'Courtyard home',
    values: const {
      'brief.project.name': 'Courtyard home',
      'brief.budget.target_minor': 450000000,
    },
    confirmed: confirmations > 0,
    canConfirm: confirmations == 0,
  );
  @override
  Future<void> confirm(
    String projectId,
    RequirementView brief,
    String key,
  ) async {
    expect(projectId, 'project');
    expect(brief.versionId, 'brief-v1');
    expect(brief.hash, 'a' * 64);
    confirmations++;
  }
}

void main() {
  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('manual brief fits $width and saves typed values', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gateway = WorkflowGateway();
      await tester.pumpWidget(
        MaterialApp(
          theme: KTokens.theme(Brightness.light),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ClientIntakePage(gateway: gateway, intakeId: 'draft'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Project name'),
        'Test home',
      );
      final save = find.widgetWithText(OutlinedButton, 'Save draft');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(gateway.saved!.single['value'], 'Test home');
      expect(find.text('Your draft is saved.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'discard reload resets structured entries at the same saved revision',
    (tester) async {
      final gateway = WorkflowGateway();
      await tester.pumpWidget(
        MaterialApp(
          theme: KTokens.theme(Brightness.light),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClientIntakePage(gateway: gateway, intakeId: 'draft'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'The idea'));
      await tester.pumpAndSettle();
      final add = find.widgetWithText(OutlinedButton, 'Add entry');
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Unsaved professional',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Role or scope'),
        'Designer',
      );
      await tester.tap(find.text('Use this entry'));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved professional'), findsOneWidget);
      final reload = find.widgetWithText(TextButton, 'Reload saved draft');
      await tester.ensureVisible(reload);
      await tester.tap(reload);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Reload saved draft'));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved professional'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'brief confirmation stays disabled until this version is reviewed',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final gateway = WorkflowGateway();
      await tester.pumpWidget(
        MaterialApp(
          theme: KTokens.theme(Brightness.light),
          home: Scaffold(
            body: SingleChildScrollView(
              child: BriefReviewPage(gateway: gateway, projectId: 'project'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Confirm this version'),
            )
            .onPressed,
        isNull,
      );
      expect(gateway.confirmations, 0);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Confirm this version'),
      );
      await tester.pumpAndSettle();
      expect(gateway.confirmations, 1);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
