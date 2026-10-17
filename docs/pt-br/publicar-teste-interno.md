# Publicação no teste interno

Este guia leva um app do zero até a faixa de **teste interno** do Google Play e mostra como cada nova
versão é publicada depois disso. Quase tudo é feito uma única vez. **A cada nova versão, o único passo
manual é fazer o merge de uma PR na `main`**: o resto é automático. Como a automação funciona está em
[entendendo-o-ci.md](entendendo-o-ci.md).

## Visão geral

Os passos são identificados por grupo, de acordo com a frequência com que são feitos:

| Grupo | Frequência | Passos |
| :--- | :--- | :--- |
| **A** | Uma única vez para a empresa | A1 keystore · A2 a A4 base do CI no Google Cloud |
| **B** | Uma vez por máquina ou clone | B1 `key.properties` |
| **C** | Uma vez por app (cliente) | C1 a C4 Firebase · C5 a C7 primeiro envio, manual · C8 SHAs do Play · C9 a C12 CI do app |
| **D** | A cada nova versão | D1 merge da PR · D2 publicação automática ⚙️ |

| A cada nova versão | Antes do CI | Com o CI |
| :--- | :--- | :--- |
| Passos manuais | 5: atualizar o versionCode, gerar o bundle, enviar, preencher as notas e lançar | 1: fazer o merge da PR |

### Dependências entre os passos

```mermaid
flowchart LR
    nS((" "))
    nK((" "))
    nW((" "))
    nF1((" "))
    nF2((" "))
    nB((" "))
    nU((" "))
    nP((" "))
    nSA((" "))
    nI((" "))
    nCI((" "))
    nM((" "))
    nE((" "))

    nS -->|A1| nK
    nS -->|A2| nCI
    nS -->|A3| nW
    nW -->|A4| nCI
    nK -->|B1| nB
    nK -->|C1| nF1
    nS -->|C2| nF1
    nF1 -->|C3| nF2
    nF2 -->|C4| nB
    nS -->|C5| nU
    nB -->|C6| nU
    nU -->|C7| nP
    nP -->|C8| nE
    nS -->|C9| nSA
    nSA -.-> nI
    nP -.-> nI
    nSA -->|C10| nCI
    nI -->|C11| nCI
    nK -->|C12| nCI
    nCI -->|D1| nM
    nM -->|D2 ⚙️| nE

    %% uma vez para a empresa (roxo)
    linkStyle 0,1,2,3 stroke:#7b2d8e,stroke-width:3px
    %% uma vez por máquina (laranja)
    linkStyle 4 stroke:#e69f00,stroke-width:3px
    %% uma vez por app (azul)
    linkStyle 5,6,7,8,9,10,11,12,13,16,17,18 stroke:#0072b2,stroke-width:3px
    %% só dependência, sem trabalho (cinza)
    linkStyle 14,15 stroke:#999999,stroke-width:1px
    %% a cada versão: manual (verde) e automático (verde tracejado)
    linkStyle 19 stroke:#009e73,stroke-width:3px
    linkStyle 20 stroke:#009e73,stroke-width:3px,stroke-dasharray:6 4
```

**Como ler:**
- **Arestas** são os passos, e o rótulo é o ID do passo. **Nós** são instantes: o momento em que os passos
  seguintes podem começar.
- Um nó só é atingido quando **todas** as arestas que chegam nele terminaram.
- Arestas que saem do mesmo nó podem ser feitas **em paralelo**.
- Uma aresta **pontilhada fina, sem rótulo**, é só uma dependência, sem trabalho. Por exemplo, convidar a
  service account (C11) exige que ela já exista (C9) e que o app já esteja no Play (C7).
- Cores:
  - 🟣 uma vez para a empresa;
  - 🟠 uma vez por máquina;
  - 🔵 uma vez por app;
  - 🟢 a cada versão. A aresta **tracejada** (D2) é executada automaticamente pelo CI. D1 e D2 se repetem a cada versão.

## Valores usados

Os comandos deste guia usam as variáveis abaixo. Cole o bloco no terminal antes de começar:

