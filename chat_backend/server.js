import express from "express";
import http from "http";
import { Server } from "socket.io";
import cors from "cors";
import bcrypt from "bcryptjs";
import multer from "multer";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import { Low, JSONFile } from "lowdb";

// ==== Cấu hình cơ bản ====
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

app.use(cors());
app.use(express.json());

// ==== Upload Ảnh (multer) ====
const uploadDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir);

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => cb(null, Date.now() + "-" + file.originalname),
});
const upload = multer({ storage });
app.use("/uploads", express.static(uploadDir));

// ==== Database (LowDB) ====
const dbFile = path.join(__dirname, "db.json");
const adapter = new JSONFile(dbFile);
const db = new Low(adapter);
await db.read();
db.data ||= { users: [], rooms: [], messages: [] };

// ==== Helper ====
function findUser(username) {
  return db.data.users.find(u => u.username === username);
}

// Lấy danh sách username đang online trong room
function getMembersInRoom(groupId) {
  const set = io.sockets.adapter.rooms.get(groupId) || new Set();
  return Array.from(set)
    .map(sid => io.sockets.sockets.get(sid)?.username)
    .filter(Boolean);
}

// ==== AUTH ====
app.post("/register", async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ msg: "Thiếu username hoặc password" });
  if (findUser(username)) return res.status(400).json({ msg: "Username đã tồn tại" });

  const hashed = await bcrypt.hash(password, 10);
  db.data.users.push({
    username,
    password: hashed,
    profile: { displayName: username, avatarUrl: null, status: "Hello!" },
    friends: [],
    blocked: [],
    pendingRequests: [],
  });
  await db.write();
  res.json({ msg: "success" });
});

app.post("/login", async (req, res) => {
  const { username, password } = req.body;
  const user = findUser(username);
  if (!user) return res.status(400).json({ msg: "User không tồn tại" });
  const match = await bcrypt.compare(password, user.password);
  if (!match) return res.status(400).json({ msg: "Sai mật khẩu" });
  res.json({ msg: "success", username });
});

// ==== PROFILE & FRIENDS ====
app.get("/profile/:username", async (req, res) => {
  const user = findUser(req.params.username);
  if (!user) return res.status(404).json({ msg: "User không tồn tại" });
  res.json({
    username: user.username,
    displayName: user.profile.displayName,
    friends: user.friends || [],
  });
});

// Tìm kiếm user
app.get("/users", async (req, res) => {
  const q = (req.query.q || "").toLowerCase();
  const results = db.data.users.filter(u =>
    u.username.toLowerCase().includes(q) ||
    (u.profile.displayName || "").toLowerCase().includes(q)
  );
  res.json(results.map(u => ({ username: u.username, displayName: u.profile.displayName })));
});

// Friend requests
app.get("/friend-requests/:username", async (req, res) => {
  const user = findUser(req.params.username);
  if (!user) return res.status(404).json({ msg: "User không tồn tại" });
  res.json({ pending: user.pendingRequests || [] });
});

app.post("/friend-request", async (req, res) => {
  const { from, to } = req.body;
  const sender = findUser(from);
  const receiver = findUser(to);
  if (!sender || !receiver) return res.status(400).json({ msg: "User không tồn tại" });

  receiver.pendingRequests ||= [];
  if (!receiver.pendingRequests.includes(from)) receiver.pendingRequests.push(from);
  await db.write();
  res.json({ msg: "success" });
});

app.post("/friend-accept", async (req, res) => {
  const { from, to } = req.body;
  const sender = findUser(from);
  const receiver = findUser(to);
  if (!sender || !receiver) return res.status(400).json({ msg: "User không tồn tại" });

  receiver.pendingRequests ||= [];
  receiver.friends ||= [];
  sender.friends ||= [];

  receiver.pendingRequests = receiver.pendingRequests.filter(u => u !== from);
  if (!receiver.friends.includes(from)) receiver.friends.push(from);
  if (!sender.friends.includes(to)) sender.friends.push(to);
  await db.write();
  res.json({ msg: "success" });
});

app.post("/friend-remove", async (req, res) => {
  const { username, friend } = req.body;
  const user = findUser(username);
  const f = findUser(friend);
  if (!user || !f) return res.status(400).json({ msg: "User không tồn tại" });

  user.friends = (user.friends || []).filter(u => u !== friend);
  f.friends = (f.friends || []).filter(u => u !== username);
  await db.write();
  res.json({ msg: "success" });
});

