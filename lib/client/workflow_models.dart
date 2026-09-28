import 'client_models.dart';

class ProjectDetail {
  const ProjectDetail(
    this.project,
    this.currentVersion,
    this.confirmedVersion,
    this.intakeId,
    this.policyUnavailable,
  );
  final ClientProject project;
  final String currentVersion;
  final String? confirmedVersion, intakeId;
  final bool policyUnavailable;
  factory ProjectDetail.fromJson(Object? value) {
    final data = objectValue(value);
    return ProjectDetail(
      ClientProject.fromJson(data),
      stringValue(data, 'current_requirement_version_id'),
      data['confirmed_requirement_version_id'] as String?,
      data['active_intake_session_id'] as String?,
      data['lifecycle_gate'] == 'POLICY_UNAVAILABLE',
    );
  }
}

Map<String, dynamic> objectValue(Object? value) {
  if (value is! Map<String, dynamic>) throw const FormatException();
  return value;
}

String stringValue(Map<String, dynamic> value, String key) {
  final result = value[key];
  if (result is! String || result.isEmpty) throw const FormatException();
  return result;
}

int integerValue(Map<String, dynamic> value, String key) {
  final result = value[key];
  if (result is! int || result < 0) throw const FormatException();
  return result;
}

class EnrollmentNotice {
  const EnrollmentNotice(this.version, this.text);
  final String version, text;
  factory EnrollmentNotice.fromJson(Object? value) {
    final data = objectValue(value);
    return EnrollmentNotice(
      stringValue(data, 'version'),
      stringValue(data, 'text'),
    );
  }
}

class IntakeSummary {
  const IntakeSummary({
    required this.id,
    required this.status,
    required this.revision,
    this.projectId,
  });
  final String id, status;
  final int revision;
  final String? projectId;
  factory IntakeSummary.fromJson(Object? value) {
    final data = objectValue(value);
    return IntakeSummary(
      id: stringValue(data, 'intake_id'),
      status: stringValue(data, 'session_status'),
      revision: integerValue(data, 'draft_revision'),
      projectId: data['project_id'] as String?,
    );
  }
}

class IntakeDraft {
  const IntakeDraft({
    required this.id,
    required this.revision,
    required this.values,
    required this.fieldRevisions,
    required this.answerStates,
    required this.inputRefs,
    this.projectId,
    this.rowVersion = 1,
    this.status = 'active',
  });
  final String id;
  final int rowVersion;
  final String status;
  final int revision;
  final Map<String, dynamic> values;
  final Map<String, int> fieldRevisions;
  final Map<String, String> answerStates;
  final List<Map<String, dynamic>> inputRefs;
  final String? projectId;
  factory IntakeDraft.fromJson(Object? value) {
    final data = objectValue(value), states = objectValue(data['field_states']);
    final refs = data['input_refs'];
    if (refs is! List) throw const FormatException();
    return IntakeDraft(
      id: stringValue(data, 'intake_id'),
      rowVersion: integerValue(data, 'row_version'),
      status: stringValue(data, 'session_status'),
      revision: integerValue(data, 'draft_revision'),
      values: objectValue(data['groups']),
      fieldRevisions: states.map(
        (key, value) =>
            MapEntry(key, integerValue(objectValue(value), 'field_revision')),
      ),
      answerStates: states.map(
        (key, value) =>
            MapEntry(key, stringValue(objectValue(value), 'answer_state')),
      ),
      inputRefs: refs.map(objectValue).toList(),
      projectId: data['project_id'] as String?,
    );
  }
}

class PreparedBrief {
  const PreparedBrief(this.projectId, this.versionId);
  final String projectId, versionId;
  factory PreparedBrief.fromJson(Object? value) {
    final data = objectValue(value);
    return PreparedBrief(
      stringValue(data, 'project_id'),
      stringValue(data, 'version_id'),
    );
  }
}

class RequirementView {
  const RequirementView({
    required this.id,
    required this.versionId,
    required this.hash,
    required this.number,
    required this.expectedVersion,
    required this.title,
    required this.values,
    required this.confirmed,
    this.answerStates = const {},
    this.canConfirm = false,
  });
  final String id, versionId, hash, title;
  final int number, expectedVersion;
  final bool confirmed;
  final Map<String, dynamic> values;
  final Map<String, String> answerStates;
  final bool canConfirm;
  factory RequirementView.fromJson(Object? value) {
    final data = objectValue(value), content = objectValue(data['content']);
    return RequirementView(
      id: stringValue(data, 'requirement_id'),
      versionId: stringValue(data, 'version_id'),
      hash: stringValue(data, 'content_hash'),
      number: integerValue(data, 'version_number'),
      expectedVersion: integerValue(data, 'expected_requirement_version'),
      title: stringValue(content, 'title'),
      values: objectValue(content['details']),
      confirmed: data['confirmation_state'] == 'confirmed',
      answerStates: objectValue(content['field_states']).map(
        (key, value) =>
            MapEntry(key, stringValue(objectValue(value), 'answer_state')),
      ),
      canConfirm:
          data['allowed_actions'] is List &&
          (data['allowed_actions'] as List).contains('REQUIREMENTS_CONFIRM'),
    );
  }
}
