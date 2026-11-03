import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/failure_text.dart';
import 'package:monamie_app/utils/failure.dart';
import 'package:monamie_app/utils/user_notice.dart';

const _signInTitle = 'Erro de Login';
const _switchTitle = 'Trocar de organização';

/// Every [Failure] case, with the pt-BR message and title the app showed
/// before failures became data (the strings the repositories, use cases and
/// view models wrote themselves until then).
final List<(String, Failure, String, String?)> _failureCases = [
  // ConnectionFailure, one per FailedAction.
  (
    'connection: conclude',
    const Failure.connection(FailedAction.conclude),
    'Não foi possível concluir agora. Verifique a conexão e tente de novo.',
    null,
  ),
  (
    'connection: delete',
    const Failure.connection(FailedAction.delete),
    'Não foi possível excluir agora. Verifique a conexão e tente de novo.',
    null,
  ),
  (
    'connection: cancel',
    const Failure.connection(FailedAction.cancel),
    'Não foi possível cancelar agora. Verifique a conexão e tente de novo.',
    null,
  ),
  (
    'connection: create',
    const Failure.connection(FailedAction.create),
    'Não foi possível criar agora. Verifique a conexão e tente de novo.',
    null,
  ),
  (
    'connection: send',
    const Failure.connection(FailedAction.send),
    'Não foi possível enviar agora. Verifique a conexão e tente de novo.',
    null,
  ),
  (
    'connection: accept',
    const Failure.connection(FailedAction.accept),
    'Não foi possível aceitar agora. Verifique a conexão e tente de novo.',
    null,
  ),
  (
    'connection: save',
    const Failure.connection(FailedAction.save),
    'Não foi possível salvar agora. Verifique a conexão e tente de novo.',
    null,
  ),
  (
    'connection: switchOrganization',
    const Failure.connection(FailedAction.switchOrganization),
    'Não foi possível trocar agora. Verifique a conexão e tente de novo.',
    _switchTitle,
  ),
  (
    'connection: loadAccount',
    const Failure.connection(FailedAction.loadAccount),
    'Não foi possível carregar sua conta. Verifique a conexão e tente de '
        'novo.',
    null,
  ),
  // LoadFailure, one per LoadTarget.
  (
    'load: administrators',
    const Failure.load(LoadTarget.administrators),
    'Não foi possível carregar os administradores.',
    null,
  ),
  (
    'load: invites',
    const Failure.load(LoadTarget.invites),
    'Não foi possível carregar os convites.',
    null,
  ),
  (
    'load: groups',
    const Failure.load(LoadTarget.groups),
    'Não foi possível carregar os grupos.',
    null,
  ),
  (
    'load: themes',
    const Failure.load(LoadTarget.themes),
    'Não foi possível carregar os temas.',
    null,
  ),
  (
    'load: creations',
    const Failure.load(LoadTarget.creations),
    'Não foi possível carregar as organizações em criação.',
    null,
  ),
  (
    'load: accountDeletion',
    const Failure.load(LoadTarget.accountDeletion),
    'Não foi possível ler a exclusão da conta.',
    null,
  ),
  (
    'load: organizationIdCheck',
    const Failure.load(LoadTarget.organizationIdCheck),
    'Não foi possível verificar agora.',
    null,
  ),
  (
    'serverRefusal',
    const Failure.serverRefusal('Já existe o grupo Equipe Mar.'),
    'Já existe o grupo Equipe Mar.',
    null,
  ),
  // UnexplainedRefusal, one per RefusedAction.
  (
    'unexplainedRefusal: conclude',
    const Failure.unexplainedRefusal(RefusedAction.conclude),
    'Não foi possível concluir.',
    null,
  ),
  (
    'unexplainedRefusal: any',
    const Failure.unexplainedRefusal(RefusedAction.any),
    'Não foi possível agora.',
    null,
  ),
  (
    'unexplainedRefusal: create',
    const Failure.unexplainedRefusal(RefusedAction.create),
    'Não foi possível criar.',
    null,
  ),
  (
    'unexplainedRefusal: save',
    const Failure.unexplainedRefusal(RefusedAction.save),
    'Não foi possível salvar.',
    null,
  ),
  (
    'unexpectedResponse',
    const Failure.unexpectedResponse(),
    'Resposta inesperada do servidor.',
    null,
  ),
  (
    'unexpectedResponse: creating a group',
    const Failure.unexpectedResponse(creatingGroup: true),
    'Resposta inesperada ao criar o grupo.',
    null,
  ),
  // OrganizationIdFailure, one per OrganizationIdProblem.
  (
    'organizationId: tooShort',
    const Failure.organizationId(OrganizationIdProblem.tooShort),
    'Mínimo 3 letras',
    null,
  ),
  (
    'organizationId: notPlainLowercase',
    const Failure.organizationId(OrganizationIdProblem.notPlainLowercase),
    'Use só letras minúsculas, sem acentos nem espaços.',
    null,
  ),
  (
    'organizationId: tooLong',
    const Failure.organizationId(OrganizationIdProblem.tooLong),
    'Use no máximo 20 letras.',
    null,
  ),
  (
    'organizationId: tooLong with another maximum',
    const Failure.organizationId(OrganizationIdProblem.tooLong, maxLength: 12),
    'Use no máximo 12 letras.',
    null,
  ),
  (
    'organizationId: reserved',
    const Failure.organizationId(OrganizationIdProblem.reserved),
    'Esse identificador é reservado.',
    null,
  ),
  (
    'organizationId: unusable',
    const Failure.organizationId(OrganizationIdProblem.unusable),
    'Esse identificador não pode ser usado.',
    null,
  ),
  (
    'groupNameTooShort',
    const Failure.groupNameTooShort(),
    'Use pelo menos 2 letras.',
    null,
  ),
  (
    'groupNameTooLong',
    const Failure.groupNameTooLong(),
    'Use no máximo 40 caracteres.',
    null,
  ),
  (
    'groupNameTaken',
    const Failure.groupNameTaken('Equipe Léste'),
    'Já existe o grupo Equipe Léste.',
    null,
  ),
  (
    'noRoleChosen',
    const Failure.noRoleChosen(),
    'Marque pelo menos uma opção.',
    null,
  ),
  (
    'invalidEmail',
    const Failure.invalidEmail(),
    'Digite um e-mail válido.',
    null,
  ),
  (
    'emailAlreadyListed',
    const Failure.emailAlreadyListed('ana@x.com'),
    'ana@x.com já está na lista.',
    null,
  ),
  (
    'logoTooLarge',
    const Failure.logoTooLarge(12),
    'O arquivo tem 12 MB. Envie um de até 10 MB.',
    null,
  ),
  (
    'logoUnreadable',
    const Failure.logoUnreadable(),
    'Não deu para abrir este arquivo. Envie em PNG, JPEG, WebP ou SVG.',
    null,
  ),
  (
    'logoNotConverted',
    const Failure.logoNotConverted(),
    'Não deu para gerar o PNG do logo.',
    null,
  ),
  (
    'logoNotOpened',
    const Failure.logoNotOpened(),
    'Não deu para abrir este arquivo.',
    null,
  ),
  // EntryFailure, one per EntryStage.
  (
    'entry: enter',
    const Failure.entry(EntryStage.enter, 'Exception: sem rede'),
    'Não foi possível entrar agora: Exception: sem rede',
    _signInTitle,
  ),
  (
    'entry: check',
    const Failure.entry(EntryStage.check, 'Exception: sem rede'),
    'Não foi possível verificar agora: Exception: sem rede',
    _signInTitle,
  ),
  (
    'entry: unexpected',
    const Failure.entry(EntryStage.unexpected, 'Exception: sem rede'),
    'Ocorreu um erro inesperado: Exception: sem rede',
    _signInTitle,
  ),
  (
    'entry: loadData',
    const Failure.entry(EntryStage.loadData, 'Exception: sem rede'),
    'Ocorreu um erro ao carregar seus dados: Exception: sem rede',
    _signInTitle,
  ),
  (
    'organizationEntry',
    const Failure.organizationEntry('Rota Sul', 'Exception: sem rede'),
    'Não foi possível entrar em Rota Sul: Exception: sem rede',
    _signInTitle,
  ),
  (
    'googleAuth',
    const Failure.googleAuth(),
    'Falha ao autenticar o usuário. Verifique sua conta Google e tente '
        'novamente.',
    _signInTitle,
  ),
  (
    'googleRenewal',
    const Failure.googleRenewal(),
    'Não foi possível renovar o acesso com o Google. Tente de novo.',
    _switchTitle,
  ),
  (
    'signOut',
    const Failure.signOut('Exception: falha de rede'),
    'Não foi possível encerrar a sessão. Tente novamente.\n'
        'Erro: Exception: falha de rede',
    'Erro ao sair',
  ),
  (
    'accessLost',
    const Failure.accessLost('Rota Sul'),
    'Sua conta não tem mais acesso à Rota Sul.',
    null,
  ),
  (
    'removedFromOrganization: named',
    const Failure.removedFromOrganization('Rota Sul'),
    'Você não faz mais parte da Rota Sul.',
    null,
  ),
  (
    'removedFromOrganization: unnamed',
    const Failure.removedFromOrganization(null),
    'Você não faz mais parte desta organização.',
    null,
  ),
  (
    'sharingNotAllowed',
    const Failure.sharingNotAllowed(),
    'Você não está em campo em nenhum grupo. Peça a um administrador para '
        'liberar o compartilhamento da sua localização.',
    'Compartilhamento não autorizado',
  ),
  (
    'sharingNotChanged',
    const Failure.sharingNotChanged(),
    'Não foi possível alterar o compartilhamento agora. Tente de novo.',
    'Compartilhamento',
  ),
];

