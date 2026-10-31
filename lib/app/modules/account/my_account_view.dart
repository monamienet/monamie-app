import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/organization/monamie_brand.dart';

import 'account_deletion.dart';
import 'my_account_controller.dart';

/// *Minha conta*: the signed-in account and its deletion. A member (an
/// administrator included) leaves the organization at once; the owner
/// (*titular*) deletes it with the account. Either way there are 30 days to
/// cancel.
class MyAccountView extends StatelessWidget {
  const MyAccountView({
    super.key,
    required this.controller,
    required this.email,
    required this.organizationName,
  });

  final MyAccountController controller;
  final String email;
  final String organizationName;

  @override
  Widget build(BuildContext context) {
    final deleteAt = longDate(DateTime.now().add(const Duration(days: 30)));
    return Scaffold(
      backgroundColor: MonAmieBrand.cream,
      appBar: AppBar(
        backgroundColor: MonAmieBrand.cream,
        foregroundColor: MonAmieBrand.navy,
        elevation: 0,
        title: const Text(
          'Minha conta',
          style: TextStyle(
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
            const Text(
              'Excluir conta',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: MonAmieBrand.navy,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final owner = controller.isOwner.value;
              if (owner == null) {
                return controller.isCheckingOwner.value
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: controller.loadOwnership,
                          child: const Text('Tentar de novo'),
                        ),
                      );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final line in [
                    if (owner)
                      'Você é titular da $organizationName, então a organização '
                          'inteira é excluída junto com a sua conta.'
                    else
                      'Você sai da $organizationName agora e deixa de aparecer no '
                          'mapa.',
                    'Em $deleteAt apagamos de vez sua conta e seus dados no '
                        'MonAmie.',
                    'Até lá, é só entrar de novo e cancelar a exclusão.',
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
                  if (owner) ..._confirmation(),
                ],
              );
            }),
            const SizedBox(height: 24),
            Obx(() {
              final error = controller.errorMessage.value;
              return error.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        error,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    );
            }),
            Obx(() {
              final deleting = controller.isDeleting.value;
              // Read here so the button follows the typing.
              controller.confirmation.value;
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
                      ? controller.deleteAccount
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
                          controller.isOwner.value == true
                              ? 'Excluir conta e organização'
                              : 'Excluir conta',
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<Widget> _confirmation() => [
    const SizedBox(height: 12),
    Text(
      'Para confirmar, digite ${controller.organizationId}',
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: MonAmieBrand.navy,
      ),
    ),
    const SizedBox(height: 8),
    TextField(
      autocorrect: false,
      enableSuggestions: false,
      onChanged: (value) => controller.confirmation.value = value,
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
