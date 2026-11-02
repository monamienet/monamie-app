import 'package:cloud_functions/cloud_functions.dart';
import 'package:monamie_app/data/services/firebase/central_firebase.dart';
import 'package:monamie_app/data/services/firebase/current_organization_firebase.dart';

/// A callable function that refused or failed, as the server said it:
/// [code] is the `FirebaseFunctionsException` code (`invalid-argument`,
/// `permission-denied`, `unavailable`...) and [message] the server's own
/// words, when it sent any.
///
/// Repositories read it instead of the plugin's exception, so they never
/// import `cloud_functions`.
class FunctionsFailure implements Exception {
  const FunctionsFailure(this.code, this.message);

  final String code;
  final String? message;

  @override
  String toString() => 'FunctionsFailure($code: $message)';
}

/// Calls the callable Cloud Functions of one Firebase project. It holds no
/// state: [call] returns the function's data or throws a
/// [FunctionsFailure] (any other error passes through as it came).
///
/// Its two subclasses name the project, so `provider` tells them apart.
abstract class FunctionsService {
  const FunctionsService();

  /// The project's functions, read at each call.
  FirebaseFunctions get _functions;

  /// Calls function [name] with [data]; returns what it returned.
  Future<Object?> call(
    String name,
    Map<String, Object?> data, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      final result = await _functions
          .httpsCallable(name, options: HttpsCallableOptions(timeout: timeout))
          .call<Object?>(data);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      throw FunctionsFailure(e.code, e.message);
    }
  }
}

/// The central MonAmie project's functions (groups, invites,
/// administrators, creation, account deletion), called with the MonAmie
/// (central) session.
class CentralFunctionsService extends FunctionsService {
  const CentralFunctionsService();

  @override
  FirebaseFunctions get _functions => CentralFirebase.functions;
}

/// The bound organization's own functions (`setBranding`). The project is
/// resolved at each call, since the bound organization changes at runtime.
class OrganizationFunctionsService extends FunctionsService {
  const OrganizationFunctionsService();

  @override
  FirebaseFunctions get _functions =>
      CurrentOrganizationFirebase.instance.functions;
}
