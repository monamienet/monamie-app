# Rodar a versão web localmente

Este documento mostra como rodar o build web do app na sua máquina, entrar com uma conta Google real
e verificar automaticamente que a página de login aparece. Cada passo diz **por que** ele existe,
para que o processo possa virar script ou rodar em CI sem surpresas.

> **Resumo:** `dart run tool/partner.dart web` e `flutter build web --release`, sirva `build/web` em **`http://localhost:5000`** (outra porta
> falha no login do Google com `origin_mismatch`) e abra no perfil do Chrome que tem a conta desejada.
> Para uma verificação sem pessoa, use um Chrome headless com DevTools e espere o Flutter desenhar antes
> de tirar o screenshot.

---

## 1. Gerar o build

```bash
dart run tool/partner.dart web
flutter build web --release
```

- **Por que o primeiro comando:** o app web faz login pelo projeto Firebase central (`monamienet-app`),
  cuja config nunca é versionada (ela tem API keys). A ferramenta lê essa config com o seu
  `firebase login` e grava `web/central/firebase.json` (ignorado pelo git): as opções do Firebase web e
  o client id OAuth web do login Google. O `flutter build web` copia tudo o que está em `web/` para o
  resultado, e o `flutter run -d chrome` serve essa pasta. Assim, o app lê `central/firebase.json` via
  HTTP ao iniciar. Rode de novo só se o app web do projeto central mudar.
- Não há parceiro para preparar: um único app web atende todos os parceiros. O parceiro do usuário, com
  cores e logo, é ligado depois do login (veja `white-label.md`). O `web/index.html`, o `manifest.json`,
  o favicon e os ícones são arquivos fixos da MonAmie.
- Sem esse passo, o build ainda funciona, mas a página mostra `Could not fetch
  …/central/firebase.json (HTTP 404)` no lugar do app.
- O resultado fica em `build/web/`. É um build estático: depois de mudar o código, gere de novo.

## 2. Servir em `localhost:5000`

```bash
python3 -m http.server 5000 --bind 127.0.0.1 -d build/web
```

- **Por que a porta 5000:** o login do Google na web usa o cliente OAuth web do projeto Firebase
  central (`googleClientId` em `web/central/firebase.json`). Esse cliente só aceita as origens cadastradas
  em **Origens JavaScript autorizadas**. `http://localhost:5000` é aceita: o Firebase a cadastra (junto com `http://localhost`) ao criar o cliente. Com outra porta (por exemplo,
  8787), a janela do Google mostra `Erro 400: origin_mismatch`.
- **Para conferir ou adicionar origens:** Google Cloud Console do projeto `monamienet-app` → *APIs e
  serviços* → *Credenciais* → cliente OAuth "Web client (auto created by Google Service)" → *Origens
  JavaScript autorizadas*.
- **Rotas:** o app usa rotas com `#` (`/#/login`, `/#/monamie`). Por isso um servidor estático simples
  basta, sem regra de rewrite.
- `--bind 127.0.0.1` deixa o servidor acessível só na sua máquina.

## 3. Abrir em um perfil real do Chrome

`flutter run -d chrome` sempre abre um Chrome com um perfil temporário, sem as suas contas. Para usar
uma conta já logada, abra o endereço no perfil certo.

1. Descubra a pasta do perfil de cada conta:

    ```bash
    python3 -I -c "
    import json, os
    d = json.load(open(os.path.expanduser('~/.config/google-chrome/Local State')))
    for k, v in d['profile']['info_cache'].items(): print(k, '|', v.get('user_name'))
    "
    ```

    Exemplo de saída: `Profile 1 | fulano@id.uff.br`.

2. Abra o app nesse perfil:

    ```bash
    google-chrome --profile-directory="Profile 1" http://localhost:5000/
    ```

    Se o Chrome já estiver aberto, o comando só abre uma janela no processo existente e termina na hora.

3. Clique em **Fazer Login com o Google** e escolha a conta.

## 4. Verificação automática (sem pessoa)

Para um script ou CI confirmar que o login aparece, use um Chrome headless controlado pelo DevTools
Protocol (CDP).

- **Use uma pasta de perfil temporária** (`--user-data-dir`). Desde o Chrome 136, `--remote-debugging-port`
  é ignorado no perfil padrão
  ([anúncio do Chrome](https://developer.chrome.com/blog/remote-debugging-port)). Por isso não dá para
  automatizar o perfil real com CDP, e a verificação automática só cobre telas sem login.
- **Não use `--screenshot`:** ele tira a foto quando a página termina de carregar, antes de o Flutter
  (CanvasKit) desenhar, e o resultado sai em branco. Espere de verdade e capture pelo CDP.

```bash
python3 -m http.server 5000 --bind 127.0.0.1 -d build/web &
SERVER=$!
PROFILE=$(mktemp -d)
google-chrome --headless=new --no-sandbox --enable-unsafe-swiftshader \
  --user-data-dir="$PROFILE" --remote-debugging-port=9333 --window-size=420,860 \
  http://localhost:5000/ &
CHROME=$!
sleep 3
python3 -I - web.png <<'EOF'
# Requer o pacote Python "websockets".
import asyncio, base64, json, sys, urllib.request, websockets

async def main(out):
    tabs = json.load(urllib.request.urlopen("http://127.0.0.1:9333/json"))
    ws_url = next(t["webSocketDebuggerUrl"] for t in tabs if t["type"] == "page")
    async with websockets.connect(ws_url, max_size=None) as ws:
        await asyncio.sleep(25)  # tempo para baixar o CanvasKit e desenhar o primeiro frame
        await ws.send(json.dumps({"id": 1, "method": "Page.captureScreenshot"}))
        while True:
            msg = json.loads(await ws.recv())
            if msg.get("id") == 1:
                open(out, "wb").write(base64.b64decode(msg["result"]["data"]))
                break

asyncio.run(main(sys.argv[1]))
EOF
kill $CHROME $SERVER
rm -rf "$PROFILE"
```

O `web.png` deve mostrar a barra "MonAmie", o logo da MonAmie (antes do login nenhum parceiro está ligado) e o botão
**Fazer Login com o Google**.

## 5. Problemas conhecidos

| Sintoma | Causa | O que fazer |
| :--- | :--- | :--- |
| `Erro 400: origin_mismatch` na janela do Google | porta diferente de 5000 | sirva em `localhost:5000` ou cadastre a origem (passo 2) |
| Screenshot em branco | foto tirada antes de o Flutter desenhar | capture pelo CDP depois de esperar (passo 4) |
| "Nenhum grupo disponível" com `ClientException: Failed to fetch` | o `workspace-groups-gateway` não envia cabeçalhos CORS, e o navegador bloqueia a resposta (no Android funciona) | aguarde a correção no gateway: #49 |
