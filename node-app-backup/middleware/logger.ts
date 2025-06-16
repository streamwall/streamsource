import os from 'os';
import winston from 'winston';
import LogdnaWinston from 'logdna-winston';
import expressWinston from 'express-winston';
import dotenv from 'dotenv';

dotenv.config();

interface ConsoleTransportOptions {
  level?: string;
  handleExceptions?: boolean;
  format?: winston.Logform.Format;
}

interface LoggerOptions {
  console: ConsoleTransportOptions;
  logdna: {
    key: string;
    app: string;
    handleExceptions: boolean;
  };
}

const options: LoggerOptions = {
  console: {
    level: 'debug',
    handleExceptions: true,
    format: winston.format.prettyPrint({ colorize: true })
  },
  logdna: {
    key: process.env.LOGDNA_INGESTION_KEY as string,
    app: 'StreamSource',
    handleExceptions: true
  }
};

const transports: any[] = [new winston.transports.Console(options.console)];

// Only add LogDNA transport if key is provided and not in test environment
if (process.env.LOGDNA_INGESTION_KEY && process.env.NODE_ENV !== 'test') {
  transports.push(new LogdnaWinston(options.logdna) as any);
}

export const logger = expressWinston.logger({
  transports,
  meta: true,
  msg: 'HTTP {{req.method}} {{req.url}}',
  expressFormat: true,
  colorize: false
});

export const errorLogger = expressWinston.errorLogger({
  transports,
  meta: true
});