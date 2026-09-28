import 'workflow_models.dart';

class LeadProvider {
  const LeadProvider(
    this.id,
    this.name,
    this.summary,
    this.services,
    this.coverage,
    this.qualifications,
  );
  final String id, name, summary;
  final List<String> services, coverage, qualifications;
  factory LeadProvider.fromJson(Object? source) {
    final row = objectValue(source);
    List<String> list(String key) => (row[key] as List).cast<String>();
    return LeadProvider(
      stringValue(row, 'provider_id'),
      stringValue(row, 'name'),
      stringValue(row, 'summary'),
      list('service_codes'),
      list('coverage_codes'),
      list('verified_categories'),
    );
  }
}

class ProviderPage {
  const ProviderPage(this.items, this.cursor);
  final List<LeadProvider> items;
  final String? cursor;
  factory ProviderPage.fromJson(Object? source) {
    final row = objectValue(source);
    return ProviderPage(
      (row['items'] as List).map(LeadProvider.fromJson).toList(),
      row['next_cursor'] as String?,
    );
  }
}
