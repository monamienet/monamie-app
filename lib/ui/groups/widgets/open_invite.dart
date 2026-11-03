import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';

/// What *Convidar pessoas* opens with: the groups screen's controller and
/// the group to preselect.
typedef InviteRequest = ({GroupsViewModel groups, String? groupId});

/// Opens *Convidar pessoas* for the organization's groups (preselecting
/// [groupId]); completes after the groups are reloaded.
Future<void> openInvite(
  BuildContext context,
  GroupsViewModel controller, {
  String? groupId,
}) async {
  final InviteRequest request = (groups: controller, groupId: groupId);
  await context.push<void>(Routes.invite, extra: request);
  await controller.load.execute();
}
