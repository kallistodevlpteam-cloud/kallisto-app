import 'workflow_models.dart';

class ClientSettings {
  const ClientSettings(this.section, this.version, this.values);
  final String section;
  final int version;
  final Map<String, dynamic> values;
  factory ClientSettings.fromJson(Object? source) {
    final json = objectValue(source);
    return ClientSettings(
      stringValue(json, 'section'),
      (json['row_version'] as num).toInt(),
      objectValue(json['values']),
    );
  }
}
