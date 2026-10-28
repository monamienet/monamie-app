/// A scheduled deletion of the signed-in account: in its 30 days the person
/// can cancel; then the account (and the organizations they own) is erased.
class AccountDeletion {
  const AccountDeletion({
    required this.deleteAt,
    this.ownedPartners = const [],
    this.ownedNames = const {},
  });

  /// Reads `{deleteAt: ISO string, ownedPartners: [id], ownedNames: {id:
  /// name}}`; `null` when [json] is not a deletion.
  static AccountDeletion? fromJson(Object? json) {
    if (json is! Map) return null;
    final deleteAt = DateTime.tryParse('${json['deleteAt']}');
    if (deleteAt == null) return null;
    final owned = json['ownedPartners'];
    final names = json['ownedNames'];
    return AccountDeletion(
      deleteAt: deleteAt,
      ownedPartners: [
        if (owned is List)
          for (final id in owned)
            if (id is String) id,
      ],
      ownedNames: {
        if (names is Map)
          for (final MapEntry(:key, :value) in names.entries)
            if (key is String && value is String) key: value,
      },
    );
  }

  final DateTime deleteAt;

  /// Ids of the organizations deleted with the account.
  final List<String> ownedPartners;

  final Map<String, String> ownedNames;

  /// The organization deleted with the account, as shown in the titles; the
  /// first one when there are several, `null` for a plain member.
  String? get organizationName {
    if (ownedPartners.isEmpty) return null;
    final id = ownedPartners.first;
    return ownedNames[id] ?? id;
  }
}

const _months = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// "25 de novembro de 2026", in the device's time zone.
String longDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day} de ${_months[local.month - 1]} de ${local.year}';
}

/// Whole days left until [deleteAt], counting a started day as one and
/// never below zero.
int daysLeft(DateTime deleteAt, DateTime now) {
  final left = deleteAt.difference(now);
  if (left <= Duration.zero) return 0;
  return (left.inMinutes / Duration.minutesPerDay).ceil();
}

/// "em 30 dias", "em 1 dia", "hoje".
String inDays(int days) => switch (days) {
  0 => 'hoje',
  1 => 'em 1 dia',
  _ => 'em $days dias',
};

/// Whether the text typed to confirm matches the organization's id (case
/// and surrounding spaces ignored).
bool confirmsId(String typed, String id) => typed.trim().toLowerCase() == id;
