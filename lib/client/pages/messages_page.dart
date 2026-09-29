import 'package:flutter/material.dart';
import '../../design_system/components.dart';
import '../client_gateway.dart';
import '../client_models.dart';
import '../message_models.dart';

class ClientMessagesPage extends StatefulWidget {
  const ClientMessagesPage({
    super.key,
    required this.gateway,
    this.conversationId,
  });
  final ClientGateway gateway;
  final String? conversationId;
  @override
  State<ClientMessagesPage> createState() => _ClientMessagesPageState();
}

class _ClientMessagesPageState extends State<ClientMessagesPage> {
  final _text = TextEditingController();
  List<ClientThread> _threads = [];
  List<ThreadMessage> _messages = [];
  ClientThread? _thread;
  String? _cursor, _intentText, _intentKey;
  String _error = '', _sendStatus = '';
  bool _busy = false, _sending = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load({bool next = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final id = widget.conversationId;
      if (id == null) {
        final page = await widget.gateway.conversations(
          cursor: next ? _cursor : null,
        );
        if (mounted) {
          setState(() {
            _threads = [if (next) ..._threads, ...page.items];
            _cursor = page.cursor;
          });
        }
      } else {
        final thread = await widget.gateway.conversation(id);
        final page = await widget.gateway.messages(
          id,
          cursor: next ? _cursor : null,
        );
        if (mounted) {
          setState(() {
            _thread = thread;
            _messages = [if (next) ..._messages, ...page.items]
              ..sort((a, b) => a.sequence.compareTo(b.sequence));
            _cursor = page.cursor;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _threads = [];
          _messages = [];
          _thread = null;
          _cursor = null;
          _error = error is ClientFailure
              ? error.message
              : 'Could not load messages. Please retry.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (_sending ||
        text.isEmpty ||
        text.length > 8000 ||
        _thread?.status != 'open') {
      return;
    }
    if (_intentText != text) {
      _intentText = text;
      _intentKey = clientIntentId();
    }
    setState(() {
      _sending = true;
      _sendStatus = 'Sending…';
    });
    try {
      await widget.gateway.sendMessage(_thread!.id, text, _intentKey!);
      if (mounted) {
        _text.clear();
        _intentText = null;
        _intentKey = null;
        setState(() => _sendStatus = 'Message saved.');
        await _load();
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _sendStatus = error is ClientFailure
              ? error.message
              : 'Delivery is uncertain. Your text is retained; retry to recover the result.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _thread?.title ?? 'Your conversations',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 12),
      const Text(
        'Conversations stay within their project, enquiry or support case. Messages do not approve scope, costs or completion.',
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        children: [
          OutlinedButton(
            onPressed: _busy ? null : () => _load(),
            child: const Text('Refresh'),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/help'),
            child: const Text('Help & support'),
          ),
        ],
      ),
      if (_busy) const LinearProgressIndicator(),
      if (_error.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(_error),
        ),
      if (!_busy &&
          _error.isEmpty &&
          widget.conversationId == null &&
          _threads.isEmpty)
        const KPanel(
          child: Text(
            'No conversations on this page. Enquiries and support requests create their own threads.',
          ),
        ),
      for (final thread in _threads)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: KPanel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(thread.title),
              subtitle: Text('${thread.kind} · ${thread.status}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(
                context,
                '/messages/${Uri.encodeComponent(thread.id)}',
              ),
            ),
          ),
        ),
      if (_thread != null) ...[
        const SizedBox(height: 16),
        KBadge('${_thread!.kind} · ${_thread!.status}'),
        if (_messages.isEmpty && !_busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No messages yet.'),
          ),
        for (final message in _messages)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: KPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.author,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(message.text),
                  if (message.createdAt != null)
                    Text(
                      message.createdAt!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        if (_thread!.status == 'open') ...[
          TextField(
            controller: _text,
            enabled: !_sending,
            minLines: 2,
            maxLines: 6,
            maxLength: 8000,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Write to this conversation',
            ),
          ),
          FilledButton(
            onPressed: _sending ? null : _send,
            child: Text(_sending ? 'Sending…' : 'Send message'),
          ),
          const Text('File attachments are not available yet.'),
        ] else
          const Text('This conversation is read-only.'),
        if (_sendStatus.isNotEmpty) Text(_sendStatus),
      ],
      if (_cursor != null)
        OutlinedButton(
          onPressed: _busy ? null : () => _load(next: true),
          child: Text(
            widget.conversationId == null ? 'Load more' : 'Load older messages',
          ),
        ),
    ],
  );
}
