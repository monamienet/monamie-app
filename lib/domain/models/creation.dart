/// An organization being created by the signed-in account.
class Creation {
  const Creation({
    required this.id,
    required this.name,
    required this.plan,
    required this.status,
    this.failureStep,
  });

  static Creation? fromJson(Object? json) => switch (json) {
    {
      'id': final String id,
      'name': final String name,
      'status': final String status,
    } =>
      Creation(
        id: id,
        name: name,
        plan: json['plan'] is String ? json['plan'] as String : 'standard',
        status: status,
        failureStep: json['failureStep'] is String
            ? json['failureStep'] as String
            : null,
      ),
    _ => null,
  };

  final String id;
  final String name;
  final String plan;

  /// `reserved`, `awaiting_billing`, `provisioning`, `failed` or `active`.
  final String status;

  /// Where a failed creation stopped (`project`, `group`, `data`).
  final String? failureStep;
}
