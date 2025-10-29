import { db, getMembersInRoom } from "../db.js";

export default function socketChat(io) {
  io.on("connection", socket => {
    console.log("Kết nối mới:", socket.id);

    socket.on("joinGroup", async ({ groupId, username }) => {
      if (!groupId || !username) return;

      socket.join(groupId);
      socket.username = username;
      socket.groupId = groupId;

      db.data.messages ||= [];
      const history = db.data.messages.filter(m => m.groupId === groupId);
      socket.emit("chatHistory", history);

      const members = getMembersInRoom(io, groupId);
      io.to(groupId).emit("members", members);
      io.to(groupId).emit("status", { groupId, message: `${username} vừa vào phòng` });
    });

    socket.on("message", async ({ groupId, username, message, image, time }) => {
      if (!groupId || !username || (!message && !image)) return;

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
      const members = getMembersInRoom(io, groupId);
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
        const members = getMembersInRoom(io, groupId);
        io.to(groupId).emit("roomInfo", { groupId, members, count: members.length });
        io.to(groupId).emit("status", { groupId, message: `${username || "Một người"} mất kết nối` });
      }
    });
  });
}
