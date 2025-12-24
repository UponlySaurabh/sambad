import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { pool } from './db';

export const resolvers = {
  Query: {
    me: async (_: any, __: any, ctx: any) => {
      if (!ctx.user) return null;
      const { rows } = await pool.query('SELECT id, name, email, created_at FROM users WHERE id = $1', [ctx.user.id]);
      return rows[0];
    },
    contacts: async (_: any, __: any, ctx: any) => {
      if (!ctx.user) return [];
      const { rows } = await pool.query('SELECT * FROM contacts WHERE owner_id = $1', [ctx.user.id]);
      return rows;
    },
    messages: async (_: any, { contactId }: any, ctx: any) => {
      if (!ctx.user) return [];
      const { rows } = await pool.query('SELECT * FROM messages WHERE (from_id = $1 AND to_id = $2) OR (from_id = $2 AND to_id = $1) ORDER BY created_at', [ctx.user.id, contactId]);
      return rows;
    },
  },
  Mutation: {
    register: async (_: any, { name, email, password }: any) => {
      const hash = await bcrypt.hash(password, 10);
      const { rows } = await pool.query('INSERT INTO users (name, email, password) VALUES ($1, $2, $3) RETURNING id, name, email, created_at', [name, email, hash]);
      return rows[0];
    },
    login: async (_: any, { email, password }: any) => {
      const { rows } = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
      const user = rows[0];
      if (!user) throw new Error('User not found');
      const valid = await bcrypt.compare(password, user.password);
      if (!valid) throw new Error('Invalid password');
      return jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET!, { expiresIn: '7d' });
    },
    addContact: async (_: any, { name, phone }: any, ctx: any) => {
      if (!ctx.user) throw new Error('Not authenticated');
      const { rows } = await pool.query('INSERT INTO contacts (name, phone, owner_id) VALUES ($1, $2, $3) RETURNING *', [name, phone, ctx.user.id]);
      return rows[0];
    },
    sendMessage: async (_: any, { to, content, private: isPrivate }: any, ctx: any) => {
      if (!ctx.user) throw new Error('Not authenticated');
      const { rows } = await pool.query('INSERT INTO messages (from_id, to_id, content, private) VALUES ($1, $2, $3, $4) RETURNING *', [ctx.user.id, to, content, !!isPrivate]);
      return rows[0];
    },
    deleteAccount: async (_: any, __: any, ctx: any) => {
      if (!ctx.user) throw new Error('Not authenticated');
      await pool.query('DELETE FROM users WHERE id = $1', [ctx.user.id]);
      return true;
    },
  },
};
