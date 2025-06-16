import _ from 'lodash';
import express, { Request, Response, NextFunction } from 'express';
import passport from 'passport';
import jwt from 'jsonwebtoken';
import { userValidationRules, handleValidationErrors } from '../middleware/validation';
import dotenv from 'dotenv';
import type { AuthRequest, User } from '../types';

dotenv.config();

const router = express.Router();

async function createUser(req: Request, res: Response) {
  res.json({
    message: "Signed up successfully",
    user: (req as any).user
  });
}

async function login(req: Request, res: Response, next: NextFunction) {
  passport.authenticate('login', async (err: Error | null, user: User | false, _info: any) => {
    try {
      if (err || !user) {
        const error = new Error("An error occurred while logging in");
        return next(error);
      }
      
      req.login(user, { session: false }, async (error) => {
        if (error) return next(error);
        
        // We don't want to store the sensitive information such as the
        // user password in the token so we pick only the email and id
        const body = { _id: user.id, email: user.email };
        
        // Sign the JWT token and populate the payload with the user email and id
        const token = jwt.sign(
          { user: body }, 
          process.env.JWT_SECRET as string,
          { 
            algorithm: 'HS256',
            expiresIn: '24h' 
          }
        );
        
        // Send back the token to the user
        return res.json({ token });
      });
    } catch (error) {
      return next(error);
    }
  })(req, res, next);
}

router.post('/signup', 
  ...userValidationRules.signup,
  passport.authenticate('signup', { session: false }), 
  createUser
);

router.post('/login', 
  ...userValidationRules.login,
  login
);

export default router;