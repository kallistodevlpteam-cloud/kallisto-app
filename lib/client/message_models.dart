import 'workflow_models.dart';

class ClientThread {
  const ClientThread(this.id, this.title, this.kind, this.status);
  final String id, title, kind, status;
  factory ClientThread.fromJson(Object? source) {
    final row = objectValue(source);
    return ClientThread(
      stringValue(row, 'conversation_id'),
      stringValue(row, 'title'),
      stringValue(objectValue(row['context']), 'kind'),
      stringValue(row, 'status'),
    );
  }
}

class ThreadMessage {
  const ThreadMessage(
    this.id,
    this.text,
    this.author,
    this.sequence,
    this.createdAt,
  );
  final String id, text, author;
  final int sequence;
  final String? createdAt;
  factory ThreadMessage.fromJson(Object? source) {
    final row = objectValue(source);
    return ThreadMessage(
      stringValue(row, 'message_id'),
      stringValue(row, 'text'),
      stringValue(objectValue(row['author_summary']), 'display_name'),
      integerValue(row, 'sequence'),
      row['created_at'] as String?,
    );
  }
}

class SupportCase {
  const SupportCase(
    this.id,
    this.subject,
    this.description,
    this.status,
    this.conversationId,
    this.version,
    this.category,
  );
  final String id, subject, description, status, conversationId, category;
  final int version;
  factory SupportCase.fromJson(Object? source) {
    final row = objectValue(source);
    return SupportCase(
      stringValue(row, 'case_id'),
      stringValue(row, 'subject'),
      stringValue(row, 'description'),
      stringValue(row, 'status'),
      stringValue(row, 'conversation_id'),
      integerValue(row, 'row_version'),
      stringValue(row, 'category'),
    );
  }
}

class ClientPage<T> {
  const ClientPage(this.items, this.cursor);
  final List<T> items;
  final String? cursor;
  static ClientPage<T> parse<T>(Object? source, T Function(Object?) parse) {
    final row = objectValue(source);
    return ClientPage(
      (row['items'] as List).map(parse).toList(),
      row['next_cursor'] as String?,
    );
  }
}
