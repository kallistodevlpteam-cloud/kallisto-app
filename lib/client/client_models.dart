enum ClientSection { home, projects, providers, messages, account }

enum ClientConnection {
  loading,
  signedOut,
  ready,
  denied,
  offline,
  unavailable,
}

class ClientFailure implements Exception {
  const ClientFailure(this.connection, this.message);
  final ClientConnection connection;
  final String message;
}

class ClientProject {
  const ClientProject({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.phase,
    this.location,
  });
  final String id;
  final String name;
  final String type;
  final String status;
  final String phase;
  final String? location;

  factory ClientProject.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) throw const FormatException();
    String requiredString(String key) {
      final field = value[key];
      if (field is! String || field.isEmpty) throw const FormatException();
      return field;
    }

    final location = value['location'];
    if (location != null && location is! String) throw const FormatException();
    return ClientProject(
      id: requiredString('project_id'),
      name: requiredString('name'),
      type: requiredString('project_type'),
      status: requiredString('status'),
      phase: requiredString('phase'),
      location: location as String?,
    );
  }
}

class ClientSnapshot {
  const ClientSnapshot({
    required this.uid,
    required this.name,
    required this.projects,
    required this.nextCursor,
  });
  final String uid;
  final String name;
  final List<ClientProject> projects;
  final String? nextCursor;
}
