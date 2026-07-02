import cors from 'cors';
import express from 'express';
import fs from 'fs';
import { createServer } from 'http';
import os from 'os';
import path from 'path';
import { fileURLToPath } from 'url';
import { Server } from 'socket.io';

const PORT = process.env.PORT || 3000;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const WEB_ROOT = path.join(__dirname, 'public');

const PROMPTS = [
  'ولد',
  'حيوان',
  'فاكهة',
  'مدينة',
  'لون',
  'مهنة',
  'كتاب',
  'طعام',
  'رياضة',
  'بلد',
];

/** @type {Map<string, any>} */
const rooms = new Map();

/** @type {Map<string, string>} */
const socketToRoom = new Map();

/** @type {Map<string, string>} */
const socketToPlayer = new Map();

function generateRoomCode() {
  let code = '';
  do {
    code = String(Math.floor(1000 + Math.random() * 9000));
  } while (rooms.has(code));
  return code;
}

function getPrompt(roundIndex) {
  return PROMPTS[roundIndex % PROMPTS.length];
}

function createPlayer(socketId, name, isHost = false) {
  return {
    id: socketId,
    name,
    points: 0,
    isHost,
    hasSubmitted: false,
    hasReviewed: false,
  };
}

function resetRoundState(room) {
  room.prompt = null;
  room.roundEndsAt = null;
  room.submissions = {};
  room.reviews = {};
  room.roundScores = {};
  for (const player of room.players) {
    player.hasSubmitted = false;
    player.hasReviewed = false;
  }
}

function sortedPlayers(room) {
  return [...room.players].sort((a, b) => b.points - a.points);
}

function buildRoundResults(room) {
  const results = room.players.map((player) => {
    const approvedWords = room.reviews[player.id] || [];
    const roundScore = approvedWords.length;
    return {
      playerId: player.id,
      playerName: player.name,
      approvedWords,
      roundScore,
      totalPoints: player.points,
    };
  });

  return results.sort((a, b) => b.roundScore - a.roundScore);
}

function serializeRoom(room, viewerSocketId) {
  const viewerPlayerId = socketToPlayer.get(viewerSocketId);
  const mySubmission = room.submissions[viewerPlayerId] || [];
  const myReview = room.reviews[viewerPlayerId] || mySubmission;
  const isHostViewer = room.hostId === viewerPlayerId;

  const reviewSubmissions =
    room.phase === 'review' && isHostViewer
      ? room.players.map((player) => ({
          playerId: player.id,
          playerName: player.name,
          words: room.submissions[player.id] || [],
          approvedWords:
            room.reviews[player.id] ?? [...(room.submissions[player.id] || [])],
        }))
      : [];

  return {
    code: room.code,
    playerId: viewerPlayerId,
    isHost: isHostViewer,
    settings: room.settings,
    phase: room.phase,
    roundIndex: room.roundIndex,
    players: room.players.map((player) => ({
      id: player.id,
      name: player.name,
      points: player.points,
      isHost: player.isHost,
      hasSubmitted: player.hasSubmitted,
      hasReviewed: player.hasReviewed,
    })),
    prompt: room.prompt,
    roundEndsAt: room.roundEndsAt,
    mySubmittedWords: mySubmission,
    myApprovedWords: myReview,
    reviewSubmissions,
    roundResults: room.phase === 'results' ? buildRoundResults(room) : [],
  };
}

function emitRoomState(room) {
  for (const player of room.players) {
    const socketId = player.id;
    const socket = io.sockets.sockets.get(socketId);
    if (socket) {
      socket.emit('room_state', serializeRoom(room, socketId));
    }
  }
}

function removePlayerFromRoom(socketId) {
  const roomCode = socketToRoom.get(socketId);
  if (!roomCode) {
    return;
  }

  const room = rooms.get(roomCode);
  if (!room) {
    return;
  }

  room.players = room.players.filter((player) => player.id !== socketId);
  delete room.submissions[socketId];
  delete room.reviews[socketId];
  socketToRoom.delete(socketId);
  socketToPlayer.delete(socketId);

  if (room.players.length === 0) {
    rooms.delete(roomCode);
    return;
  }

  if (room.hostId === socketId) {
    room.hostId = room.players[0].id;
    room.players[0].isHost = true;
  }

  if (room.phase === 'playing' || room.phase === 'review') {
    room.phase = 'lobby';
    resetRoundState(room);
  }

  emitRoomState(room);
}

