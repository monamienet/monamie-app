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

/// The central creation functions, behind a contract so the screens are
/// tested with a fake. Throws [CreationException] with a message.
abstract interface class CreationBackend {
  /// Whether [id] can be used: `null` when available, else why not.
  Future<String?> idProblem(String id);

  /// Creates the organization; returns its status after the call
  /// (`active` for Community, `awaiting_billing` for Standard, or
  /// `failed`).
  Future<String> create({
    required String id,
    required String name,
    required String themeId,
    required String plan,
  });

  /// The signed-in account's organizations still being created.
  Future<List<Creation>> mine();
}

class CreationException implements Exception {
  const CreationException(this.message);

  final String message;

  @override
  String toString() => message;
}