```bash
# Empresa
GCP_PROJECT=ci-cd-management      # projeto do Google Cloud dedicado ao CI
GCP_PROJECT_NUMBER=787253151660   # gcloud projects describe $GCP_PROJECT --format='value(projectNumber)'
POOL=github-actions               # workload identity pool (A3)
PROVIDER=github                   # provider do GitHub (A4)
GITHUB_ORG_ID=336690459           # gh api orgs/monamienet --jq .id

# App
REPO=monamienet/monamie-app
FIREBASE_PROJECT=monamienet-aquariustur
SA_NAME=wlif-monamie-app-play     # service account do deploy (C9)
SA_EMAIL=$SA_NAME@$GCP_PROJECT.iam.gserviceaccount.com
```

Para outro app (cliente):
- troque os valores do grupo *App*;
- no workflow [`.github/workflows/deploy-play-internal.yml`](../../.github/workflows/deploy-play-internal.yml),
  atualize o `packageName` e o `service_account`.

---

## A. Uma única vez para a empresa

### A1. Gerar a keystore de upload

A keystore assina os bundles enviados ao Play e é a mesma para todos os apps da empresa. **Guarde um
backup fora da máquina:** sem ela, nenhum app recebe novas versões.

```bash
keytool -genkey -v \
  -keystore <CAMINHO>/upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias <ALIAS> \
  -dname "CN=MonAmieNet, O=MonAmieNet, C=BR" \
  -storepass '<SENHA>' -keypass '<SENHA>'
```

### A2. Ativar a API do Play no projeto de CI

Sem a API ativada, o Google recusa as chamadas de publicação feitas pelo CI.

```bash
gcloud services enable androidpublisher.googleapis.com --project=$GCP_PROJECT
```

### A3. Criar o workload identity pool

O pool agrupa as identidades externas (aqui, os workflows do GitHub) que o Google Cloud aceita. Ele serve
a todos os pipelines da organização.

```bash
gcloud iam workload-identity-pools create $POOL \
  --project=$GCP_PROJECT \
  --location=global \
  --display-name="GitHub Actions" \
  --description="GitHub Actions workflows of the monamienet organization"
```

### A4. Criar o provider do GitHub

O provider faz o pool confiar nos tokens do GitHub Actions, mas só nos da organização `monamienet`. A
condição usa o ID numérico porque, ao contrário do nome, ele nunca é reutilizado.

```bash
gcloud iam workload-identity-pools providers create-oidc $PROVIDER \
  --project=$GCP_PROJECT \
  --location=global \
  --workload-identity-pool=$POOL \
  --display-name="GitHub" \
  --issuer-uri="https://token.actions.githubusercontent.com/" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository_id=assertion.repository_id,attribute.repository_owner_id=assertion.repository_owner_id" \
  --attribute-condition="assertion.repository_owner_id=='$GITHUB_ORG_ID'"
```

**Conferir A2 a A4:**

```bash
gcloud services list --enabled --project=$GCP_PROJECT --filter="config.name=androidpublisher.googleapis.com"
gcloud iam workload-identity-pools providers describe $PROVIDER --workload-identity-pool=$POOL \
  --location=global --project=$GCP_PROJECT --format="yaml(state,attributeCondition)"
```

O resultado esperado é a API listada, `state: ACTIVE` e a condição com o ID da organização.

## B. Uma vez por máquina ou clone

### B1. Criar o `android/key.properties`

Esse arquivo diz ao Gradle onde está a keystore. Ele está no `.gitignore`, então cada máquina precisa do
seu. Ele só é necessário para builds release **locais**, como o primeiro envio (C6), porque o CI monta o
dele a partir dos secrets (C12).

```properties
storePassword=<SENHA>
keyPassword=<SENHA>
keyAlias=<ALIAS>
storeFile=<CAMINHO>/upload.jks
```

> **Fail-fast:** sem esse arquivo, ou com alguma propriedade vazia, todo build release falha com a mensagem
> `Release signing: ...`. Não há fallback para a chave debug, cujo bundle o Play rejeitaria. Builds debug
> (`flutter run`) não precisam da keystore.

## C. Uma vez por app (cliente)

São três frentes que podem andar em paralelo: Firebase (C1 a C4), primeiro envio (C5 a C8) e CI do app
(C9 a C12). O diagrama mostra o que depende do quê.

### C1. Obter os SHAs da chave de upload

```bash
keytool -list -v -keystore <CAMINHO>/upload.jks -alias <ALIAS> | grep -E "SHA1|SHA256"
```

### C2. Obter o ID do app Android no Firebase

