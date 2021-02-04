FROM node:alpine
WORKDIR /replays
WORKDIR /discordbot/persistent
WORKDIR /discordbot
RUN npm install chokidar discord.js
ADD discordbot.js .
CMD ["node", "discordbot.js"]