/// Every [UserNotice] case other than [FailureNotice], with the pt-BR
/// message and title the app showed before notices became data.
const List<(String, UserNotice, String, String)> _noticeCases = [
  (
    'waitingForGps',
    UserNotice.waitingForGps(),
    'O monitoramento foi iniciado, mas a sua posição inicial ainda está '
        'sendo obtida pelos satélites.',
    'Aguardando sinal de GPS',
  ),
  (
    'trackingAtRisk',
    UserNotice.trackingAtRisk(),
    'O aparelho está restringindo o MonAmie em segundo plano. O rastreamento '
        'vai parar quando você sair do aplicativo.',
    'Rastreamento em risco',
  ),
  (
    'trackingStopUnconfirmed',
    UserNotice.trackingStopUnconfirmed(),
    'Não foi possível confirmar o encerramento do rastreamento. Ele será '
        'encerrado automaticamente em instantes.',
    'Rastreamento',
  ),
  (
    'backgroundStillRestricted',
    UserNotice.backgroundStillRestricted(),
    "A alteração não foi aplicada. Toque em 'Permitir uso em segundo "
        "plano' e, se o interruptor já estiver ativado, desative-o e "
        'ative-o novamente.',
    'Uso em segundo plano ainda restrito',
  ),
];

/// The kind of [failure] (its case and, for the enum-driven cases, the
/// enum value), so the coverage check below can tell the cases apart.
String _kindOf(Failure failure) => switch (failure) {
  ConnectionFailure(:final action) => 'connection.$action',
  LoadFailure(:final target) => 'load.$target',
  UnexplainedRefusal(:final action) => 'unexplainedRefusal.$action',
  OrganizationIdFailure(:final problem) => 'organizationId.$problem',
  EntryFailure(:final stage) => 'entry.$stage',
  UnexpectedResponse(:final creatingGroup) =>
    'unexpectedResponse.$creatingGroup',
  RemovedFromOrganization(:final organizationName) =>
    'removedFromOrganization.${organizationName == null}',
  _ => '${failure.runtimeType}',
};