function maybeAdvanceFromPlaying(room) {
  const allSubmitted = room.players.every((player) => player.hasSubmitted);
  if (!allSubmitted) {
    return;
  }

  room.phase = 'review';
  for (const player of room.players) {
    const words = room.submissions[player.id] || [];
    room.reviews[player.id] = [...words];
    player.hasReviewed = false;
  }
  emitRoomState(room);
}

function finalizeReview(room) {
  for (const player of room.players) {
    const approvedWords = room.reviews[player.id] || [];
    const roundScore = approvedWords.length;
    player.points += roundScore;
    room.roundScores[player.id] = roundScore;
    player.hasReviewed = true;
  }

  room.phase = 'results';
  emitRoomState(room);
}

const app = express();
app.set('trust proxy', 1);
app.use(cors());
app.get('/health', (_req, res) => {
  res.json({ ok: true, rooms: rooms.size });
});

function getLanAddresses() {
  const interfaces = os.networkInterfaces();
  const addresses = [];

  for (const entries of Object.values(interfaces)) {
    for (const entry of entries ?? []) {
      if (entry.family === 'IPv4' && !entry.internal) {
        addresses.push(entry.address);
      }
    }
  }

  return addresses;
}

app.get('/network-info', (req, res) => {
  const forwardedProto = req.headers['x-forwarded-proto'];
  const forwardedHost = req.headers['x-forwarded-host'];
  const host = forwardedHost || req.get('host');
  const protocol = forwardedProto || req.protocol;

  if (host && !host.startsWith('localhost') && !host.startsWith('127.0.0.1')) {
    const baseUrl = `${protocol}://${host}`;
    res.json({
      primaryIp: host,
      ips: [host],
      appPort: protocol === 'https' ? 443 : 80,
      baseUrl,
      public: true,
    });
    return;
  }

  const ips = getLanAddresses();
  const appPort = Number(req.query.appPort || PORT);
  const primaryIp = ips[0] || 'localhost';

  res.json({
    primaryIp,
    ips,
    appPort,
    baseUrl: `http://${primaryIp}:${appPort}`,
    public: false,
  });
});

function mountWebApp() {
  if (!fs.existsSync(WEB_ROOT)) {
    console.log('Web build not found. API-only mode.');
    return;
  }

  app.use(express.static(WEB_ROOT));
  app.get('*', (_req, res) => {
    res.sendFile(path.join(WEB_ROOT, 'index.html'));
  });

  console.log(`Serving web app from ${WEB_ROOT}`);
}

mountWebApp();

const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  transports: ['websocket', 'polling'],
});

