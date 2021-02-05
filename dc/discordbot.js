const pathToReplays = '/replays/';
const pathToSentLog = './persistent/sentLog.json';
const pathToSecrets = './persistent/secrets.json';

const fs = require('fs');
const path = require('path');
const creds = require(pathToSecrets);
const compressing = require('compressing');
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
    chokidar.watch(pathToReplays).on('add', (filepath, event) => {
        console.log("New file? " + filepath);
        if ( filepath.endsWith(".rep") && !(uploadHistory.list.includes(filepath)) ) {
            const filename = path.basename(filepath, path.extname(filepath));
            const destfile = pathToReplays+filename+".zip";
            console.log("Haven't seen " + filename + " before. Uploading...");
            compressing.zip.compressFile(filepath, destfile)
            .then(() => {
                const attachment = new Discord.MessageAttachment(destfile);
                client.channels.cache.get(creds.channelID).send(attachment)
                .then((value) => {
                    console.log(value);
                    console.log("Upload finished. Writing " + filepath + " to upload history.");
                    uploadHistory.list.push(filepath);
                    fs.writeFileSync(pathToSentLog, JSON.stringify(uploadHistory, null, 2));
                }).catch(console.error);
            }).catch(console.error);
        }
    });
});
