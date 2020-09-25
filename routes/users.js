const _ = require('lodash')
const express = require('express');
const router = express.Router();
const passport = require('passport')
const jwt = require('jsonwebtoken')
const dotenv = require('dotenv')
dotenv.config()

async function createUser(req, res) {
  res.json({
    message: "Signed up successfully",
    user:    req.user
  })
}

async function login(req, res, next) {
  passport.authenticate('login', async (err, user, _info) => {
    try {
      if (err || !user) {
        const error = new Error("An error occurred while logging in")
        return next(error)
      }
      req.login(user, { session: false }, async (error) => {
        if (error) return next(error)
        //We don't want to store the sensitive information such as the
        //user password in the token so we pick only the email and id
        const body = { _id: user._id, email: user.email };
        //Sign the JWT token and populate the payload with the user email and id
        const token = jwt.sign({ user: body }, process.env.JWT_SECRET);
        //Send back the token to the user
        return res.json({ token });
      });
    } catch (error) {
      return next(error);
    }
  })(req, req, next)
}

router.post('/signup', passport.authenticate('signup', { session: false }), createUser)
router.post('/login', login)

module.exports = router;
