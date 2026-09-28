enum BriefFieldKind { text, paragraph, count, money, choice, list, boolean }

class BriefField {
  const BriefField(
    this.path,
    this.label,
    this.group, {
    this.kind = BriefFieldKind.text,
    this.options = const {},
    this.limit = 1000,
  });
  final String path, label, group;
  final BriefFieldKind kind;
  final Map<String, String> options;
  final int limit;
}

const briefFields = [
  BriefField('brief.project.name', 'Project name', 'The idea', limit: 120),
  BriefField(
    'brief.project.project_type',
    'Project type',
    'The idea',
    kind: BriefFieldKind.choice,
    options: {
      'architecture': 'Architecture',
      'interior': 'Interiors',
      'construction': 'Construction',
      'renovation': 'Renovation',
      'other': 'Other',
    },
  ),
  BriefField(
    'brief.scope.description',
    'What would you like to create?',
    'The idea',
    kind: BriefFieldKind.paragraph,
    limit: 2000,
  ),
  BriefField(
    'brief.scope.work_nature',
    'Nature of work',
    'The idea',
    kind: BriefFieldKind.choice,
    options: {
      'new_build': 'New build',
      'interior_fitout': 'Interior fitout',
      'renovation': 'Renovation',
      'extension': 'Extension',
      'maintenance': 'Maintenance',
      'other': 'Other',
    },
  ),
  BriefField(
    'brief.scope.reported_current_stage',
    'Where are you in the process?',
    'The idea',
    limit: 240,
  ),
  BriefField(
    'brief.building.use',
    'Building use',
    'The idea',
    kind: BriefFieldKind.choice,
    options: {
      'residential': 'Residential',
      'commercial': 'Commercial',
      'mixed_use': 'Mixed use',
      'other': 'Other',
    },
  ),
  BriefField(
    'brief.scope.exclusions',
    'Outside your scope',
    'The idea',
    kind: BriefFieldKind.list,
  ),
  BriefField(
    'brief.site.location.locality',
    'Locality or town',
    'Your site',
    limit: 240,
  ),
  BriefField(
    'brief.site.location.district',
    'District',
    'Your site',
    limit: 120,
  ),
  BriefField('brief.site.location.state', 'State', 'Your site', limit: 120),
  BriefField(
    'brief.site.location.country',
    'Country code (for example IN)',
    'Your site',
    limit: 2,
  ),
  BriefField(
    'brief.site.location.address',
    'Site address',
    'Your site',
    kind: BriefFieldKind.paragraph,
  ),
  BriefField(
    'brief.site.tenure_status',
    'Site tenure',
    'Your site',
    kind: BriefFieldKind.choice,
    options: {
      'owned': 'Owned',
      'rented': 'Rented',
      'permission_reported': 'Permission reported',
      'selecting': 'Still selecting',
      'other': 'Other',
    },
  ),
  BriefField(
    'brief.site.client_authority_status',
    'Authority to commission work',
    'Your site',
    kind: BriefFieldKind.choice,
    options: {
      'reported_authorized': 'I report that I am authorized',
      'needs_confirmation': 'Needs confirmation',
      'unknown': 'Unknown',
    },
  ),
  BriefField(
    'brief.site.access_constraints',
    'Site access constraints',
    'Your site',
    kind: BriefFieldKind.list,
  ),
  BriefField(
    'brief.building.floor_count_including_ground',
    'Floors, including ground floor',
    'Spaces',
    kind: BriefFieldKind.count,
  ),
  BriefField(
    'brief.building.basement_levels',
    'Basement levels',
    'Spaces',
    kind: BriefFieldKind.count,
  ),
  BriefField(
    'brief.spaces.bedrooms.total',
    'Bedrooms in total',
    'Spaces',
    kind: BriefFieldKind.count,
  ),
  BriefField(
    'brief.spaces.bedrooms.ground_floor_count',
    'Ground floor bedrooms',
    'Spaces',
    kind: BriefFieldKind.count,
  ),
  BriefField(
    'brief.spaces.bathrooms.total',
    'Bathrooms in total',
    'Spaces',
    kind: BriefFieldKind.count,
  ),
  BriefField(
    'brief.spaces.bathrooms.attached_count',
    'Attached bathrooms',
    'Spaces',
    kind: BriefFieldKind.count,
  ),
  BriefField(
    'brief.spaces.kitchen.preferences',
    'Kitchen preferences',
    'Spaces',
    kind: BriefFieldKind.list,
  ),
  BriefField(
    'brief.spaces.utility_area_required',
    'Utility area needed',
    'Spaces',
    kind: BriefFieldKind.boolean,
  ),
  BriefField(
    'brief.spaces.parking.vehicle_count',
    'Parking spaces needed',
    'Spaces',
    kind: BriefFieldKind.count,
  ),
  BriefField(
    'brief.spaces.parking.covered_required',
    'Covered parking needed',
    'Spaces',
    kind: BriefFieldKind.boolean,
  ),
  BriefField(
    'brief.household.occupant_count',
    'Number of occupants',
    'People & style',
    kind: BriefFieldKind.count,
  ),
  BriefField(
    'brief.household.functional_needs',
    'Everyday needs',
    'People & style',
    kind: BriefFieldKind.list,
  ),
  BriefField(
    'brief.household.accessibility_preferences',
    'Accessibility preferences',
    'People & style',
    kind: BriefFieldKind.list,
  ),
  BriefField(
    'brief.design.style_preferences',
    'Styles you like',
    'People & style',
    kind: BriefFieldKind.list,
  ),
  BriefField(
    'brief.design.environmental_preferences',
    'Environmental preferences',
    'People & style',
    kind: BriefFieldKind.list,
  ),
  BriefField(
    'brief.budget.target_minor',
    'Target budget (INR)',
    'Budget & timing',
    kind: BriefFieldKind.money,
  ),
  BriefField(
    'brief.budget.minimum_minor',
    'Budget range minimum (INR)',
    'Budget & timing',
    kind: BriefFieldKind.money,
  ),
  BriefField(
    'brief.budget.maximum_minor',
    'Budget range maximum (INR)',
    'Budget & timing',
    kind: BriefFieldKind.money,
  ),
  BriefField(
    'brief.budget.hard_cap_minor',
    'Firm maximum (INR)',
    'Budget & timing',
    kind: BriefFieldKind.money,
  ),
  BriefField(
    'brief.budget.amount_qualifier',
    'How precise is this budget?',
    'Budget & timing',
    kind: BriefFieldKind.choice,
    options: {
      'approximate': 'Approximate',
      'stated_exact': 'Stated exact',
      'range': 'Range',
      'undecided': 'Undecided',
    },
  ),
  BriefField(
    'brief.budget.flexibility',
    'Budget flexibility',
    'Budget & timing',
    kind: BriefFieldKind.choice,
    options: {
      'flexible_target': 'Flexible target',
      'preferred_range': 'Preferred range',
      'firm_maximum': 'Firm maximum',
      'undecided': 'Undecided',
    },
  ),
  BriefField(
    'brief.budget.scope',
    'What should the budget cover?',
    'Budget & timing',
    kind: BriefFieldKind.paragraph,
  ),
  BriefField(
    'brief.timing.deadline_reason',
    'Timing, deadlines and why they matter',
    'Budget & timing',
    kind: BriefFieldKind.paragraph,
  ),
  BriefField(
    'brief.constraints.must_keep',
    'What must stay?',
    'Other details',
    kind: BriefFieldKind.list,
  ),
  BriefField(
    'brief.constraints.must_avoid',
    'What should we avoid?',
    'Other details',
    kind: BriefFieldKind.list,
  ),
  BriefField(
    'brief.existing_building.reported_structure',
    'Existing structure, as you understand it',
    'Other details',
    kind: BriefFieldKind.paragraph,
  ),
  BriefField(
    'brief.renovation.intervention_intent',
    'Planned renovation work',
    'Other details',
    kind: BriefFieldKind.list,
  ),
  BriefField(
    'brief.renovation.occupied_during_work',
    'Will the property be occupied during work?',
    'Other details',
    kind: BriefFieldKind.boolean,
  ),
  BriefField(
    'brief.renovation.work_time_constraints',
    'Restrictions on working times',
    'Other details',
    kind: BriefFieldKind.list,
  ),
  BriefField(
    'brief.renovation.structural_change_intent',
    'Proposed structural changes',
    'Other details',
    kind: BriefFieldKind.choice,
    options: {
      'proposed': 'Proposed',
      'not_proposed': 'Not proposed',
      'unsure': 'Unsure',
    },
  ),
  BriefField(
    'brief.interior.fitout_scope',
    'Interior fitout scope',
    'Other details',
    kind: BriefFieldKind.list,
  ),
  BriefField(
    'brief.commercial.intended_use',
    'Commercial use, if applicable',
    'Other details',
  ),
  BriefField(
    'brief.commercial.expected_occupancy',
    'Expected commercial occupancy',
    'Other details',
    kind: BriefFieldKind.count,
  ),
  BriefField(
    'brief.constraints.additional_notes',
    'Anything else we should know?',
    'Other details',
    kind: BriefFieldKind.paragraph,
    limit: 8000,
  ),
];

String briefLabel(String path) {
  for (final field in briefFields) {
    if (field.path == path) return field.label;
  }
  return path
      .replaceFirst('brief.', '')
      .replaceAll('.', ' · ')
      .replaceAll('_', ' ');
}

String briefDisplay(String path, dynamic value) {
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is List) return value.join('; ');
  if (path.endsWith('_minor') && value is int) {
    return '₹${(value ~/ 100)}.${(value % 100).toString().padLeft(2, '0')}';
  }
  for (final field in briefFields) {
    if (field.path == path && field.options.containsKey(value)) {
      return field.options[value]!;
    }
  }
  return value.toString();
}
