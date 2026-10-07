import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

class HighlightedObservedUsersList extends StatelessWidget {
  const HighlightedObservedUsersList({super.key});

  GoogleGroupsController get googleGroupsCtrl => Get.find<GoogleGroupsController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final users = googleGroupsCtrl.highlightedObservedUsers;

      if (users.isEmpty) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: 108,
        left: 16,
        child: Material(
          color: AppColors.darkBlue().withAlpha(220),
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 200,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabeçalho
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.visibility, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Trajetórias (${users.length})',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  // Lista de usuários
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final member = users[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  member.name.isNotEmpty ? member.name : member.email,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.visibility_off,
                                    color: Colors.white60,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    googleGroupsCtrl.toggleHighlight(member);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}