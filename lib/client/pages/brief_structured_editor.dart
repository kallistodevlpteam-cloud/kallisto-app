import 'dart:convert';
import 'package:flutter/material.dart';
import '../intake_fields.dart';

/// Typed controls retain partial edits locally; only complete validated values save.
class BriefStructuredEditor extends StatefulWidget {
  const BriefStructuredEditor({
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
  State<BriefStructuredEditor> createState() => _BriefStructuredEditorState();
}

class _BriefStructuredEditorState extends State<BriefStructuredEditor> {
  Map<String, dynamic> value = {};
  @override
  void initState() {
    super.initState();
    try {
      value = Map<String, dynamic>.from(
        jsonDecode(widget.controller.text) as Map,
      );
    } catch (_) {}
  }

  void update(String key, Object? next) {
    setState(() {
      if (next == null ||
          (widget.field.kind == BriefFieldKind.serviceObservations &&
              next == '')) {
        value.remove(key);
      } else {
        value[key] = next;
      }
      if (widget.field.kind == BriefFieldKind.sitePin) {
        value['source'] = 'user_shared';
      }
      if (widget.field.kind == BriefFieldKind.datePreference) {
        final kind = value['kind'];
        if (kind == 'date' || kind == 'month') {
          value['raw_phrase'] = value['value'] ?? '';
        }
        if (kind == 'date_range') {
          value['raw_phrase'] =
              '${value['start'] ?? ''} to ${value['end'] ?? ''}';
        }
      }
      widget.controller.text = jsonEncode(value);
    });
    widget.onChanged();
  }

  Widget text(String key, String label, {bool number = false}) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextFormField(
      key: ValueKey('${widget.field.path}:$key:${value['kind']}'),
      initialValue: value[key]?.toString() ?? '',
      enabled: widget.enabled,
      decoration: InputDecoration(labelText: label),
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      maxLength: 500,
      onChanged: (v) => update(key, number ? (double.tryParse(v) ?? v) : v),
    ),
  );
  Widget choice(String key, String label, Map<String, String> options) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: DropdownButtonFormField<String>(
          initialValue: value[key] as String?,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: options.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: widget.enabled
              ? (v) {
                  if (key == 'kind') {
                    value = {};
                  }
                  update(key, v);
                }
              : null,
        ),
      );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.field.label, style: Theme.of(context).textTheme.titleSmall),
      if (widget.field.kind == BriefFieldKind.serviceObservations) ...[
        const Text(
          'Only enter services you know about. Leaving a service blank keeps it unknown.',
        ),
        for (final key in ['water', 'power', 'drainage', 'internet', 'gas'])
          text(
            key,
            '${key[0].toUpperCase()}${key.substring(1)} — what you know',
          ),
      ],
      if (widget.field.kind == BriefFieldKind.measurement) ...[
        text('value', 'Area as stated'),
        choice('unit', 'Area unit', {
          'sq_ft': 'Square feet',
          'sq_m': 'Square metres',
          'cent': 'Cents',
          'acre': 'Acres',
        }),
        choice('precision', 'Precision', {
          'approximate': 'Approximate',
          'stated_exact': 'Stated exact',
        }),
      ],
      if (widget.field.kind == BriefFieldKind.sitePin) ...[
        const Text(
          'Share coordinates explicitly. This does not request your device location.',
        ),
        text('latitude', 'Latitude', number: true),
        text('longitude', 'Longitude', number: true),
      ],
      if (widget.field.kind == BriefFieldKind.datePreference) ...[
        choice('kind', 'How precise is the timing?', {
          'date': 'Specific day',
          'month': 'Month only',
          'date_range': 'Date range',
          'relative_duration': 'Relative period',
        }),
        if (value['kind'] == 'date') text('value', 'Date (YYYY-MM-DD)'),
        if (value['kind'] == 'month') text('value', 'Month (YYYY-MM)'),
        if (value['kind'] == 'date_range') ...[
          text('start', 'From (YYYY-MM-DD)'),
          text('end', 'To (YYYY-MM-DD)'),
        ],
        if (value['kind'] == 'relative_duration') ...[
          text('raw_phrase', 'Your timing preference, in your words'),
          text('reference_date', 'Reference date (YYYY-MM-DD)'),
          text('timezone', 'Time zone (for example Asia/Kolkata)'),
        ],
        const Text(
          'A preference only. This does not commit a provider to a schedule.',
        ),
      ],
    ],
  );
}

String? validateStructuredBrief(BriefField field, String encoded) {
  try {
    final v = jsonDecode(encoded) as Map<String, dynamic>;
    if (field.kind == BriefFieldKind.serviceObservations &&
        (v.isEmpty ||
            v.values.any(
              (x) => x is! String || x.trim().isEmpty || x.length > 500,
            ))) {
      return 'Describe a service you know about, or choose an answer status.';
    }
    if (field.kind == BriefFieldKind.measurement) {
      if (!RegExp(
            r'^\d{1,12}(\.\d{1,6})?$',
          ).hasMatch(v['value']?.toString() ?? '') ||
          !['sq_ft', 'sq_m', 'cent', 'acre'].contains(v['unit']) ||
          !['approximate', 'stated_exact'].contains(v['precision'])) {
        return 'Enter an area, unit and precision.';
      }
    }
    if (field.kind == BriefFieldKind.sitePin) {
      if (v['latitude'] is! num ||
          v['longitude'] is! num ||
          (v['latitude'] as num).abs() > 90 ||
          (v['longitude'] as num).abs() > 180) {
        return 'Enter latitude between −90 and 90 and longitude between −180 and 180.';
      }
    }
    if (field.kind == BriefFieldKind.datePreference) {
      bool date(dynamic x) {
        if (x is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(x)) {
          return false;
        }
        final d = DateTime.tryParse(x);
        return d != null && d.toIso8601String().startsWith(x);
      }

      switch (v['kind']) {
        case 'date':
          if (!date(v['value'])) return 'Enter a valid calendar date.';
        case 'month':
          if (!RegExp(
            r'^\d{4}-(0[1-9]|1[0-2])$',
          ).hasMatch(v['value']?.toString() ?? '')) {
            return 'Enter a valid year and month.';
          }
        case 'date_range':
          if (!date(v['start']) ||
              !date(v['end']) ||
              (v['start'] as String).compareTo(v['end'] as String) > 0) {
            return 'Enter a valid date range in chronological order.';
          }
        case 'relative_duration':
          if ((v['raw_phrase'] ?? '').toString().trim().isEmpty ||
              !date(v['reference_date']) ||
              (v['timezone'] ?? '').toString().trim().isEmpty) {
            return 'Provide the original timing phrase, reference date and time zone.';
          }
        default:
          return 'Choose how precise the timing is.';
      }
    }
    return null;
  } catch (_) {
    return 'Complete these details or choose an answer status.';
  }
}
