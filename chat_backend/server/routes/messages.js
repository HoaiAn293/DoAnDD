import express from "express";
import { db } from "../db.js";

const router = express.Router();

router.get("/:groupId", async (req, res) => {
  const { groupId } = req.params;
  db.data.messages ||= [];
  const messages = db.data.messages.filter(m => m.groupId === groupId);
  res.json(messages);
});

export default router;
