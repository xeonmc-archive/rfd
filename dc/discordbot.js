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

let uploadHistory = {};
try {
  let readLog = require(pathToSentLog);
  if (typeof readLog === 'object') uploadHistory = readLog;
} catch(err) {
  console.error(err);
}

console.log("logging in with token " + creds.token);
client.login(creds.token);

client.on('ready', () => {
    console.log(`Logged in as ${client.user.tag}!`);
    chokidar.watch(pathToReplays).on('add', (filepath, event) => {
        console.log("New file? " + filepath);
        const filename = path.basename(filepath, path.extname(filepath));
        if ( filepath.endsWith(".rep") && !(filename in uploadHistory) ) {
            console.log("Haven't seen " + filename + " before. Uploading...");
            uploadHistory[filename] = {};
            const destfile = pathToReplays + filename + ".zip";
            compressing.zip.compressFile(filepath, destfile)
            .then(() => {
                const attachment = new Discord.MessageAttachment(destfile);
                for (const channelID of creds.targetCIDs) {
                    client.channels.cache.get(channelID).send(attachment)
                    .then(msg=>{
                        msg.attachments.forEach(Attachment => {
                            console.log(Attachment.url)
                            uploadHistory[filename][channelID] = Attachment.url;
                        })
                        try {
                            fs.writeFile(pathToSentLog, JSON.stringify(uploadHistory, null, 2), (err) => {
                                if (err) throw err;
                                console.log("success logged for " + filename + " at " + channelID);
                            })
                        } catch(err) {
                            console.error(err);
                        }
                    }).catch(err=>{
                        console.log(err);
                        uploadHistory[filename][channelID] = "failed";
                        try {
                            fs.writeFile(pathToSentLog, JSON.stringify(uploadHistory, null, 2), (err) => {
                                if (err) throw err;
                                console.log("failure logged for " + filename + " at " + channelID);
                            })
                        } catch(err) {
                            console.error(err);
                        }
                    });
                } 
            }).catch(console.error);
        }
    });
});
