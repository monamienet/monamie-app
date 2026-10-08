import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

class MonAmieAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MonAmieAppBar({super.key});

  GoogleGroupsController get googleGroupsController => Get.find<GoogleGroupsController>();
  UserController get userController => Get.find<UserController>();

  Widget _buildProfileAvatar() {
    final avatarBase64 = userController.googleUser?.avatarBase64;

    if (avatarBase64 == null || avatarBase64.isEmpty) {
      return const CircleAvatar(
        backgroundColor: Colors.white24,
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    return ClipOval(
      child: Image.memory(
        base64Decode(avatarBase64),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: AppColors.appBarBottomGradient()),
      ),
      title: Obx(() => Text(
        'Grupo observado: ${googleGroupsController.observedGroup}', 
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
      )),
      centerTitle: true,
      elevation: 8,
      foregroundColor: Colors.white,
      actions: [
        PopupMenuButton(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Obx(() => _buildProfileAvatar()),
          ),
          onSelected: (value) {
            if (value == 'sair') {
              Get.find<AuthGoogleController>().logout();
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'sair',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Sair', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        )
      ],
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

