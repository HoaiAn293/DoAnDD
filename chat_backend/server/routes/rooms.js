import express from "express";
import bcrypt from "bcryptjs";
import { db } from "../db.js";

const router = express.Router();

// Lấy danh sách rooms
router.get("/", (req, res) => {
  const rooms = db.data.rooms.map(({ id, name, type, creator }) => ({ id, name, type, creator }));
  res.json(rooms);
});

// Tạo room
router.post("/", async (req, res) => {
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
  res.json({ msg: "success", id: room.id });
});

export default router;
