"use strict";
const os = require("os");
const winston = require("winston");
const LogdnaWinston = require("logdna-winston");
const expressWinston = require("express-winston");

const dotenv = require("dotenv")
dotenv.config()

const options = {
  console: {
    level: "debug",
    handleExceptions: true,
    format: winston.format.prettyPrint({ colorize: true })
  },
  logdna: {
    key: process.env.LOGDNA_INGESTION_KEY,
    hostname: os.hostname(),
    ip: os.networkInterfaces().lo0[0].address,
    mac: os.networkInterfaces().lo0[0].mac,
    app: "StreamSource",
    handleExceptions: true
  }
};

const logger = expressWinston.logger({
  transports: [
    new winston.transports.Console(options.console),
    new LogdnaWinston(options.logdna)
  ],
  exitOnError: false
});

module.exports = logger;