# Um app, vários parceiros

A MonAmie publica um único app, `org.monamienet.app` ("MonAmie"). Cada parceiro (uma organização cliente) mantém o próprio projeto Firebase, os próprios dados e a própria cobrança. O app descobre a qual parceiro o usuário pertence **depois** do login, e só então mostra o nome, as cores e o logo do parceiro.

Este guia explica como isso funciona, o que a MonAmie configura uma única vez e como cadastrar um parceiro sem publicar uma nova versão do app. As decisões por trás disso estão na issue #28.

## 1. Parceiro não é usuário

| | Parceiro | Usuário |
|---|---|---|
| O que é | uma organização cliente | uma pessoa |
| Exemplo | AquariusTur | Maria |
| O que tem | marca, projeto Firebase `monamienet-<id>`, grupo raiz `<id>00@monamienet.org` | uma conta Google |
| Faz login? | não | sim |

A conta Google não diz nada sobre o parceiro. A ponte são os **grupos**: cada parceiro tem um grupo raiz `<id>00@monamienet.org` e subgrupos `<id>01` … `<id>99`. Colocar o e-mail de uma pessoa num deles é o que a torna usuária daquele parceiro. Como o sufixo tem sempre 2 dígitos, o id do parceiro é o nome do grupo sem os 2 últimos caracteres: `aquariustur01@monamienet.org` → `aquariustur`.

## 2. O que acontece no login

1. **Login Google** no projeto central `monamienet-app`. A tela tem a marca MonAmie: ainda não se sabe o parceiro.
2. **`resolvePartners`** (função central) pede ao gateway os grupos do usuário, transforma os nomes em ids de parceiro, mantém só os marcados como ativos no registro central `partners/{id}` e devolve as opções do Firebase de cada parceiro.
3. O app lê o **`config/branding`** (público) de cada parceiro. Sem parceiro, o usuário vê "sua conta não está vinculada a nenhuma organização"; com um, o app entra nele; com vários, um seletor mostra o nome e o ícone de cada um.
4. **Ligação:** o projeto Firebase do parceiro (um app Firebase nomeado `partner-<id>`), o grupo raiz e a marca são ligados juntos. O app entra no projeto do parceiro com o mesmo ID token do Google (o parceiro aceita o cliente web central) e chama a `syncClaims` do parceiro, que decide o que o usuário pode ver, como antes.
5. **Lembrança:** a ligação fica salva no aparelho. As próximas aberturas já começam com a marca do parceiro, sem consultar o projeto central.

O app **esquece** o parceiro quando a pessoa sai, quando uma atualização de grupos não encontra mais nenhum grupo do parceiro, ou quando a `syncClaims` não devolve nenhum papel.

O ícone e o nome na tela inicial do celular, a ficha na Play e a splash nativa são sempre MonAmie: o Android os lê do pacote instalado.

## 3. Onde cada valor mora

| Tipo | Exemplos | Onde |
|---|---|---|
| Escolha do parceiro | nome (obrigatório); cores, logo, ícone (opcionais) | `config/branding` em `monamienet-<id>` |
| Escolha da MonAmie | parceiro ativo | `partners/{id}` em `monamienet-app` |
| Derivado por regra | `monamienet-<id>`, `<id>00@monamienet.org`, id a partir do nome do grupo | código |
| Buscado no build | `google-services.json` central | `android/app/google-services.json` (ignorado pelo git) |
| Buscado em tempo de execução | opções do Firebase do parceiro | `resolvePartners`, depois o aparelho |

Cada dado opcional que faltar usa o próprio plano B: sem cor principal → azul MonAmie `#315399`; sem fundo → branco; sem logo → o nome escrito na cor do parceiro; sem ícone → a inicial do nome num círculo.

## 4. Configuração única do projeto central (mantenedor)

