import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface AuthRequest extends Request {
  user?: any;
}

export function authMiddleware(req: AuthRequest, res: Response, next: NextFunction) {
  const auth = req.headers.authorization;
  if (auth && auth.startsWith('Bearer ')) {
    const token = auth.slice(7);
    try {
      const user = jwt.verify(token, process.env.JWT_SECRET!);
      req.user = user;
    } catch (e) {
      req.user = null;
    }
  } else {
    req.user = null;
  }
  next();
}
