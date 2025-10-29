import express from "express";
import bcrypt from "bcryptjs";
import { db, findUser } from "../db.js";

const router = express.Router();

router.post("/register", async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ msg: "Thiếu username hoặc password" });
  if (findUser(username)) return res.status(400).json({ msg: "Username đã tồn tại" });

  const hashed = await bcrypt.hash(password, 10);
  db.data.users.push({
    username,
    password: hashed,
    profile: { displayName: username, avatarUrl: null, status: "Hello!" },
    friends: [], blocked: [], pendingRequests: []
  });
  await db.write();
  res.json({ msg: "success" });
});

router.post("/login", async (req, res) => {
  const { username, password } = req.body;
  const user = findUser(username);
  if (!user) return res.status(400).json({ msg: "User không tồn tại" });
  const match = await bcrypt.compare(password, user.password);
  if (!match) return res.status(400).json({ msg: "Sai mật khẩu" });
  res.json({ msg: "success", username });
});

export default router;
