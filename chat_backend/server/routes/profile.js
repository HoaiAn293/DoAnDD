import express from "express";
import { db, findUser } from "../db.js";

const router = express.Router();

router.get("/profile/:username", (req, res) => {
  const user = findUser(req.params.username);
  if (!user) return res.status(404).json({ msg: "User không tồn tại" });
  res.json({
    username: user.username,
    displayName: user.profile.displayName,
    friends: user.friends || [],
  });
});

router.get("/users", (req, res) => {
  const q = (req.query.q || "").toLowerCase();
  const results = db.data.users.filter(u =>
    u.username.toLowerCase().includes(q) ||
    (u.profile.displayName || "").toLowerCase().includes(q)
  );
  res.json(results.map(u => ({ username: u.username, displayName: u.profile.displayName })));
});

// Friend request, accept, remove, block
router.get("/friend-requests/:username", (req, res) => {
  const user = findUser(req.params.username);
  if (!user) return res.status(404).json({ msg: "User không tồn tại" });
  res.json({ pending: user.pendingRequests || [] });
});

// POST friend-request
router.post("/friend-request", async (req, res) => {
  const { from, to } = req.body;
  const sender = findUser(from);
  const receiver = findUser(to);
  if (!sender || !receiver) return res.status(400).json({ msg: "User không tồn tại" });
  receiver.pendingRequests ||= [];
  if (!receiver.pendingRequests.includes(from)) receiver.pendingRequests.push(from);
  await db.write();
  res.json({ msg: "success" });
});

// POST friend-accept
router.post("/friend-accept", async (req, res) => {
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

// POST friend-remove
router.post("/friend-remove", async (req, res) => {
  const { username, friend } = req.body;
  const user = findUser(username);
  const f = findUser(friend);
  if (!user || !f) return res.status(400).json({ msg: "User không tồn tại" });

  user.friends = (user.friends || []).filter(u => u !== friend);
  f.friends = (f.friends || []).filter(u => u !== username);
  await db.write();
  res.json({ msg: "success" });
});

// POST block
router.post("/block", async (req, res) => {
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

export default router;
