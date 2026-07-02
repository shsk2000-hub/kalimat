# kalimat

Arabic multiplayer word challenge game built with Flutter Web and Firebase.

## Stack

- **Firebase Hosting** — Flutter Web app
- **Firebase Realtime Database** — rooms, players, and live game state
- **Local player identity** — stored in browser/device (no signup)

## One-time Firebase setup

1. Open [Realtime Database in Firebase Console](https://console.firebase.google.com/project/kalimat-shsk2000/database)
2. Click **Create Database** → choose a location → **Start in test mode**
3. Deploy rules and app:

```powershell
firebase deploy --only database,hosting
```

## Local development

```powershell
flutter pub get
flutter run -d chrome
```

## Deploy updates

```powershell
flutter build web --release
firebase deploy --only hosting
```

## Multiplayer rules

- Room creator is the host
- Host starts rounds and approves all player words
- Join via room code or QR/link (`?join=1234`)
