# Run the web version locally

This document explains how to run the app's web build on your machine, sign in with a real Google
account, and check automatically that the login page renders. Each step says **why** it exists, so the
process can be scripted or run in CI without surprises.

> **Summary:** run `flutter build web --release`, serve `build/web` on **`http://localhost:5000`** (any
> other port fails Google sign-in with `origin_mismatch`), and open it in the Chrome profile that has the
> account you want. For an unattended check, use headless Chrome through DevTools and wait for Flutter to
> paint before taking the screenshot.

---

## 1. Build

```bash
flutter build web --release
```

The output is in `build/web/`. It is a static build: rebuild after changing code.

> Once `dart run tool/partner.dart web <id>` exists (#32), run it before the build to pick the partner.

## 2. Serve on `localhost:5000`

```bash
python3 -m http.server 5000 --bind 127.0.0.1 -d build/web
```

- **Why port 5000:** web Google sign-in uses the OAuth web client of the partner's Firebase project
  (`google-signin-client_id` in `web/index.html`). That client only accepts the origins listed under
  **Authorized JavaScript origins**. `http://localhost:5000` is accepted. On any other port (for example
  8787), the Google window shows `Error 400: origin_mismatch`.
- **To check or add origins:** Google Cloud Console for project `monamienet-<id>` → *APIs & Services* →
  *Credentials* → OAuth client "Web client (auto created by Google Service)" → *Authorized JavaScript
  origins*.
- **Routing:** the app uses hash routes (`/#/login`, `/#/monamie`), so a plain static server works
  without any rewrite rule.
- `--bind 127.0.0.1` keeps the server reachable from your machine only.

## 3. Open it in a real Chrome profile

`flutter run -d chrome` always starts Chrome with a throwaway profile that has none of your accounts.
To use an account that is already signed in, open the URL in the right profile.

1. Find each account's profile directory:

    ```bash
    python3 -I -c "
    import json, os
    d = json.load(open(os.path.expanduser('~/.config/google-chrome/Local State')))
    for k, v in d['profile']['info_cache'].items(): print(k, '|', v.get('user_name'))
    "
    ```

    Example output: `Profile 1 | someone@id.uff.br`.

2. Open the app in that profile:

    ```bash
    google-chrome --profile-directory="Profile 1" http://localhost:5000/
    ```

    If Chrome is already running, the command only opens a window in the existing process and exits right
    away.

3. Click **Fazer Login com o Google** and pick the account.

## 4. Automated check (unattended)

For a script or CI to confirm that the login page renders, use headless Chrome driven through the
DevTools Protocol (CDP).

- **Use a temporary profile directory** (`--user-data-dir`). Since Chrome 136, `--remote-debugging-port`
  is ignored for the default profile
  ([Chrome announcement](https://developer.chrome.com/blog/remote-debugging-port)). So the real profile
  can't be automated through CDP, and the automated check only covers screens before sign-in.
- **Don't use `--screenshot`:** it captures as soon as the page finishes loading, before Flutter
  (CanvasKit) has painted anything, so the image comes out blank. Wait for real, then capture through CDP.

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
# Requires the "websockets" Python package.
import asyncio, base64, json, sys, urllib.request, websockets

async def main(out):
    tabs = json.load(urllib.request.urlopen("http://127.0.0.1:9333/json"))
    ws_url = next(t["webSocketDebuggerUrl"] for t in tabs if t["type"] == "page")
    async with websockets.connect(ws_url, max_size=None) as ws:
        await asyncio.sleep(25)  # time to download CanvasKit and paint the first frame
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

`web.png` should show the "MonAmie <name>" bar, the partner logo and the **Fazer Login com o Google**
button.

## 5. Known problems

| Symptom | Cause | What to do |
| :--- | :--- | :--- |
| `Error 400: origin_mismatch` in the Google window | port other than 5000 | serve on `localhost:5000` or add the origin (step 2) |
| Blank screenshot | captured before Flutter painted | capture through CDP after waiting (step 4) |
| "Nenhum grupo disponível" with `ClientException: Failed to fetch` | `workspace-groups-gateway` sends no CORS headers, so the browser blocks the response (Android works) | wait for the gateway fix: #49 |
