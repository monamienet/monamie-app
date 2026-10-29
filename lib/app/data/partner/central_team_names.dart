import 'package:cloud_functions/cloud_functions.dart';
import 'package:monamie_app/app/data/firebase/central_firebase.dart';

/// The display names of the teams the signed-in person sees in [partnerId],
/// by team key (`rotasul01`), from the central `teamNames` function: the
/// only place that reads the team groups themselves.
Future<Map<String, String>> fetchTeamNames(String partnerId) async {
  final result = await CentralFirebase.functions
      .httpsCallable(
        'teamNames',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      )
      .call<Object?>({'partnerId': partnerId});
  return parseTeamNames(result.data);
}

/// Reads the `teamNames` response `{names: {<teamKey>: name}}`. Keys are
/// lowercased and names trimmed; an entry that is not a non-blank string
/// is skipped, so the team falls back to "Equipe NN".
Map<String, String> parseTeamNames(Object? data) {
  final names = data is Map ? data['names'] : null;
  if (names is! Map) return const {};
  return {
    for (final MapEntry(:key, :value) in names.entries)
      if (key is String && value is String && value.trim().isNotEmpty)
        key.trim().toLowerCase(): value.trim(),
  };
}