```bash
firebase apps:list ANDROID --project $FIREBASE_PROJECT
APP_ID=<valor da coluna "App ID">
```

### C3. Registrar os SHAs no Firebase

O login com Google só funciona em apps cuja assinatura o Firebase conhece.

```bash
firebase apps:android:sha:create $APP_ID <SHA1> --project $FIREBASE_PROJECT
firebase apps:android:sha:create $APP_ID <SHA256> --project $FIREBASE_PROJECT
```

### C4. Atualizar o `google-services.json`

Depois de atualizar, faça o commit do arquivo, porque ele é versionado.

```bash
firebase apps:sdkconfig ANDROID $APP_ID --project $FIREBASE_PROJECT --out android/app/google-services.json
```

### C5. Criar a lista de testadores

No Play Console, crie uma lista de e-mails de testadores e associe-a à faixa de **teste interno**.

### C6. Gerar o primeiro bundle

O Play só aceita envios pela API depois que o app recebe o primeiro bundle pelo Play Console, então
**a primeira versão é manual**.

1. Em `pubspec.yaml`, defina `version: a.b.c+d`. `a.b.c` é o *versionName*, que aparece na loja, e `d`
   é o *versionCode*. Use um `d` **menor que 101**, porque os números a partir de 101 são usados pelo CI.
2. Gere o bundle:

    ```bash
    flutter build appbundle --release
    ```

    O resultado fica em `build/app/outputs/bundle/release/app-release.aab`.

### C7. Enviar e lançar o primeiro bundle

No Play Console, abra o **teste interno**, crie uma versão, envie o `.aab`, preencha as notas da versão
e clique em **Salvar → Lançar**.

### C8. Registrar no Firebase os SHAs da assinatura do Google Play

O Play reassina o app com uma chave do Google (*Play App Signing*). Sem os SHAs dessa chave no Firebase, o
login com Google falha nos aparelhos dos testadores. Copie o SHA1 e o SHA256 em *Play Console → Protegido
com o Google Play → Assinatura de apps* e registre:

```bash
firebase apps:android:sha:create $APP_ID <SHA1_DO_PLAY> --project $FIREBASE_PROJECT
firebase apps:android:sha:create $APP_ID <SHA256_DO_PLAY> --project $FIREBASE_PROJECT
```

### C9. Criar a service account do deploy

