import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:monamie_app/app/config/secrets.dart';
import 'package:monamie_app/app/data/models/gd_groups_google_model.dart';
import 'package:monamie_app/app/data/models/gdi_groups_model.dart';
import 'package:http/http.dart' as http;

class GoogleService {
  /// Busca os grupos GDI de um usuário Google.
  Future<GdiGroupsGoogle> getGdiGroupsGoogle(String token, String userEmail) async {
    try {
      DateTime now = DateTime.now();
      Uri url = Uri.https(
        Secrets.gdiGoogleHost, 
        Secrets.gdiUserGoogleGroupsPath, 
        {'email': userEmail}
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        //debugPrint(response.body);
        final jsonData = json.decode(response.body);
        //debugPrint(jsonData);
        List<GdiGroups> gdiGroups = (jsonData['groups'].toList() as List)
            .map((group) => GdiGroups.fromJson(group))
            .toList();
        //debugPrint("Grupos GDI obtidos com sucesso:");
        //gdiGroups.forEach((group) => debugPrint('(${group.name}, ${group.email})'));
        GdiGroupsGoogle gdiGroupsGoogle = GdiGroupsGoogle(now, gdiGroups);
        return gdiGroupsGoogle;
      } else {
        throw Exception('Falha ao buscar grupos GDI: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Erro ao obter grupos GDI: $e");
      return GdiGroupsGoogle(DateTime.now(), []);
    }
  }

  /// Busca todos os membros de um grupo Google.
  /// 
  /// Retorna a lista bruta de membros (Map) conforme retornado pela API.
  /// Cada membro possui: id, email, role, type (USER ou GROUP), status.
  Future<List<Map<String, dynamic>>> getGroupEntities(String token, String groupEmail) async {
    try {
      Uri url = Uri.https(Secrets.gdiGoogleHost, Secrets.gdiGroupMembers, {'email': groupEmail});

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        //debugPrint('\n\n${response.body}\n\n');
        final jsonData = json.decode(response.body);
        //debugPrint("Membros do grupo $groupEmail obtidos com sucesso:");
        final List<dynamic> members = jsonData['members'] as List;
        return members.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Falha ao buscar membros do grupo: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Erro ao obter membros do grupo $groupEmail: $e");
      return [];
    }
  }
}