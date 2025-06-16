declare module 'logdna-winston' {
  import winston from 'winston';
  
  interface LogDNATransportOptions {
    key: string;
    hostname?: string;
    ip?: string;
    mac?: string;
    app?: string;
    handleExceptions?: boolean;
    level?: string;
    tags?: string[];
  }
  
  class LogDNATransport extends winston.Transport {
    constructor(options: LogDNATransportOptions);
  }
  
  export = LogDNATransport;
}