É a identidade que publica no Play. Cada pipeline tem a sua, e ela não recebe nenhum papel no Google
Cloud. O motivo está em [entendendo-o-ci.md](entendendo-o-ci.md#por-que-uma-service-account-dedicada).

```bash
gcloud iam service-accounts create $SA_NAME \
  --project=$GCP_PROJECT \
  --display-name="monamie-app Play publisher" \
  --description="Publishes $REPO to the Play internal track from GitHub Actions via WIF. Docs: docs/pt-br/publicar-teste-interno.md"
```

### C10. Permitir que só o environment `play-internal` assuma a service account

O `--member` é o *subject* exato que o GitHub coloca no token de um job que roda no environment
`play-internal` deste repositório. Qualquer outro job é recusado.

```bash
gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
  --project=$GCP_PROJECT \
  --role=roles/iam.workloadIdentityUser \
  --member="principal://iam.googleapis.com/projects/$GCP_PROJECT_NUMBER/locations/global/workloadIdentityPools/$POOL/subject/repo:$REPO:environment:play-internal"
```

**Conferir:** `gcloud iam service-accounts get-iam-policy $SA_EMAIL --project=$GCP_PROJECT` deve listar um
binding `roles/iam.workloadIdentityUser` com esse `principal://...`. Se aparecer só o `etag`, o comando não
foi aplicado.

### C11. Convidar a service account no Play Console

1. No Play Console, abra **Usuários e permissões → Convidar novos usuários**.
2. Informe o e-mail da service account (`echo $SA_EMAIL`).
3. Em **Permissões do app**, adicione o app e marque **apenas** a permissão de lançar em faixas de teste.
4. Clique em **Convidar usuário**.

A permissão pode levar até 48 horas para valer.

### C12. Criar o environment e os secrets no GitHub

O environment `play-internal` guarda os secrets de assinatura e só pode ser usado pela `main`. **Essa
restrição é obrigatória:** a permissão de C10 confia no environment, e é a restrição que impede outras
branches de publicar.

| Secret | Valor |
| :--- | :--- |
| `ANDROID_KEYSTORE_B64` | a keystore codificada em base64 |
| `ANDROID_KEYSTORE_PASSWORD` | o `storePassword` do `key.properties` |
| `ANDROID_KEY_PASSWORD` | o `keyPassword` do `key.properties` |
| `ANDROID_KEY_ALIAS` | o `keyAlias` do `key.properties` |

Pela interface, use *Settings → Environments*. Pelo terminal, a partir da raiz do repositório, os valores
vão direto do `key.properties` para o GitHub, sem aparecer na tela:

```bash
prop() { grep "^$1=" android/key.properties | cut -d= -f2- | tr -d '\r\n'; }

gh api -X PUT repos/$REPO/environments/play-internal \
  -F 'deployment_branch_policy[protected_branches]=false' \
  -F 'deployment_branch_policy[custom_branch_policies]=true'
gh api -X POST repos/$REPO/environments/play-internal/deployment-branch-policies -f name=main

prop storePassword | gh secret set ANDROID_KEYSTORE_PASSWORD --env play-internal --repo $REPO
prop keyPassword   | gh secret set ANDROID_KEY_PASSWORD      --env play-internal --repo $REPO
prop keyAlias      | gh secret set ANDROID_KEY_ALIAS         --env play-internal --repo $REPO
base64 -w0 "$(prop storeFile)" | gh secret set ANDROID_KEYSTORE_B64 --env play-internal --repo $REPO
```

**Conferir:** `gh secret list --env play-internal --repo $REPO` deve listar os 4 secrets, e
`gh api repos/$REPO/environments/play-internal/deployment-branch-policies --jq '.branch_policies[].name'`
deve mostrar `main`.

## D. A cada nova versão

### D1. Fazer o merge da PR na `main`

É o único passo manual. Para mudar o versionName (por exemplo, de `1.0.0` para `1.1.0`), altere o
`version:` do `pubspec.yaml` na própria PR. O versionCode é automático.

### D2. Publicação automática ⚙️

O merge dispara o workflow, que roda os testes, gera e assina o bundle, envia-o ao Play e lança a versão
para os testadores. Nada precisa ser feito, mas vale saber:

- **Acompanhar:** em *Actions → Deploy to Play (internal)*, cada execução mostra os logs de cada passo.
  Se algo falhar, nada é enviado e quem fez o push recebe um e-mail.
- **Publicar de novo sem merge**, por exemplo depois de corrigir uma permissão: use *Run workflow* na `main`.
- **Notas da versão:** são opcionais na faixa interna, e o workflow não as preenche. Se quiser notas,
  edite a versão no Play Console.
- ⚠️ **Não renomeie o arquivo do workflow.** O número da execução, usado como versionCode, é contado por
  arquivo. Renomeá-lo reinicia a contagem em 1, e o Play recusa versionCodes repetidos.

**Sem o CI:** se o workflow estiver indisponível, repita C6 e C7 com um versionCode maior que o da última
versão enviada, que aparece no Play Console.

---

## Problemas comuns

| Mensagem | Causa e solução |
| :--- | :--- |
| `Release signing: ...` | O `key.properties` ou a keystore estão incompletos. Localmente, confira B1. No CI, confira os secrets de C12. |
| `Secret ANDROID_... is empty` | O secret não foi cadastrado no environment `play-internal`, ou foi cadastrado como secret do repositório (C12). |
| `The given credential is rejected by the attribute condition` | O token não veio da organização `monamienet`. Confira a condição do provider (A4). |
| `Permission 'iam.serviceAccounts.getAccessToken' denied` | Falta a permissão de C10, ou o job não rodou no environment `play-internal`, e por isso o subject do token é outro. |
| `The caller does not have permission` | A service account ainda não tem permissão no Play Console, ou a permissão ainda não propagou (C11). |
| `Version code ... has already been used` | O versionCode já foi usado. Normalmente o arquivo do workflow foi renomeado. Aumente o `+ 100` no workflow. |
| `Only releases with status draft may be created on draft app` | O app ainda está em rascunho no Play. Conclua o primeiro lançamento (C7). |
| O app instala, mas o login com Google falha | Faltam SHAs no Firebase: da chave de upload (C3) ou da assinatura do Google Play (C8). |
