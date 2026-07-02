# kalimat

Arabic multiplayer word challenge game built with Flutter Web.

## Local development

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable)
- [Node.js](https://nodejs.org/) 20+ (for local multiplayer server)
- [Firebase CLI](https://firebase.google.com/docs/cli) (for hosting deployment)

## Architecture

- **Firebase Hosting** serves the Flutter Web app.
- **Render** runs the Socket.IO multiplayer API (`server/`).

Set the API URL when building for production:

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://YOUR_API.onrender.com
firebase deploy --only hosting
```

Or use:

```powershell
.\scripts\deploy-production.ps1 -ApiBaseUrl https://YOUR_API.onrender.com
```

### Deploy the API on Render

1. Push this repository to GitHub.
2. In Render, create a **Blueprint** from the repo (uses `render.yaml`).
3. Wait for `kalimat-api` to deploy and copy its URL.
4. Run the production web deploy command above with that URL.

### Local multiplayer

```powershell
.\scripts\serve-web.ps1
```

Open http://localhost:3000