void main() {
  final pt = lookupAppLocalizations(const Locale('pt'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('FailureText (pt-BR) - Unit Test Suite', () {
    for (final (label, failure, message, title) in _failureCases) {
      test('Happy Path: $label reads as before', () {
        // 1. Arrange
        final input = failure;

        // 2. Act
        final shown = (input.message(pt), input.title(pt));

        // 3. Assert
        expect(shown, (message, title));
      });
    }

    test('Edge Case: the table covers every case of Failure and of its '
        'enums', () {
      // 1. Arrange
      final expectedKinds = {
        ...{for (final a in FailedAction.values) 'connection.$a'},
        ...{for (final t in LoadTarget.values) 'load.$t'},
        ...{for (final a in RefusedAction.values) 'unexplainedRefusal.$a'},
        ...{for (final p in OrganizationIdProblem.values) 'organizationId.$p'},
        ...{for (final s in EntryStage.values) 'entry.$s'},
        'unexpectedResponse.true',
        'unexpectedResponse.false',
        'removedFromOrganization.true',
        'removedFromOrganization.false',
        'ServerRefusal',
        'GroupNameTooShort',
        'GroupNameTooLong',
        'GroupNameTaken',
        'NoRoleChosen',
        'InvalidEmail',
        'EmailAlreadyListed',
        'LogoTooLarge',
        'LogoUnreadable',
        'LogoNotConverted',
        'LogoNotOpened',
        'OrganizationEntryFailure',
        'GoogleAuthFailure',
        'GoogleRenewalFailure',
        'SignOutFailure',
        'AccessLost',
        'SharingNotAllowed',
        'SharingNotChanged',
      };

      // 2. Act
      final kinds = {
        for (final (_, failure, _, _) in _failureCases) _kindOf(failure),
      };

      // 3. Assert
      expect(kinds, expectedKinds);
    });
  });

  group('FailureText (English) - Unit Test Suite', () {
    for (final (label, failure, ptMessage, ptTitle) in _failureCases) {
      if (failure is ServerRefusal) continue;
      test('Happy Path: $label has its own English words', () {
        // 1. Arrange
        final input = failure;

        // 2. Act
        final message = input.message(en);
        final title = input.title(en);

        // 3. Assert
        expect(message, isNotEmpty);
        expect(message, isNot(ptMessage));
        if (ptTitle == null) {
          expect(title, isNull);
        } else {
          expect(title, allOf(isNotNull, isNotEmpty, isNot(ptTitle)));
        }
      });
    }

    test('Edge Case: a ServerRefusal shows the server words in every '
        'language', () {
      // 1. Arrange
      const failure = ServerRefusal('Já existe o grupo Equipe Mar.');

      // 2. Act
      final shown = [
        failure.message(pt),
        failure.message(en),
        failure.title(en),
      ];

      // 3. Assert
      expect(shown, [
        'Já existe o grupo Equipe Mar.',
        failure.serverMessage,
        null,
      ]);
    });

    test('Edge Case: the English text keeps the values it quotes', () {
      // 1. Arrange
      const failures = [
        Failure.groupNameTaken('Equipe Léste'),
        Failure.emailAlreadyListed('ana@x.com'),
        Failure.organizationEntry('Rota Sul', 'Exception: sem rede'),
        Failure.signOut('Exception: falha de rede'),
      ];

      // 2. Act
      final messages = [for (final f in failures) f.message(en)];

      // 3. Assert
      expect(messages[0], contains('Equipe Léste'));
      expect(messages[1], contains('ana@x.com'));
      expect(
        messages[2],
        allOf(contains('Rota Sul'), contains('Exception: sem rede')),
      );
      expect(messages[3], contains('Exception: falha de rede'));
    });
  });

  group('UserNoticeText - Unit Test Suite', () {
    for (final (label, notice, message, title) in _noticeCases) {
      test('Happy Path: $label reads as before in pt-BR', () {
        // 1. Arrange
        final input = notice;

        // 2. Act
        final shown = (input.message(pt), input.title(pt));

        // 3. Assert
        expect(shown, (message, title));
      });

      test('Happy Path: $label has its own English words', () {
        // 1. Arrange
        final input = notice;

        // 2. Act
        final message = input.message(en);
        final title = input.title(en);

        // 3. Assert
        expect(message, allOf(isNotEmpty, isNot(_ptMessageOf(notice))));
        expect(title, allOf(isNotNull, isNotEmpty, isNot(_ptTitleOf(notice))));
      });
    }

    for (final (label, failure, message, title) in _failureCases) {
      test('Happy Path: a failure notice of $label reads as its failure', () {
        // 1. Arrange
        final notice = UserNotice.failure(failure);

        // 2. Act
        final shown = (notice.message(pt), notice.title(pt));

        // 3. Assert
        expect(shown, (message, title));
      });
    }

    test('Edge Case: a failure notice in English reads as its failure in '
        'English', () {
      // 1. Arrange
      const failure = Failure.googleAuth();
      const notice = UserNotice.failure(failure);

      // 2. Act
      final shown = (notice.message(en), notice.title(en));

      // 3. Assert
      expect(shown, (failure.message(en), failure.title(en)));
    });

    test('Edge Case: the table covers every other case of UserNotice', () {
      // 1. Arrange
      const expected = {
        WaitingForGpsNotice,
        TrackingAtRiskNotice,
        TrackingStopUnconfirmedNotice,
        BackgroundStillRestrictedNotice,
      };

      // 2. Act
      final kinds = {
        for (final (_, notice, _, _) in _noticeCases) notice.runtimeType,
      };

      // 3. Assert
      expect(kinds, expected);
    });
  });
}

String _ptMessageOf(UserNotice notice) =>
    _noticeCases.firstWhere((c) => c.$2 == notice).$3;

String _ptTitleOf(UserNotice notice) =>
    _noticeCases.firstWhere((c) => c.$2 == notice).$4;
