declare module 'express-query-boolean' {
  import { RequestHandler } from 'express';
  
  function boolParser(): RequestHandler;
  
  export = boolParser;
}