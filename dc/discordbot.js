const pathToReplays = '/replays/';
const pathToSentLog = './persistent/sentLog.json';
const PathToSecrets = './persistent/secrets.json';

const fs = require('fs');
const creds = require(PathToSecrets);
const chokidar = require('chokidar');
const Discord = require('discord.js');
const client = new Discord.Client();

var uploadHistory;
try {
  uploadHistory = require(pathToSentLog);
  if (!Array.isArray(uploadHistory.list)) {
      uploadHistory = {"list":[]};
  }
} catch(err) {
  console.error(err);
  uploadHistory = {"list":[]};
}

client.login(creds.token);
console.log(creds.token);
console.log(creds.channelID);

client.on('ready', () => {
    console.log(`Logged in as ${client.user.tag}!`);
    chokidar.watch(pathToReplays).on('add', (path, event) => {
        console.log("new file " + path);
        if ( path.endsWith(".rep") && !(uploadHistory.list.includes(path)) ) {
            console.log("haven't seen " + path + " before. Uploading...");
            const attachment = new Discord.MessageAttachment(path);
            client.channels.cache.get(creds.channelID).send(attachment)
                .then(console.log)
                .catch(console.error);
            uploadHistory.list.push(path);
            fs.writeFileSync(pathToSentLog, JSON.stringify(uploadHistory, null, 2));
        }
    });
});
