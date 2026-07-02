# kalimat

Arabic multiplayer word challenge game built with Flutter Web and a Node.js real-time server.

## Local development

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable)
- [Node.js](https://nodejs.org/) 20+

### Run on web with multiplayer server

```powershell
.\scripts\serve-web.ps1
```

Open http://localhost:3000

### Build web only

```powershell
flutter build web --release
```

## Production deployment

This project ships as a single Docker container:

1. Flutter Web is built during the Docker image build.
2. A Node.js server serves the static web app and handles Socket.IO multiplayer rooms.

### Health check

`GET /health` returns `{ "ok": true, "rooms": <count> }`.

## Deploy to GitHub and Render

### 1. Push to GitHub

```powershell
cd C:\Users\forsu\Projects\kalimat

# Create a new empty repository on GitHub named "kalimat", then:
git remote add origin https://github.com/YOUR_USERNAME/kalimat.git
git branch -M main
git push -u origin main
```

### 2. Deploy on Render

1. Sign in at https://render.com
2. Click **New +** → **Blueprint**
3. Connect your GitHub account and select the `kalimat` repository
4. Render reads `render.yaml` and creates a **Web Service** named `kalimat`
5. Click **Apply** and wait for the Docker build to finish
6. Open the generated URL (for example `https://kalimat.onrender.com`)

### 3. Verify production

- App loads at your Render URL
- `https://YOUR_APP.onrender.com/health` returns `{"ok":true,...}`
- Create a room, share the join link, and confirm multiplayer works

### Notes

- Render free tier may spin down after inactivity; the first request can take ~30 seconds.
- WebSockets are supported on Render web services; Socket.IO falls back to polling if needed.
- Room state is stored in memory and resets when the service restarts.