io.on('connection', (socket) => {
  socket.on('create_room', ({ settings, playerName }, callback) => {
    const code = generateRoomCode();
    const player = createPlayer(socket.id, playerName, true);

    const room = {
      code,
      hostId: socket.id,
      settings,
      phase: 'lobby',
      roundIndex: 0,
      players: [player],
      prompt: null,
      roundEndsAt: null,
      submissions: {},
      reviews: {},
      roundScores: {},
    };

    rooms.set(code, room);
    socketToRoom.set(socket.id, code);
    socketToPlayer.set(socket.id, socket.id);
    socket.join(code);

    const payload = serializeRoom(room, socket.id);
    callback?.({ ok: true, room: payload });
    emitRoomState(room);
  });

  socket.on('join_room', ({ code, playerName }, callback) => {
    const room = rooms.get(code);
    if (!room) {
      callback?.({ ok: false, error: 'الغرفة غير موجودة' });
      return;
    }

    if (room.phase !== 'lobby') {
      callback?.({ ok: false, error: 'الجولة جارية بالفعل' });
      return;
    }

    if (room.players.some((player) => player.name === playerName)) {
      callback?.({ ok: false, error: 'الاسم مستخدم في الغرفة' });
      return;
    }

    const player = createPlayer(socket.id, playerName, false);
    room.players.push(player);
    socketToRoom.set(socket.id, code);
    socketToPlayer.set(socket.id, socket.id);
    socket.join(code);

    const payload = serializeRoom(room, socket.id);
    callback?.({ ok: true, room: payload });
    emitRoomState(room);
  });

  socket.on('start_round', (_payload, callback) => {
    const roomCode = socketToRoom.get(socket.id);
    const room = rooms.get(roomCode || '');
    if (!room || room.hostId !== socket.id) {
      callback?.({ ok: false, error: 'غير مصرح' });
      return;
    }

    if (room.phase !== 'lobby' && room.phase !== 'results') {
      callback?.({ ok: false, error: 'لا يمكن بدء الجولة الآن' });
      return;
    }

    if (room.phase === 'results') {
      room.roundIndex += 1;
      if (room.roundIndex >= room.settings.numberOfRounds) {
        room.phase = 'finished';
        emitRoomState(room);
        callback?.({ ok: true });
        return;
      }
    }

    resetRoundState(room);
    room.phase = 'playing';
    room.prompt = getPrompt(room.roundIndex);
    room.roundEndsAt = Date.now() + room.settings.roundDurationSeconds * 1000;

    emitRoomState(room);
    callback?.({ ok: true });

    setTimeout(() => {
      const currentRoom = rooms.get(room.code);
      if (!currentRoom || currentRoom.phase !== 'playing') {
        return;
      }

      for (const player of currentRoom.players) {
        if (!player.hasSubmitted) {
          currentRoom.submissions[player.id] = currentRoom.submissions[player.id] || [];
          player.hasSubmitted = true;
        }
      }

      currentRoom.phase = 'review';
      for (const player of currentRoom.players) {
        const words = currentRoom.submissions[player.id] || [];
        currentRoom.reviews[player.id] = [...words];
        player.hasReviewed = false;
      }
      emitRoomState(currentRoom);
    }, room.settings.roundDurationSeconds * 1000);
  });

  socket.on('submit_words', ({ words }, callback) => {
    const roomCode = socketToRoom.get(socket.id);
    const room = rooms.get(roomCode || '');
    if (!room || room.phase !== 'playing') {
      callback?.({ ok: false, error: 'لا يمكن الإرسال الآن' });
      return;
    }

    const player = room.players.find((entry) => entry.id === socket.id);
    if (!player || player.hasSubmitted) {
      callback?.({ ok: false, error: 'تم الإرسال مسبقاً' });
      return;
    }

    room.submissions[socket.id] = words;
    player.hasSubmitted = true;
    emitRoomState(room);
    maybeAdvanceFromPlaying(room);
    callback?.({ ok: true });
  });

  socket.on('approve_results', ({ reviews }, callback) => {
    const roomCode = socketToRoom.get(socket.id);
    const room = rooms.get(roomCode || '');
    if (!room || room.phase !== 'review') {
      callback?.({ ok: false, error: 'لا يمكن الاعتماد الآن' });
      return;
    }

    if (room.hostId !== socket.id) {
      callback?.({
        ok: false,
        error: 'فقط مسؤول الغرفة يمكنه اعتماد الكلمات',
      });
      return;
    }

    if (!reviews || typeof reviews !== 'object') {
      callback?.({ ok: false, error: 'بيانات الاعتماد غير صالحة' });
      return;
    }

    for (const player of room.players) {
      const approvedWords = reviews[player.id];
      if (!Array.isArray(approvedWords)) {
        callback?.({ ok: false, error: 'بيانات الاعتماد غير مكتملة' });
        return;
      }
      room.reviews[player.id] = approvedWords;
    }

    finalizeReview(room);
    callback?.({ ok: true });
  });

  socket.on('leave_room', () => {
    removePlayerFromRoom(socket.id);
  });

  socket.on('disconnect', () => {
    removePlayerFromRoom(socket.id);
  });
});

httpServer.listen(PORT, () => {
  console.log(`Word Challenge server running on http://localhost:${PORT}`);
});
