import 'dotenv/config';
import express from 'express';
import { ApolloServer } from 'apollo-server-express';
import cors from 'cors';
import http from 'http';
import { typeDefs } from './typeDefs';
import { resolvers } from './resolvers';
import { authMiddleware } from './middleware/auth';

const PORT = process.env.PORT || 4000;

async function startServer() {
  const app = express();
  app.use(cors());
  app.use(express.json());
  app.use(authMiddleware);

  const apolloServer = new ApolloServer({
    typeDefs,
    resolvers,
    context: ({ req }) => ({ user: req.user })
  });
  await apolloServer.start();
  apolloServer.applyMiddleware({ app, path: '/graphql' });

  const httpServer = http.createServer(app);
  httpServer.listen(PORT, () => {
    console.log(`🚀 Server ready at http://localhost:${PORT}/graphql`);
  });
}

startServer();
