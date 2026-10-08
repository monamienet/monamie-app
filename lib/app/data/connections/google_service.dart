import 'dart:convert';

import 'package:monamie_app/app/config/secrets.dart';
import 'package:monamie_app/app/data/connections/groups_api_exception.dart';
import 'package:monamie_app/app/data/models/gd_groups_google_model.dart';
import 'package:monamie_app/app/data/models/gdi_groups_model.dart';
import 'package:http/http.dart' as http;

class GoogleService {
  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Busca os grupos dos quais um usuário Google participa (`GET /groups`).
  ///
  /// Retorna a lista bruta conforme a Directory API (id, email, name,
  /// description, directMembersCount...).
  /// Lança [GroupsApiException] se o gateway não responder 200.
  Future<List<Map<String, dynamic>>> getUserGroups(String token, String userEmail) async {
    final url = Uri.https(
      Secrets.gdiGoogleHost,
      Secrets.gdiUserGoogleGroupsPath,
      {'email': userEmail},
    );

    final response = await http.get(url, headers: _headers(token));
    if (response.statusCode != 200) {
      throw GroupsApiException(userEmail, response.statusCode, response.body);
    }

    final jsonData = json.decode(response.body);
    final List<dynamic> groups = (jsonData['groups'] as List?) ?? [];
    return groups.cast<Map<String, dynamic>>();
  }

  /// Busca os grupos GDI de um usuário Google.
  /// Lança [GroupsApiException] em caso de falha.
  Future<GdiGroupsGoogle> getGdiGroupsGoogle(String token, String userEmail) async {
    final groups = await getUserGroups(token, userEmail);
    return GdiGroupsGoogle(
      DateTime.now(),
      groups.map((group) => GdiGroups.fromJson(group)).toList(),
    );
  }

  /// Busca todos os membros de um grupo Google (`GET /members`).
  ///
  /// Retorna a lista bruta de membros (Map) conforme retornado pela API.
  /// Cada membro possui: id, email, role, type (USER ou GROUP), status.
  /// Lança [GroupsApiException] se o gateway não responder 200.
  Future<List<Map<String, dynamic>>> getGroupEntities(String token, String groupEmail) async {
    final url = Uri.https(Secrets.gdiGoogleHost, Secrets.gdiGroupMembers, {'email': groupEmail});

    final response = await http.get(url, headers: _headers(token));
    if (response.statusCode != 200) {
      throw GroupsApiException(groupEmail, response.statusCode, response.body);
    }

    final jsonData = json.decode(response.body);
    final List<dynamic> members = (jsonData['members'] as List?) ?? [];
    return members.cast<Map<String, dynamic>>();
  }
}