app.post("/block", async (req, res) => {
  const { by, target } = req.body;
  const user = findUser(by);
  const t = findUser(target);
  if (!user || !t) return res.status(400).json({ msg: "User không tồn tại" });

  user.blocked ||= [];
  if (!user.blocked.includes(target)) user.blocked.push(target);

  user.friends = (user.friends || []).filter(u => u !== target);
  t.friends = (t.friends || []).filter(u => u !== by);

  await db.write();
  res.json({ msg: "success" });
});

// ==== ROOMS ====
app.get("/rooms", (req, res) => {
  const rooms = db.data.rooms.map(({ id, name, type, creator }) => ({ id, name, type, creator }));
  res.json(rooms);
});

app.post("/rooms", async (req, res) => {
  const { name, type, password, creator } = req.body;
  if (!name || !type || !creator) return res.status(400).json({ msg: "Thiếu thông tin" });

  let passwordHash = null;
  if (type === "private") {
    if (!password) return res.status(400).json({ msg: "Phòng riêng tư cần mật khẩu" });
    passwordHash = await bcrypt.hash(password, 10);
  }

  const room = { id: Date.now().toString(), name, type, passwordHash, creator };
  db.data.rooms.push(room);
  await db.write();

  io.emit("roomListUpdate", db.data.rooms.map(({ id, name, type, creator }) => ({ id, name, type, creator })));
  res.json({ msg: "success", id: room.id });
});




// ==== MESSAGES API ====
app.get("/messages/:groupId", async (req, res) => {
  const { groupId } = req.params;
  await db.read();
  db.data.messages ||= [];
  const messages = db.data.messages.filter(m => m.groupId === groupId);
  res.json(messages);
});

// ==== SOCKET.IO ====
io.on("connection", socket => {
  console.log("Kết nối mới:", socket.id);

  socket.on("joinGroup", async ({ groupId, username }) => {
    if (!groupId || !username) return;

    socket.join(groupId);
    socket.username = username;
    socket.groupId = groupId;

    await db.read();
    db.data.messages ||= [];
    const history = db.data.messages.filter(m => m.groupId === groupId);
    socket.emit("chatHistory", history);

    // thông báo số người online
    const members = getMembersInRoom(groupId);
    io.to(groupId).emit("members", members);
    io.to(groupId).emit("status", { groupId, message: `${username} vừa vào phòng` });
  });

  socket.on("message", async ({ groupId, username, message, image, time }) => {
    if (!groupId || !username || (!message && !image)) return;

    await db.read();
    db.data.messages ||= [];
    const msg = { id: Date.now().toString(), groupId, username, message: message || "", image: image || null, time: time || new Date().toISOString() };
    db.data.messages.push(msg);
    await db.write();

    io.to(groupId).emit("message", msg);
  });

  socket.on("leaveGroup", () => {
    const { groupId, username } = socket;
    if (!groupId) return;

    socket.leave(groupId);
    const members = getMembersInRoom(groupId);
    io.to(groupId).emit("roomInfo", { groupId, members, count: members.length });
    io.to(groupId).emit("status", { groupId, message: `${username || "Một người"} vừa rời phòng` });
  });

  socket.on("typing", data => {
    if (!data?.groupId) return;
    io.to(data.groupId).emit("typing", data);
  });

  socket.on("disconnect", () => {
    const { groupId, username } = socket;
    if (groupId) {
      const members = getMembersInRoom(groupId);
      io.to(groupId).emit("roomInfo", { groupId, members, count: members.length });
      io.to(groupId).emit("status", { groupId, message: `${username || "Một người"} mất kết nối` });
    }
  });
});

// ==== Upload ảnh ====
app.post("/upload", upload.single("image"), (req, res) => {
  if (!req.file) return res.status(400).json({ msg: "No file" });
  const host = req.get("host"); 
  const protocol = req.protocol; 
  const url = `${protocol}://${host}/uploads/${req.file.filename}`;
  res.json({ msg: "success", url });
});

// ==== Khởi động server ====
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Server chạy tại http://localhost:${PORT}`));
