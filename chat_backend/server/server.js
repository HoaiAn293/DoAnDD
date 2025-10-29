import express from "express";
import http from "http";
import { Server } from "socket.io";
import cors from "cors";

import authRoutes from "./routes/auth.js";
import profileRoutes from "./routes/profile.js";
import roomsRoutes from "./routes/rooms.js";
import messagesRoutes from "./routes/messages.js";
import uploadRoutes from "./routes/upload.js";
import socketChat from "./sockets/chat.js";

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

app.use(cors());
app.use(express.json());
app.use("/uploads", express.static("uploads"));

app.use("/auth", authRoutes);
app.use("/profile", profileRoutes);
app.use("/rooms", roomsRoutes);
app.use("/messages", messagesRoutes);
app.use("/upload", uploadRoutes);

socketChat(io);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Server chạy tại http://localhost:${PORT}`));
