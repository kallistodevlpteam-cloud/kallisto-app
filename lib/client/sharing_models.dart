import 'workflow_models.dart';

class ClientEnquiry {
  const ClientEnquiry(
    this.id,
    this.projectId,
    this.status,
    this.title,
    this.details, {
    this.conversationId,
  });
  final String id, projectId, status, title;
  final Map<String, dynamic> details;
  final String? conversationId;
  factory ClientEnquiry.fromJson(Object? value) {
    final row = objectValue(value),
        snapshot = objectValue(row['disclosure_snapshot']);
    return ClientEnquiry(
      stringValue(row, 'enquiry_id'),
      stringValue(row, 'project_id'),
      stringValue(row, 'status'),
      stringValue(snapshot, 'title'),
      objectValue(snapshot['permitted_details']),
      conversationId: row['conversation_id'] as String?,
    );
  }
}

class EnquiryPage {
  const EnquiryPage(this.items, this.cursor);
  final List<ClientEnquiry> items;
  final String? cursor;
  factory EnquiryPage.fromJson(Object? value) {
    final row = objectValue(value);
    return EnquiryPage(
      (row['items'] as List).map(ClientEnquiry.fromJson).toList(),
      row['next_cursor'] as String?,
    );
  }
}

class BriefDisclosure {
  const BriefDisclosure(
    this.projectId,
    this.recipient,
    this.versionId,
    this.briefHash,
    this.manifestHash,
    this.projectVersion,
    this.policy,
    this.selection,
    this.content,
  );
  final String projectId, recipient, versionId, briefHash, manifestHash;
  final int projectVersion;
  final Map<String, dynamic> policy, selection, content;
  factory BriefDisclosure.fromJson(String project, Object? value) {
    final row = objectValue(value);
    return BriefDisclosure(
      project,
      stringValue(row, 'provider_uid'),
      stringValue(row, 'requirement_version_id'),
      stringValue(row, 'requirement_content_hash'),
      stringValue(row, 'disclosure_manifest_hash'),
      integerValue(row, 'expected_project_version'),
      objectValue(row['policy_ref']),
      objectValue(row['disclosure_selection']),
      objectValue(row['disclosed_content']),
    );
  }
}
