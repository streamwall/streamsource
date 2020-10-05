const createError = require('http-errors');
const express = require('express');
const path = require('path');
const cookieParser = require('cookie-parser');
const { logger, errorLogger } = require('./middleware/logger');
const bodyParser = require('body-parser')
const boolParser = require('express-query-boolean');

const dotenv = require('dotenv')
dotenv.config()

const indexRouter = require('./routes/index');
const streamsRouter = require('./routes/streams');
const usersRouter = require('./routes/users');

const app = express();
require('./auth/authentication')

app.use(bodyParser.urlencoded({ extended: false }))
app.use(boolParser())

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

app.use(logger);
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', indexRouter);
app.use('/streams', streamsRouter);
app.use('/users', usersRouter);

app.use(errorLogger);

// catch 404 and forward to error handler
app.use(function (req, res, next) {
  next(createError(404));
});

// error handler
app.use(function (err, req, res, _next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.json({ error: err });
});

module.exports = app;
