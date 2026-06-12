// backend/src/services/websocketService.js
const wsClients = new Map(); // userId -> Set of WS connections

const registerClient = (userId, ws) => {
  const userIdStr = userId.toString();
  if (!wsClients.has(userIdStr)) {
    wsClients.set(userIdStr, new Set());
  }
  wsClients.get(userIdStr).add(ws);
  console.log(`👤 Conexión WS registrada para usuario: ${userIdStr}`);
};

const unregisterClient = (ws) => {
  for (const [userId, connSet] of wsClients.entries()) {
    if (connSet.has(ws)) {
      connSet.delete(ws);
      if (connSet.size === 0) wsClients.delete(userId);
      console.log(`🔌 Conexión WS removida para usuario: ${userId}`);
      break;
    }
  }
};

const notifyUserJobUpdate = (userId, jobData) => {
  const userIdStr = userId.toString();
  if (wsClients.has(userIdStr)) {
    const payload = JSON.stringify({
      type: 'nail_tryon_update',
      data: {
        id: jobData.id,
        status: jobData.status,
        preview_url: jobData.preview_url,
        error_message: jobData.error_message
      }
    });
    for (const conn of wsClients.get(userIdStr)) {
      if (conn.readyState === 1) { // OPEN
        conn.send(payload);
      }
    }
  }
};

const notifyUserChatMessage = (userId, messageData) => {
  const userIdStr = userId.toString();
  if (wsClients.has(userIdStr)) {
    const payload = JSON.stringify({
      type: 'chat_message',
      data: messageData
    });
    for (const conn of wsClients.get(userIdStr)) {
      if (conn.readyState === 1) { // OPEN
        conn.send(payload);
      }
    }
  }
};

module.exports = {
  registerClient,
  unregisterClient,
  notifyUserJobUpdate,
  notifyUserChatMessage
};
