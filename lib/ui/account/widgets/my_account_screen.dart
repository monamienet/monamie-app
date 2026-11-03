import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/themes/monamie_brand.dart';

import 'package:monamie_app/ui/account/view_models/my_account_view_model.dart';

/// *Minha conta*: the signed-in account and its deletion. A member (an
/// administrator included) leaves the organization at once; the owner
/// (*titular*) deletes it with the account. Either way there are 30 days to
/// cancel.
class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({
    super.key,
    required this.controller,
    required this.email,
    required this.organizationName,
  });

  final MyAccountViewModel controller;
  final String email;
  final String organizationName;

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  MyAccountViewModel get controller => widget.controller;
  String get email => widget.email;
  String get organizationName => widget.organizationName;

  @override
  void initState() {
    super.initState();
    controller.loadOwnership.execute();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deleteAt = DateTime.now().add(const Duration(days: 30));
    return Scaffold(
      backgroundColor: MonAmieBrand.cream,
      appBar: AppBar(
        backgroundColor: MonAmieBrand.cream,
        foregroundColor: MonAmieBrand.navy,
        elevation: 0,
        title: Text(
          l10n.myAccountTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: MonAmieBrand.navy,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              email,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MonAmieBrand.navy,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.myAccountDeleteHeading,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: MonAmieBrand.navy,
              ),
            ),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: Listenable.merge([
                controller,
                controller.loadOwnership,
              ]),
              builder: (context, _) {
                final owner = controller.state.isOwner;
                if (owner == null) {
                  return controller.loadOwnership.running
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: controller.loadOwnership.execute,
                            child: Text(l10n.commonTryAgain),
                          ),
                        );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final line in [
                      if (owner)
                        l10n.myAccountOwnerLeaves(organizationName)
                      else
                        l10n.myAccountMemberLeaves(organizationName),
                      l10n.myAccountEraseOn(deleteAt),
                      l10n.myAccountUndo,
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          line,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: MonAmieBrand.mutedInk,
                          ),
                        ),
                      ),
                    if (owner) ..._confirmation(l10n),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final error = controller.state.errorMessage;
                return error.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          error,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      );
              },
            ),
            ListenableBuilder(
              listenable: Listenable.merge([
                controller,
                controller.deleteAccount,
              ]),
              builder: (context, _) {
                final deleting = controller.deleteAccount.running;
                return SizedBox(
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onPressed: controller.canDelete
                        ? controller.deleteAccount.execute
                        : null,
                    child: deleting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            controller.state.isOwner == true
                                ? l10n.myAccountDeleteWithOrganization
                                : l10n.myAccountDelete,
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _confirmation(AppLocalizations l10n) => [
    const SizedBox(height: 12),
    Text(
      l10n.myAccountConfirmPrompt(controller.organizationId),
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: MonAmieBrand.navy,
      ),
    ),
    const SizedBox(height: 8),
    TextField(
      autocorrect: false,
      enableSuggestions: false,
      onChanged: controller.setConfirmation,
      decoration: InputDecoration(
        hintText: controller.organizationId,
        hintStyle: TextStyle(
          color: MonAmieBrand.mutedInk.withValues(alpha: 0.45),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  ];
}
