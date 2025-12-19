import { IResolvers } from 'apollo-server-express';
import bcrypt from 'bcryptjs';
import { getRepository } from 'typeorm';
import { User } from '../models/User';
import { Contact } from '../models/Contact';
import { Message } from '../models/Message';
import { signJwt } from '../utils/auth';

export const resolvers: IResolvers = {
  Query: {
    me: async (_parent, _args, context) => {
      if (!context.user) return null;
      const repo = getRepository(User);
      return repo.findOne(context.user.id, { relations: ['contacts'] });
    },
    contacts: async (_parent, _args, context) => {
      if (!context.user) return [];
      const repo = getRepository(Contact);
      return repo.find({ where: { user: { id: context.user.id } } });
    },
    messages: async (_parent, { withUserId }, context) => {
      if (!context.user) return [];
      const repo = getRepository(Message);
      return repo.find({
        where: [
          { from: { id: context.user.id }, to: { id: withUserId } },
          { from: { id: withUserId }, to: { id: context.user.id } },
        ],
        relations: ['from', 'to'],
        order: { timestamp: 'ASC' },
      });
    },
  },
  Mutation: {
    register: async (_parent, { username, phone, password }) => {
      const repo = getRepository(User);
      const exists = await repo.findOne({ where: [{ username }, { phone }] });
      if (exists) throw new Error('User already exists');
      const hashed = await bcrypt.hash(password, 10);
      const user = repo.create({ username, phone, password: hashed });
      await repo.save(user);
      return signJwt({ id: user.id });
    },
    login: async (_parent, { phone, password }) => {
      const repo = getRepository(User);
      const user = await repo.findOne({ where: { phone } });
      if (!user) throw new Error('User not found');
      const valid = await bcrypt.compare(password, user.password);
      if (!valid) throw new Error('Invalid password');
      return signJwt({ id: user.id });
    },
    addContact: async (_parent, { name, phone }, context) => {
      if (!context.user) throw new Error('Not authenticated');
      const userRepo = getRepository(User);
      const contactRepo = getRepository(Contact);
      const user = await userRepo.findOne(context.user.id);
      if (!user) throw new Error('User not found');
      const contact = contactRepo.create({ name, phone, user });
      await contactRepo.save(contact);
      return contact;
    },
    sendMessage: async (_parent, { toUserId, content }, context) => {
      if (!context.user) throw new Error('Not authenticated');
      const userRepo = getRepository(User);
      const msgRepo = getRepository(Message);
      const from = await userRepo.findOne(context.user.id);
      const to = await userRepo.findOne(toUserId);
      if (!from || !to) throw new Error('User not found');
      const msg = msgRepo.create({ from, to, content, timestamp: new Date().toISOString() });
      await msgRepo.save(msg);
      return msg;
    },
  },
};
