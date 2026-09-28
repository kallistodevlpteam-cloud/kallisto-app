import 'package:flutter/material.dart';
import '../../design_system/components.dart';

class FormsSection extends StatefulWidget {
  const FormsSection({super.key});
  @override
  State<FormsSection> createState() => _FormsSectionState();
}

class _FormsSectionState extends State<FormsSection> {
  final form = GlobalKey<FormState>();
  bool notifications = true;
  bool checked = false;
  String service = 'Architecture';
  double progress = 60;
  bool submitted = false;
  DateTime? date;
  final tags = <String>{'Architecture'};
  @override
  Widget build(BuildContext context) => Column(
    children: [
      KSection(
        title: 'Anatomy of a form',
        description:
            'Visible labels, useful help, and inline validation. This sample form does not create project records.',
        child: KPanel(
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KBadge('Component demonstration', tone: KBadgeTone.info),
                const SizedBox(height: 24),
                KGrid(
                  minWidth: 280,
                  children: [
                    TextFormField(
                      key: const ValueKey('project-name'),
                      decoration: const InputDecoration(
                        labelText: 'Project name',
                        hintText: 'e.g. Courtyard residence',
                        helperText: 'A short, recognizable name.',
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 3
                          ? 'Enter at least 3 characters.'
                          : null,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Contact email',
                        hintText: 'studio@example.com',
                        prefixIcon: Icon(Icons.mail_outline),
                        helperText: 'Used only to demonstrate validation.',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null ||
                              !RegExp(
                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                              ).hasMatch(value.trim())
                          ? 'Enter a valid email address.'
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                KGrid(
                  minWidth: 280,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: service,
                      decoration: const InputDecoration(labelText: 'Service'),
                      items: [
                        for (final name in [
                          'Architecture',
                          'Interior design',
                          'Engineering',
                        ])
                          DropdownMenuItem(value: name, child: Text(name)),
                      ],
                      onChanged: (value) => setState(() => service = value!),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: date ?? DateTime(2026, 9, 28),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                        );
                        if (mounted && selected != null) {
                          setState(() => date = selected);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        date == null
                            ? 'Choose a sample date'
                            : '${date!.day}/${date!.month}/${date!.year}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Optional details for the sample…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Include this sample in my selection'),
                  value: checked,
                  onChanged: (value) => setState(() => checked = value!),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          setState(() => submitted = true);
                        }
                      },
                      child: const Text('Validate sample'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        form.currentState!.reset();
                        setState(() {
                          submitted = false;
                          date = null;
                          checked = false;
                          service = 'Architecture';
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                if (submitted)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Semantics(
                      liveRegion: true,
                      child: const KBadge(
                        'Sample validation passed',
                        tone: KBadgeTone.success,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      KSection(
        title: 'Input states',
        description:
            'Default, error, disabled, and multiline fields share the same geometry.',
        child: const KGrid(
          minWidth: 260,
          children: [
            KPanel(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Default field',
                  hintText: 'Type something',
                ),
              ),
            ),
            KPanel(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Validation error',
                  errorText: 'This value needs your attention.',
                ),
              ),
            ),
            KPanel(
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Disabled field',
                  hintText: 'Not available',
                ),
              ),
            ),
          ],
        ),
      ),
      KSection(
        title: 'Choices & preferences',
        description:
            'Use switches for immediate preferences, checkboxes for selection, and chips for filters.',
        child: KGrid(
          minWidth: 280,
          children: [
            KPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activity notifications'),
                    subtitle: const Text('Sample preference'),
                    value: notifications,
                    onChanged: (value) => setState(() => notifications = value),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Progress · ${progress.round()}%'),
                  Slider(
                    value: progress,
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '${progress.round()}%',
                    onChanged: (value) => setState(() => progress = value),
                  ),
                ],
              ),
            ),
            KPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by expertise',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final label in [
                        'Architecture',
                        'Interiors',
                        'Landscape',
                        'Engineering',
                      ])
                        FilterChip(
                          label: Text(label),
                          selected: tags.contains(label),
                          onSelected: (selected) => setState(
                            () =>
                                selected ? tags.add(label) : tags.remove(label),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('${tags.length} expertise filters selected'),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
