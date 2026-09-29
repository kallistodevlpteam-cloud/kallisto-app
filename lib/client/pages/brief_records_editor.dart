import 'dart:convert';
import 'package:flutter/material.dart';
import '../client_gateway.dart';
import '../intake_fields.dart';

class BriefEntryProperty {
  const BriefEntryProperty(
    this.key,
    this.label, {
    this.optional = false,
    this.numeric = false,
    this.options = const {},
  });
  final String key, label;
  final bool optional, numeric;
  final Map<String, String> options;
}

List<BriefEntryProperty> briefEntryProperties(String path) => switch (path) {
  'brief.scope.existing_professional_refs' => const [
    BriefEntryProperty('name', 'Name'),
    BriefEntryProperty('role', 'Role or scope'),
    BriefEntryProperty('contact', 'Contact, if permitted', optional: true),
    BriefEntryProperty('notes', 'Notes', optional: true),
  ],
  'brief.building.future_expansion' => const [
    BriefEntryProperty('description', 'Future wish'),
    BriefEntryProperty('timing', 'Timing in your words', optional: true),
  ],
  'brief.site.reported_conditions' => const [
    BriefEntryProperty('observation', 'Your observation'),
  ],
  'brief.spaces.additional_spaces' => const [
    BriefEntryProperty('label', 'Space name'),
    BriefEntryProperty('category', 'Type of space'),
    BriefEntryProperty(
      'scope',
      'Scope',
      options: {
        'present': 'Present scope',
        'future': 'Future wish',
        'alternative': 'Alternative',
      },
    ),
    BriefEntryProperty(
      'count',
      'Count, if known',
      optional: true,
      numeric: true,
    ),
    BriefEntryProperty('notes', 'Notes', optional: true),
  ],
  'brief.design.priorities' => const [
    BriefEntryProperty('label', 'Priority'),
    BriefEntryProperty(
      'rank',
      'Rank, only if you want to rank it',
      optional: true,
      numeric: true,
    ),
  ],
  'brief.design.reference_refs' => const [
    BriefEntryProperty('label', 'Reference title'),
    BriefEntryProperty('url', 'HTTPS reference URL'),
  ],
  'brief.documents.reported_approval_status' => const [
    BriefEntryProperty('statement', 'What you report was approved'),
    BriefEntryProperty(
      'reported_by',
      'Approving person or body, as reported',
      optional: true,
    ),
  ],
  _ => const [
    BriefEntryProperty('label', 'Name'),
    BriefEntryProperty(
      'existing_or_proposed',
      'Existing or proposed',
      options: {'existing': 'Existing', 'proposed': 'Proposed'},
    ),
    BriefEntryProperty('notes', 'Notes', optional: true),
  ],
};

class BriefRecordsEditor extends StatefulWidget {
  const BriefRecordsEditor({
    super.key,
    required this.field,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });
  final BriefField field;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;
  @override
  State<BriefRecordsEditor> createState() => _BriefRecordsEditorState();
}

class _BriefRecordsEditorState extends State<BriefRecordsEditor> {
  List<Map<String, dynamic>> rows = [];
  @override
  void initState() {
    super.initState();
    try {
      rows = (jsonDecode(widget.controller.text) as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
    } catch (_) {}
  }

  void save() {
    widget.controller.text = rows.isEmpty ? '' : jsonEncode(rows);
    widget.onChanged();
  }

  Future<void> edit([int? index]) async {
    final properties = briefEntryProperties(widget.field.path);
    final previous = index == null ? <String, dynamic>{} : rows[index];
    final editors = {
      for (final p in properties) p.key: previous[p.key]?.toString() ?? '',
    };
    final form = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          index == null
              ? 'Add ${widget.field.label.toLowerCase()}'
              : 'Edit entry',
        ),
        content: SizedBox(
          width: 420,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Your report only. This does not verify a professional, approval or site condition.',
                  ),
                  for (final p in properties)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: p.options.isNotEmpty
                          ? DropdownButtonFormField<String>(
                              initialValue: editors[p.key]!.isEmpty
                                  ? null
                                  : editors[p.key]!,
                              isExpanded: true,
                              decoration: InputDecoration(labelText: p.label),
                              items: p.options.entries
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => editors[p.key] = v ?? '',
                              validator: (v) =>
                                  v == null ? 'Choose a value.' : null,
                            )
                          : TextFormField(
                              initialValue: editors[p.key],
                              onChanged: (v) => editors[p.key] = v,
                              maxLength: p.key == 'url'
                                  ? 2000
                                  : p.key == 'notes' ||
                                        p.key == 'statement' ||
                                        p.key == 'observation' ||
                                        p.key == 'description'
                                  ? 1000
                                  : 240,
                              decoration: InputDecoration(labelText: p.label),
                              keyboardType: p.numeric
                                  ? TextInputType.number
                                  : TextInputType.text,
                              validator: (input) {
                                final v = input?.trim() ?? '';
                                if (v.isEmpty) {
                                  return p.optional
                                      ? null
                                      : 'Enter this detail.';
                                }
                                if (p.numeric &&
                                    (int.tryParse(v) == null ||
                                        int.parse(v) <
                                            (p.key == 'rank' ? 1 : 0) ||
                                        int.parse(v) >
                                            (p.key == 'rank'
                                                ? 100
                                                : 1000000))) {
                                  return 'Enter a valid whole number.';
                                }
                                if (p.key == 'url') {
                                  final u = Uri.tryParse(v);
                                  if (u == null ||
                                      u.scheme != 'https' ||
                                      u.host.isEmpty ||
                                      u.userInfo.isNotEmpty) {
                                    return 'Enter an HTTPS reference without credentials.';
                                  }
                                }
                                if (p.key == 'name' ||
                                    p.key == 'role' ||
                                    p.key == 'category') {
                                  if (v.length > 120) {
                                    return 'Use up to 120 characters.';
                                  }
                                }
                                return null;
                              },
                            ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              final row = <String, dynamic>{
                'entry_id': previous['entry_id'] ?? clientIntentId(),
                for (final p in properties)
                  if (editors[p.key]!.trim().isNotEmpty)
                    p.key: p.numeric
                        ? int.parse(editors[p.key]!.trim())
                        : editors[p.key]!.trim(),
              };
              if (widget.field.path == 'brief.renovation.target_areas' ||
                  widget.field.path == 'brief.interior.reuse_items') {
                row['source_refs'] = <Object>[];
              }
              Navigator.pop(context, row);
            },
            child: const Text('Use this entry'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (index == null) {
        rows.add(result);
      } else {
        rows[index] = result;
      }
    });
    save();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.field.label, style: Theme.of(context).textTheme.titleSmall),
      for (final (index, row) in rows.indexed)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            (row['label'] ??
                    row['name'] ??
                    row['description'] ??
                    row['observation'] ??
                    row['statement'])
                .toString(),
          ),
          subtitle: TextButton(
            onPressed: widget.enabled ? () => edit(index) : null,
            child: const Text('Edit entry'),
          ),
          trailing: IconButton(
            tooltip: 'Remove from working draft',
            onPressed: widget.enabled
                ? () {
                    setState(() => rows.removeAt(index));
                    save();
                  }
                : null,
            icon: const Icon(Icons.close),
          ),
        ),
      OutlinedButton.icon(
        onPressed: widget.enabled && rows.length < 30 ? () => edit() : null,
        icon: const Icon(Icons.add),
        label: const Text('Add entry'),
      ),
      if (widget.field.path == 'brief.design.reference_refs')
        const Text(
          'References are saved as links. Their contents are not fetched or verified.',
        ),
    ],
  );
}
