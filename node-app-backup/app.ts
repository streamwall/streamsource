import createError from 'http-errors';
import express, { Request, Response, NextFunction } from 'express';
import path from 'path';
import cookieParser from 'cookie-parser';
import { logger, errorLogger } from './middleware/logger';
import boolParser from 'express-query-boolean';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { metricsMiddleware } from './middleware/metrics';
import dotenv from 'dotenv';

dotenv.config();

import indexRouter from './routes/index';
import streamsRouter from './routes/streams';
import usersRouter from './routes/users';
import healthRouter from './routes/health';

const app = express();
require('./auth/authentication');

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

// Metrics endpoint (before rate limiting so metrics are always accessible)
app.use(metricsMiddleware);

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

// Apply rate limiting to all requests
app.use(limiter);

// Stricter rate limiting for authentication endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Limit each IP to 5 requests per windowMs
  skipSuccessfulRequests: true,
});

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');

app.use(logger);
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(boolParser());
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', indexRouter);
app.use('/health', healthRouter);
app.use('/streams', streamsRouter);
app.use('/users', authLimiter, usersRouter);

app.use(errorLogger);

// catch 404 and forward to error handler
app.use(function (req: Request, res: Response, next: NextFunction) {
  next(createError(404));
});

// error handler
interface ErrorWithStatus extends Error {
  status?: number;
}

app.use(function (err: ErrorWithStatus, req: Request, res: Response, _next: NextFunction) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.json({ error: err });
});

export default app;