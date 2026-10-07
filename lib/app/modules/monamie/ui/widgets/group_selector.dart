import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_model.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

class GroupSelector extends StatelessWidget {
  const GroupSelector({super.key});

  GoogleGroupsController get googleGroupsController => Get.find<GoogleGroupsController>();

  Widget _group(GoogleGroupModel group) {
    return ListTile(
      title: Text(
        group.name,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(group.email, style: TextStyle(color: Colors.white, fontSize: 13)),
          if (group.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              group.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white60, fontSize: 12),
            )
          ]
        ],
      ),
      isThreeLine: true,
      onTap: () {
        googleGroupsController.updateObservedUsers(group);
        Get.back();
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.darkBlue(),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppColors.darkBlue()),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grupos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    googleGroupsController.refreshGroups();
                  },
                  tooltip: 'Atualizar grupos',
                ),
              ],
            ),
          ),
          // Lista dos grupos carregados dinamicamente da API
          Obx(() {
            if (googleGroupsController.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              );
            }

            if (googleGroupsController.googleGroups.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      const Text('Nenhum grupo disponível', style: TextStyle(color: Colors.white)),
                      SizedBox(height: 6),
                      Text('${googleGroupsController.loadError}', style: TextStyle(color: Colors.white60))
                    ],
                  )),
              );
            }

            return Column(
              children: googleGroupsController.googleGroups.map((item) {
                return _group(item);
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

