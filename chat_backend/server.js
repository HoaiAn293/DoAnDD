const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const bcrypt = require('bcryptjs');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

app.use(cors());
app.use(express.json());

// ================== DỮ LIỆU TẠM ==================
let users = []; 
let rooms = []; 

// ================== AUTH ==================

//Đăng ký
app.post('/register', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password)
    return res.status(400).json({ msg: 'Username và password không được để trống' });

  if (users.find(u => u.username === username))
    return res.status(400).json({ msg: 'Username đã tồn tại' });

  const hashed = await bcrypt.hash(password, 10);
  users.push({ username, password: hashed });
  console.log(`Người dùng mới đăng ký: ${username}`);
  res.json({ msg: 'success' });
});

//Đăng nhập
app.post('/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password)
    return res.status(400).json({ msg: 'Username và password không được để trống' });

  const user = users.find(u => u.username === username);
  if (!user) return res.status(400).json({ msg: 'User không tồn tại' });

  const match = await bcrypt.compare(password, user.password);
  if (!match) return res.status(400).json({ msg: 'Sai mật khẩu' });

  console.log(`✅ ${username} vừa đăng nhập thành công`);
  res.json({ msg: 'success', username });
});

// ================== PHÒNG CHAT ==================

//Lấy danh sách phòng
app.get('/rooms', (req, res) => {
  const publicData = rooms.map(r => ({
    id: r.id,
    name: r.name,
    type: r.type,
    creator: r.creator
  }));
  res.json(publicData);
});

//Tạo phòng
app.post('/rooms', async (req, res) => {
  const { name, type, password, creator } = req.body;

  if (!name || !type || !creator)
    return res.status(400).json({ msg: 'Thiếu thông tin' });

  let passwordHash = null;
  if (type === 'private') {
    if (!password) return res.status(400).json({ msg: 'Phòng riêng tư cần mật khẩu' });
    passwordHash = await bcrypt.hash(password, 10);
  }

  const room = {
    id: Date.now().toString(),
    name,
    type,
    passwordHash,
    creator
  };
  rooms.push(room);

  console.log(`🏠 ${creator} vừa tạo phòng "${name}" (${type})`);

  io.emit('roomListUpdate', rooms.map(r => ({
    id: r.id,
    name: r.name,
    type: r.type,
    creator: r.creator
  })));

  res.json({ msg: 'success', id: room.id });
});

//Kiểm tra mật khẩu phòng riêng tư
app.post('/rooms/check', async (req, res) => {
  const { roomId, password } = req.body;
  const room = rooms.find(r => r.id === roomId);

  if (!room) return res.status(404).json({ msg: 'Không tìm thấy phòng' });
  if (room.type === 'public') return res.json({ msg: 'success' });

  const match = await bcrypt.compare(password, room.passwordHash);
  if (!match) return res.status(400).json({ msg: 'Sai mật khẩu' });

  res.json({ msg: 'success' });
});

// ================== SOCKET.IO ==================
io.on('connection', socket => {
  console.log('🔗 Người dùng kết nối:', socket.id);

  socket.on('joinGroup', ({ groupId, username }) => {
    socket.join(groupId);
    console.log(`👤 ${username} vừa vào phòng ID ${groupId}`);
    io.to(groupId).emit('status', `${username} vừa vào nhóm`);
  });

  socket.on('message', ({ groupId, username, message }) => {
    console.log(`💬 [${groupId}] ${username}: ${message}`);
    io.to(groupId).emit('message', { sender: username, message });
  });

  socket.on('disconnect', () => {
    console.log('❌ Người dùng rời:', socket.id);
  });
});

server.listen(3000, () => console.log('✅ Server chạy ở http://localhost:3000'));
