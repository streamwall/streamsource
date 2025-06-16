import passport from 'passport';
import { Strategy as LocalStrategy } from 'passport-local';
import { Strategy as JWTStrategy, ExtractJwt } from 'passport-jwt';
import { prisma, User } from '../lib/prisma';
import type { JWTPayload } from '../types';

// JWT Strategy Configuration
passport.use(new JWTStrategy({
  secretOrKey: process.env.JWT_SECRET as string,
  jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
  algorithms: ['HS256'],
  ignoreExpiration: false
}, async (token: JWTPayload, done) => {
  try {
    const user = await prisma.user.findUnique({ where: { email: token.user.email }});
    return done(null, user);
  } catch (error) {
    done(error);
  }
}));

// Signup Strategy
passport.use('signup', new LocalStrategy({
  usernameField: 'email',
  passwordField: 'password'
}, async (email: string, password: string, done) => {
  try {
    const user = await User.create({
      email,
      password
    });
    return done(null, user);
  } catch (error) {
    done(error);
  }
}));

// Login Strategy
passport.use('login', new LocalStrategy({
  usernameField: 'email',
  passwordField: 'password'
}, async (email: string, password: string, done) => {
  try {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      return done(null, false, { message: 'User not found' });
    }
    
    const validate = await User.validatePassword(user, password);
    if (!validate) {
      return done(null, false, { message: 'Wrong Password' });
    }
    
    return done(null, user, { message: 'Logged in Successfully' });
  } catch (error) {
    return done(error);
  }
}));