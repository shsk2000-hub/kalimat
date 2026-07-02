# kalimat

Arabic multiplayer word challenge game built with Flutter Web.

## Local development

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable)
- [Node.js](https://nodejs.org/) 20+ (for local multiplayer server)
- [Firebase CLI](https://firebase.google.com/docs/cli) (for hosting deployment)

### Run on web with local multiplayer server

```powershell
.\scripts\serve-web.ps1
```

Open http://localhost:3000

### Build web release

```powershell
flutter build web --release
```

## Firebase Hosting deployment

Hosting serves the Flutter Web build from `build/web` with single-page app rewrites.

```powershell
flutter build web --release
firebase deploy --only hosting
```
