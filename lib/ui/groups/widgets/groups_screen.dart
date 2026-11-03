import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/failure_text.dart';
import 'package:go_router/go_router.dart';

import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/ui/core/ui/admin_ui.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';

const _ink = AdminColors.ink;
const _muted = AdminColors.muted;
const _line = AdminColors.line;

/// *Grupos*: every group of the organization for an administrator, or the
/// groups a maintainer (*Gestor do grupo*) maintains.
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key, required this.controller});

  final GroupsViewModel controller;

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  GroupsViewModel get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.load.execute();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: adminAppBar(AppLocalizations.of(context).groupsTitle),
    body: Column(
      children: [
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge([controller, controller.load]),
            builder: (context, _) {
              final state = controller.state;
              final failure = state.failure?.message(
                AppLocalizations.of(context),
              );
              if (controller.load.running && state.groups.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return RefreshIndicator(
                onRefresh: controller.load.execute,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                  children: [
                    if (failure != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: adminErrorText(failure),
                      ),
                    if (state.groups.isEmpty && failure == null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        child: Text(
                          controller.isAdmin
                              ? AppLocalizations.of(context).groupsEmptyAdmin
                              : AppLocalizations.of(
                                  context,
                                ).groupsEmptyMaintainer,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: _muted,
                          ),
                        ),
                      ),
                    for (final group in state.groups) _groupRow(group),
                  ],
                ),
              );
            },
          ),
        ),
        // Only administrators create groups.
        if (controller.isAdmin)
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _line)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 32),
              child: adminPrimaryButton(
                label: AppLocalizations.of(context).createGroupButton,
                busy: false,
                busyLabel: '',
                icon: Icons.add,
                onPressed: () =>
                    context.push<void>(Routes.newGroup, extra: controller),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _groupRow(Group group) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () => context.push<void>(Routes.group(group.id), extra: controller),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _initialTile(group.name, size: 40, fontSize: 15),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).peopleCount(group.people.length),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, size: 20, color: _muted),
          ],
        ),
      ),
    ),
  );
}

Widget _initialTile(String name, {double size = 44, double? fontSize}) {
  // A name such as "Grupo Norte" shows the initial of "Norte".
  final initial = name.replaceFirst(RegExp(r'^Grupo\s+'), '');
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: adminPalette.light,
      borderRadius: BorderRadius.circular(size == 40 ? 12 : size * 0.3),
    ),
    child: Text(
      initial.isEmpty ? '?' : initial[0].toUpperCase(),
      style: TextStyle(
        fontSize: fontSize ?? size * 0.42,
        fontWeight: FontWeight.w800,
        color: adminPalette.dark,
      ),
    ),
  );
}
