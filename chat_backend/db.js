import { Low, JSONFile } from "lowdb";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const dbFile = path.join(__dirname, "db.json");
const adapter = new JSONFile(dbFile);
export const db = new Low(adapter);

await db.read();
db.data ||= { users: [], rooms: [], messages: [], posts: [] };

export function findUser(username) {
  return db.data.users.find(u => u.username === username);
}

export function getMembersInRoom(io, groupId) {
  const set = io.sockets.adapter.rooms.get(groupId) || new Set();
  return Array.from(set)
    .map(sid => io.sockets.sockets.get(sid)?.username)
    .filter(Boolean);
}
