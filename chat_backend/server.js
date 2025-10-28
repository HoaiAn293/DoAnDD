const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

// lowdb
const { Low, JSONFile } = require("lowdb");

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

app.use(cors());
app.use(express.json());

// multer / uploads
const uploadDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir);
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => cb(null, Date.now() + "-" + file.originalname),
});
const upload = multer({ storage });
app.use("/uploads", express.static(uploadDir));

// Setup lowdb
const dbFile = path.join(__dirname, "db.json");
const adapter = new JSONFile(dbFile);
const db = new Low(adapter);

(async () => {
  // đọc/khởi tạo db
  await db.read();
  db.data ||= { users: [], rooms: [] };

  // helper
  function findUser(username) {
    return db.data.users.find((u) => u.username === username);
  }

  // Đăng ký (lưu vào db)
  app.post("/register", async (req, res) => {
    const { username, password } = req.body;
    if (!username || !password)
      return res
        .status(400)
        .json({ msg: "Username và password không được để trống" });
    if (findUser(username))
      return res.status(400).json({ msg: "Username đã tồn tại" });

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
    console.log(`Người dùng mới đăng ký: ${username}`);
    res.json({ msg: "success" });
  });

  app.post("/login", async (req, res) => {
    const { username, password } = req.body;
    if (!username || !password)
      return res
        .status(400)
        .json({ msg: "Username và password không được để trống" });

    const user = findUser(username);
    if (!user) return res.status(400).json({ msg: "User không tồn tại" });

    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(400).json({ msg: "Sai mật khẩu" });

    console.log(`✅ ${username} vừa đăng nhập thành công`);
    res.json({ msg: "success", username });
  });

  // Lấy profile công khai
  app.get("/profile/:username", (req, res) => {
    const { username } = req.params;
    const user = findUser(username);
    if (!user) return res.status(404).json({ msg: "Không tìm thấy user" });
    const { displayName, avatarUrl, status } = user.profile;
    res.json({
      username,
      displayName,
      avatarUrl,
      status,
      friends: user.friends,
    });
  });

  // Cập nhật profile
  app.put("/profile", async (req, res) => {
    const { username, displayName, avatarUrl, status } = req.body;
    const user = findUser(username);
    if (!user) return res.status(404).json({ msg: "Không tìm thấy user" });
    user.profile.displayName = displayName ?? user.profile.displayName;
    user.profile.avatarUrl = avatarUrl ?? user.profile.avatarUrl;
    user.profile.status = status ?? user.profile.status;
    await db.write();
    res.json({ msg: "success", profile: user.profile });
  });

  // Tìm kiếm user
  app.get("/users", (req, res) => {
    const q = (req.query.q || "").toLowerCase();
    const list = db.data.users
      .filter(
        (u) =>
          u.username.toLowerCase().includes(q) ||
          (u.profile.displayName || "").toLowerCase().includes(q)
      )
      .map((u) => ({
        username: u.username,
        displayName: u.profile.displayName,
        avatarUrl: u.profile.avatarUrl,
      }));
    res.json(list);
  });

  // Gửi lời mời kết bạn
  app.post("/friend-request", async (req, res) => {
    const { from, to } = req.body;
    const userFrom = findUser(from);
    const userTo = findUser(to);
    if (!userFrom || !userTo)
      return res.status(404).json({ msg: "User không tồn tại" });
    if (userTo.blocked.includes(from) || userFrom.blocked.includes(to))
      return res.status(400).json({ msg: "Không thể gửi yêu cầu" });
    if (userTo.pendingRequests.includes(from) || userTo.friends.includes(from))
      return res.status(400).json({ msg: "Đã gửi hoặc đã là bạn" });
    userTo.pendingRequests.push(from);
    await db.write();
    res.json({ msg: "success" });
  });

  // Lấy danh sách yêu cầu kết bạn
  app.get("/friend-requests/:username", (req, res) => {
    const u = findUser(req.params.username);
    if (!u) return res.status(404).json({ msg: "User không tồn tại" });
    res.json({ pending: u.pendingRequests });
  });

  // Chấp nhận lời mời
  app.post("/friend-accept", async (req, res) => {
    const { from, to } = req.body; // from = người gửi, to = người nhận (chấp nhận)
    const userFrom = findUser(from);
    const userTo = findUser(to);
    if (!userFrom || !userTo)
      return res.status(404).json({ msg: "User không tồn tại" });
    const idx = userTo.pendingRequests.indexOf(from);
    if (idx === -1) return res.status(400).json({ msg: "Không có lời mời" });
    userTo.pendingRequests.splice(idx, 1);
    if (!userTo.friends.includes(from)) userTo.friends.push(from);
    if (!userFrom.friends.includes(to)) userFrom.friends.push(to);
    await db.write();
    res.json({ msg: "success" });
  });

  // Xóa bạn
  app.post("/friend-remove", async (req, res) => {
    const { username, friend } = req.body;
    const u = findUser(username),
      f = findUser(friend);
    if (!u || !f) return res.status(404).json({ msg: "User không tồn tại" });
    u.friends = u.friends.filter((x) => x !== friend);
    f.friends = f.friends.filter((x) => x !== username);
    await db.write();
    res.json({ msg: "success" });
  });

  // Chặn user
  app.post("/block", async (req, res) => {
    const { by, target } = req.body;
    const a = findUser(by),
      b = findUser(target);
    if (!a || !b) return res.status(404).json({ msg: "User không tồn tại" });
    if (!a.blocked.includes(target)) a.blocked.push(target);
    a.friends = a.friends.filter((x) => x !== target);
    b.friends = b.friends.filter((x) => x !== by);
    a.pendingRequests = a.pendingRequests.filter((x) => x !== target);
    b.pendingRequests = b.pendingRequests.filter((x) => x !== by);
    await db.write();
    res.json({ msg: "success" });
  });

  // Lấy danh sách phòng
  app.get("/rooms", (req, res) => {
    const publicData = db.data.rooms.map((r) => ({
      id: r.id,
      name: r.name,
      type: r.type,
      creator: r.creator,
    }));
    res.json(publicData);
  });

  // Tạo phòng (lưu vào db)
  app.post("/rooms", async (req, res) => {
    const { name, type, password, creator } = req.body;
    if (!name || !type || !creator)
      return res.status(400).json({ msg: "Thiếu thông tin" });

    let passwordHash = null;
    if (type === "private") {
      if (!password)
        return res.status(400).json({ msg: "Phòng riêng tư cần mật khẩu" });
      passwordHash = await bcrypt.hash(password, 10);
    }

    const room = {
      id: Date.now().toString(),
      name,
      type,
      passwordHash,
      creator,
    };
    db.data.rooms.push(room);
    await db.write();

    console.log(`🏠 ${creator} vừa tạo phòng "${name}" (${type})`);

    io.emit(
      "roomListUpdate",
      db.data.rooms.map((r) => ({
        id: r.id,
        name: r.name,
        type: r.type,
        creator: r.creator,
      }))
    );

    res.json({ msg: "success", id: room.id });
  });

  // Kiểm tra mật khẩu phòng riêng tư
  app.post("/rooms/check", async (req, res) => {
    const { roomId, password } = req.body;
    const room = db.data.rooms.find((r) => r.id === roomId);
    if (!room) return res.status(404).json({ msg: "Không tìm thấy phòng" });
    if (room.type === "public") return res.json({ msg: "success" });
    const match = await bcrypt.compare(password, room.passwordHash);
    if (!match) return res.status(400).json({ msg: "Sai mật khẩu" });
    res.json({ msg: "success" });
  });

  app.post("/upload", upload.single("image"), (req, res) => {
    if (!req.file) return res.status(400).json({ msg: "No file" });
    const url = `http://localhost:3000/uploads/${req.file.filename}`;
    console.log("Uploaded:", req.file.filename);
    return res.json({ msg: "success", url });
  });

  io.on("connection", (socket) => {
    console.log("🔗 Người dùng kết nối:", socket.id);

    socket.on("presence", ({ username }) => {
      socket.username = username;
      io.emit("presence", { username, online: true });
    });

    socket.on("joinGroup", ({ groupId, username }) => {
      socket.join(groupId);
      console.log(`👤 ${username} vừa vào phòng ID ${groupId}`);
      io.to(groupId).emit("status", `${username} vừa vào nhóm`);
    });

    socket.on("typing", ({ groupId, username, typing }) => {
      io.to(groupId).emit("typing", { groupId, username, typing });
    });

    socket.on("message", ({ groupId, username, message, image }) => {
      console.log(
        `💬 [${groupId}] ${username}: ${message}${image ? " [image]" : ""}`
      );
      io.to(groupId).emit("message", { sender: username, message, image });
    });

    socket.on("privateMessage", ({ toSocketId, from, message }) => {
      socket.to(toSocketId).emit("privateMessage", { from, message });
    });

    socket.on("disconnect", () => {
      console.log("❌ Người dùng rời:", socket.id);
      if (socket.username)
        io.emit("presence", { username: socket.username, online: false });
    });
  });

  server.listen(3000, () =>
    console.log("✅ Server chạy ở http://localhost:3000")
  );
})();