1. Crie o projeto Firebase **`monamienet-app`** na conta de cobrança da MonAmie (plano Blaze, por causa das Functions). O id `app` é reservado: nenhum parceiro pode usá-lo.
2. Authentication → ative o provedor **Google**. Preencha a tela de consentimento OAuth como "MonAmie".
3. Registre o **app Android** `org.monamienet.app` com o SHA-1 da chave de upload, do Play App Signing e da chave de debug de cada desenvolvedor. Registre **um app web** e adicione `http://localhost:5000` e o domínio de hospedagem como origens JavaScript autorizadas do cliente OAuth web.
4. Ative o Firestore e publique o projeto central:
   ```sh
   cd central/functions && npm ci && cd ..
   firebase deploy --project monamienet-app --only functions,firestore
   ```
5. Conceda à conta de serviço da função (`<número do projeto>-compute@developer.gserviceaccount.com`) o papel customizado **`firebaseAppConfigReader`** (`firebase.clients.list`, `firebase.clients.get`) **só em cada projeto de parceiro** (passo 7 do cadastro). Ela lê as opções do Firebase dos parceiros e nada mais.
6. CI: vincule `firebaseAppConfigReader` à conta de configuração `wlif-monamie-app-config@ci-cd-management.iam.gserviceaccount.com` em `monamienet-app` e remova o vínculo dela em `monamienet-aquariustur` (o build agora só lê a config central).
7. Play Console: crie o app `org.monamienet.app`, envie o primeiro bundle manualmente, preencha a Segurança dos dados e a declaração de **localização em segundo plano** (revisada pelo Google), e dê acesso a ele à conta de serviço de publicação. Depois, despublique o `org.monamienet.aquariustur`.
8. Confira se o gateway de grupos aceita ID tokens do Firebase de `monamienet-app` (veja a issue #72).

## 5. Cadastro de um parceiro (sem nova versão do app)

Os passos 1 a 9 cuidam dos três obrigatórios: projeto, grupo raiz e nome. O passo 10 é o portão.

**Projeto Firebase do parceiro**
1. Crie `monamienet-<id>` na conta de cobrança do parceiro.
2. Ative o Firestore e o provedor de login Google; em **Allowed client IDs**, adicione o client id web central.
3. Registre o app Android `org.monamienet.app` **sem SHA-1** (o par pacote + SHA-1 só pode ter cliente OAuth num projeto: o central) e um app web. Adicione o domínio de hospedagem aos domínios autorizados.
4. Restrinja as API keys: a Android ao pacote + SHA-1, a de navegador aos domínios.
5. Publique as regras e a `syncClaims` (a partir da raiz do repositório):
   ```sh
   firebase deploy --project monamienet-<id> --only firestore:rules,functions
   ```

**Grupos e acesso**

6. Crie o grupo raiz `<id>00@monamienet.org` e os subgrupos `<id>01`, `<id>02`… com os usuários.
7. Conceda `firebaseAppConfigReader` à conta de serviço da função central **só neste projeto**.
8. Se o gateway de grupos mantiver uma lista de projetos aceitos, inclua `monamienet-<id>`.

**Marca e ativação**

9. Publique a marca a partir do formulário de onboarding (baixe o envio com `rclone` numa pasta temporária, veja o `AGENTS.md`):
   ```sh
   dart run tool/partner.dart publish <id> --name "<Nome>" \
     --primary '#RRGGBB' --secondary '#RRGGBB' \
     --logo <pasta>/logo-com-texto.svg --icon <pasta>/logo-sem-texto.svg
   ```
   Só `--name` é obrigatório; use `--dry-run` para conferir antes. Publicar de novo depois atualiza a marca para todos na próxima abertura do app.
10. Confira e ative (a ativação roda as mesmas conferências e recusa se alguma falhar):
    ```sh
    dart run tool/partner.dart check <id>
    dart run tool/partner.dart activate <id>
    ```
    `activate <id> --deactivate` impede novos logins no parceiro.

A ferramenta usa as contas do seu `firebase login` e `gcloud auth login`.

## 6. Build

- **Android:** `flutter build apk` (sem `--flavor`). O build busca o `google-services.json` central quando ele não existe; `REFRESH_FIREBASE_CONFIG=1` força a atualização.
- **Web:** `dart run tool/partner.dart web` grava `web/central/firebase.json` (opções do Firebase central e o client id do Google); depois, `flutter build web`. Veja `rodar-web-localmente.md`.
