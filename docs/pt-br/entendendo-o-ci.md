# Entendendo o CI: deploy automático para o teste interno

Este documento explica, para quem nunca trabalhou com CI, como funciona o workflow
[`.github/workflows/deploy-play-internal.yml`](../../.github/workflows/deploy-play-internal.yml).
Ele publica o app na faixa de **teste interno** do Google Play a cada merge na `main`.

O passo a passo operacional (configuração inicial, secrets e solução de problemas) está em
[publicar-teste-interno.md](publicar-teste-interno.md#publicação-automática-ci).

---

## 1. Conceitos

**CI/CD** (Integração Contínua / Entrega Contínua) é a ideia de que uma máquina, e não uma pessoa,
executa os passos repetitivos de verificar, compilar e publicar o código. Isso acontece sempre que algo
muda no repositório. O que antes era feito à mão no terminal (`flutter build appbundle`) e no navegador
(upload no Play Console) vira uma "receita" que roda sozinha.

No GitHub, essa ferramenta se chama **GitHub Actions**. O vocabulário:

| Termo | O que é | Neste projeto |
| :--- | :--- | :--- |
| **Workflow** | Um arquivo YAML em `.github/workflows/` que descreve *quando* rodar e *o que* fazer. O GitHub detecta o arquivo automaticamente. | `deploy-play-internal.yml` |
| **Trigger** (`on:`) | O evento que dispara o workflow. | um push na `main`, ou o clique manual em "Run workflow" |
| **Runner** | A máquina virtual que o GitHub liga para executar o workflow. Ela começa **vazia**: não tem Flutter, Java, nem os arquivos que estão fora do git. Depois de terminar, ela é destruída. | `ubuntu-latest` (Linux) |
| **Job** | Um grupo de passos que rodam em sequência no mesmo runner. | um único job, `deploy` |
| **Step** | Um passo do job. Pode ser um comando de shell (`run:`) ou uma **action** (`uses:`). | 9 passos |
| **Action** | Um passo pronto e reutilizável, publicado por alguém, como uma "função" que você chama. | `actions/checkout` baixa o código; `subosito/flutter-action` instala o Flutter; `r0adkll/upload-google-play` envia ao Play |
| **Secret** | Um valor sensível guardado criptografado no GitHub. O workflow lê com `${{ secrets.NOME }}`, e o GitHub mascara o valor nos logs (aparece `***`). | a keystore, as senhas dela e a credencial do Play |
| **Environment** | Um "cofre" com nome (Settings → Environments) que agrupa secrets e pode ter regras, como exigir aprovação manual antes de rodar. | `play-internal` |
| **Artifact** | Um arquivo gerado no runner que o GitHub guarda para download depois que o runner é destruído. | **não usamos**: o repositório é público, e qualquer pessoa logada no GitHub poderia baixar builds de teste ainda não lançados. O Play Console já guarda cada versão enviada. |

## 2. O fluxo de ponta a ponta

```
PR aberta ──► PR aprovada ──► "Merge" no GitHub
                                    │
               o merge cria um commit novo na main = evento "push na main"
                                    │
                                    ▼
             GitHub Actions liga um runner Ubuntu vazio
                                    │
   ┌────────────────────────────────┴─────────────────────────────────┐
   │ 1. baixa o código        2. instala Java 17                       │
   │ 3. instala Flutter       4. ajusta a memória do Gradle            │
   │ 5. recria a keystore e o key.properties                           │
   │ 6. baixa dependências    7. roda os testes unitários              │
   │ 8. flutter build appbundle (assinado, versionCode novo)           │
   │ 9. envia ao Play (faixa internal)                                 │
   └────────────────────────────────┬─────────────────────────────────┘
                                    ▼
         Testadores internos recebem a atualização pela Play Store
```

Se **qualquer** passo falhar (um teste quebrado, um secret faltando, erro de compilação), os passos
seguintes não rodam e **nada é enviado ao Play**. O GitHub mostra um ❌ no commit e manda e-mail para quem
fez o push.

**Por que "push na main" e não "PR aceita"?** O GitHub não tem um evento chamado "PR aprovada". O merge
de uma PR sempre gera um push na `main`, e esse é o evento mais simples e confiável de escutar. Uma
consequência: um push feito **direto** na `main`, sem PR, também dispara o deploy. As regras do
[AGENTS.md](../../AGENTS.md) já proíbem pushes diretos.

## 3. Como ler o arquivo do workflow

### 3.1 O básico de YAML

YAML é só uma forma de escrever dados estruturados, parecida com JSON, mas sem chaves e aspas. As regras:

| Regra | Exemplo | Equivale a (em JSON) |
| :--- | :--- | :--- |
| `chave: valor` define um campo | `name: Deploy` | `{"name": "Deploy"}` |
| **Indentação** (espaços) põe um campo **dentro** de outro | `on:`<br>`  push:` | `{"on": {"push": ...}}` |
| `-` no início da linha é um **item de lista** | `steps:`<br>`  - run: a`<br>`  - run: b` | `{"steps": [{"run":"a"}, {"run":"b"}]}` |
| `[a, b]` é uma lista numa linha só | `branches: [main]` | `{"branches": ["main"]}` |
| `#` começa um comentário (ignorado) | `# explica algo` | — |

Mais duas notações aparecem no arquivo:
- `run: |`: o `|` indica que as linhas indentadas abaixo formam **um texto de várias linhas**, no caso
  um pequeno script de shell.
- `${{ ... }}`: não é YAML, é uma **expressão do GitHub**. Antes de executar, o GitHub troca isso pelo
  valor real. Por exemplo, `${{ secrets.ANDROID_KEY_ALIAS }}` vira o valor desse secret e
  `${{ github.run_number }}` vira o número da execução.

### 3.2 Dicionário das palavras-chave

As palavras à esquerda são **fixas**, definidas pelo GitHub Actions. Os valores à direita são escolhas nossas.

| Palavra-chave | O que faz | Valor no nosso arquivo |
| :--- | :--- | :--- |
| `name` (no topo) | Nome do workflow que aparece na aba Actions. | `Deploy to Play (internal)` |
| `on` | Lista os **eventos** que disparam o workflow. | `push` e `workflow_dispatch` |
| `on.push.branches` | Restringe o evento `push` a certas branches. Um push em outra branch não dispara. | `[main]` |
| `on.workflow_dispatch` | Cria o botão "Run workflow" para disparar à mão. Não precisa de valor. | vazio |
| `concurrency` | Controla execuções **simultâneas** (seção 3.4). | — |
| `jobs` | Lista os jobs. Cada chave dentro dele é o **nome** de um job, à nossa escolha. | um job chamado `deploy` |
| `runs-on` | O sistema operacional do runner. | `ubuntu-latest` |
| `environment` | Qual Environment (cofre de secrets) o job usa. Sem isso, `secrets.X` vem vazio. | `play-internal` |
| `steps` | A **lista** de passos, executados de cima para baixo. Cada `-` é um passo. | 9 passos |
| `name` (dentro de um step) | Rótulo opcional do passo nos logs. | ex.: `Limit Gradle memory` |
| `uses` | O passo **chama uma action pronta**, no formato `dono/repositório@versão`. | ex.: `actions/setup-java@v6` |
| `with` | Os **parâmetros** passados à action do `uses` (seção 3.3). | ex.: `java-version: '17'` |
| `run` | O passo **executa comandos de shell**, como num terminal. | ex.: `flutter test test/unit` |
| `env` | **Variáveis de ambiente** disponíveis para os comandos do `run` daquele passo. | as senhas lidas dos secrets |

Um passo usa **ou** `uses` (+ `with`) **ou** `run` (+ `env`, se precisar). Os dois pares têm o mesmo
papel: o que executar e com quais dados.

### 3.3 `with`: os argumentos de uma action

Uma action funciona como uma **função** escrita por outra pessoa. O `uses` diz **qual função** chamar,
e o `with` passa os **argumentos**:

```yaml
- uses: actions/setup-java@v6     # a função: "instalar Java", versão 6 da action
  with:                           # os argumentos:
    distribution: temurin         #   qual distribuição do Java (Temurin, a gratuita da Eclipse)
    java-version: '17'            #   qual versão do Java
```

Em Dart, isso seria algo como `setupJava(distribution: 'temurin', javaVersion: '17')`.

Quais argumentos existem é **cada action que define**, e eles ficam listados no README do repositório
dela. Por exemplo, `track` e `packageName` existem porque a `r0adkll/upload-google-play` os aceita. Para
a `actions/setup-java`, eles não significariam nada. O `'17'` vai entre aspas para o YAML tratar como
texto, e não como número.

### 3.4 `concurrency`: uma fila de execuções

```yaml
concurrency:
  group: play-internal          # um "nome de fila" qualquer, escolhido por nós
  cancel-in-progress: false     # não interromper quem já está rodando
```

- **`group`** é um rótulo. O GitHub garante que, entre todas as execuções com o **mesmo rótulo**, só
  **uma** roda por vez. As outras esperam na fila. O texto `play-internal` não tem significado
  especial: ele só precisa ser igual entre as execuções que não podem se sobrepor.
- **`cancel-in-progress`** decide o que acontece com a execução **que já está rodando** quando chega
  uma nova:
  - `true`: a que está rodando é **cancelada** e a nova assume o lugar;
  - `false`, a nossa escolha: a que está rodando **termina normalmente**, e a nova espera a vez.
    Cancelar um deploy no meio do upload pode deixar um release pela metade no Play.

Um detalhe do GitHub: a fila guarda no máximo **uma** execução esperando. Se chegarem três merges
seguidos, a do meio é descartada e só a mais nova sobe depois da primeira. Isso não perde nada, porque
a `main` mais nova já contém as mudanças da do meio.

### 3.5 Os passos, um a um

| # | Passo | O que faz e por quê |
| :--- | :--- | :--- |
| 1 | `actions/checkout` | O runner começa vazio; este passo baixa o código do commit que disparou o workflow. |
| 2 | `actions/setup-java` | O Gradle do Android precisa de Java. O projeto compila para JVM 17 ([build.gradle.kts](../../android/app/build.gradle.kts)). |
| 3 | `subosito/flutter-action` | Instala a **mesma** versão do Flutter usada no desenvolvimento, para o CI não gerar um app diferente. Com `cache: true`, o SDK é reaproveitado e as próximas execuções ficam mais rápidas. |
| 4 | `Limit Gradle memory` | O [android/gradle.properties](../../android/gradle.properties) pede 8 GB de RAM (`-Xmx8G`), mais do que o runner tem. O arquivo `~/.gradle/gradle.properties` tem prioridade sobre o do projeto, então o limite é reduzido só no CI. |
| 5 | `Restore release signing` | Recria a keystore e o `android/key.properties`, que não estão no git (seção 4). Antes disso, confere que nenhum secret está vazio. |
| 6 | `flutter pub get` | Baixa as dependências do `pubspec.yaml`. |
| 7 | `flutter test test/unit` | Roda os testes unitários. Se algum falhar, o deploy para aqui. Os testes de integração ficam de fora porque dependem dos emuladores do Firebase. |
| 8 | `flutter build appbundle` | Gera o `.aab` de release, assinado com a keystore do passo 5 e com um versionCode novo (seção 5). |
| 9 | `r0adkll/upload-google-play` | Envia o `.aab` para a faixa `internal`, autenticando com a service account (seção 6). `status: completed` lança o release direto para os testadores. |

## 4. Como a keystore chega ao runner (por que base64)

O runner só tem o que está no git, e a keystore e o `key.properties` ficam de fora de propósito: esses
são segredos de verdade. Quem tiver a keystore e as senhas consegue assinar versões do app em nome da
MonAmieNet.

Um secret do GitHub, porém, só guarda **texto**, e a keystore (`.jks`) é um arquivo **binário**. A
solução comum é a **base64**: uma codificação que transforma qualquer arquivo num texto só com letras e
números, e que pode ser desfeita sem perda.

- **Na máquina de quem configura, uma única vez:** `base64 -w0 upload.jks` gera um texto. Esse texto vai
  para o secret `ANDROID_KEYSTORE_B64`.
- **No runner, a cada execução:** `base64 -d` transforma o texto de volta no arquivo `.jks` original.
  Ele é gravado numa pasta temporária (`$RUNNER_TEMP`) que é apagada com o runner.

O `key.properties` não precisa de secret próprio: ele é montado ali mesmo, com as senhas e o alias,
apontando `storeFile` para a keystore recém-decodificada.

### Fail-fast em duas camadas

Um build release **nunca** cai para a chave debug, o que geraria um bundle que o Play rejeita. Há duas
proteções:

1. **No workflow:** o passo 5 diz *qual* secret do GitHub está vazio e para a execução.
2. **No Gradle:** a task `validateReleaseSigning` ([build.gradle.kts](../../android/app/build.gradle.kts))
   roda antes de **qualquer** build release, no CI ou numa máquina local. Ela falha se faltar o
   `key.properties`, alguma propriedade dele ou o arquivo da keystore.

Builds debug (`flutter run`) não são afetados e funcionam sem keystore.

### E o `google_config.dart`?

O [lib/app/config/google_config.dart](../../lib/app/config/google_config.dart) é versionado
normalmente porque seus valores **não são segredos**: um ID de cliente OAuth (público por design) e o
endereço do gateway de grupos. Tudo o que é compilado no app pode ser extraído do binário por qualquer
pessoa. A proteção do gateway é o token Google (`Bearer`) que o app envia em cada requisição.

## 5. Como o versionCode é definido

O Play exige que cada `.aab` enviado tenha um `versionCode` **maior** que todos os anteriores. Antes do
CI, isso era o número depois do `+` no `version:` do `pubspec.yaml`, incrementado à mão.

O GitHub dá a cada execução de um workflow um contador, `GITHUB_RUN_NUMBER` (1, 2, 3...), que **só
cresce**. O flag `--build-number` do `flutter build` substitui o número depois do `+` sem tocar no
pubspec. Assim, a 1ª execução gera versionCode **101**, a 2ª gera **102**, e assim por diante. O `+100`
garante começar acima dos envios manuais já feitos.

- O **versionName** (`1.0.0`, o que o usuário vê na loja) continua vindo do `pubspec.yaml`. Mude-o
  numa PR quando quiser.
- Execuções que falham também consomem um número. Isso cria "buracos" (101, 103...), o que é normal:
  o Play só exige que o número cresça.
- ⚠️ **Não renomeie o arquivo do workflow.** O contador pertence ao arquivo. Se ele for renomeado, o
  contador volta a 1 e o upload falha por versionCode repetido.

## 6. Como o GitHub ganha permissão para publicar no Play

Para publicar, o GitHub precisa se autenticar no Play Console sem usar a conta Google de uma pessoa.
Para isso existe a **service account**: uma "conta de robô" do Google Cloud com um arquivo de credencial
(JSON). No Play Console, essa conta recebe permissão **só** para lançar em faixas de teste do app. O JSON
fica no secret `PLAY_SERVICE_ACCOUNT_JSON`, e a action `r0adkll/upload-google-play` o usa para chamar
a API do Play.

Usamos essa action em vez do **fastlane**, outra ferramenta popular de deploy mobile, porque ela faz só
o upload, não exige instalar Ruby e cabe em poucas linhas de YAML.
