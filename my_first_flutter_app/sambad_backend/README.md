# Sambad Backend (WhatsApp-like Example)

This backend is a secure, scalable chat server inspired by WhatsApp, built with:
- Node.js (TypeScript)
- Apollo Server (GraphQL)
- PostgreSQL (TypeORM)
- JWT authentication
- HTTPS and security best practices

## Features
- User registration, login, and JWT-based authentication
- Contacts management (add, search, list)
- One-to-one chat (messages between users)
- End-to-end encryption ready (client-side)
- GraphQL API for all data access
- PostgreSQL for robust, scalable storage

## Structure
- `/src/models` — TypeORM entities for User, Contact, Message
- `/src/resolvers` — GraphQL resolvers for all operations
- `/src/schema.graphql` — GraphQL schema
- `/src/index.ts` — Server entry point

## Security
- Passwords hashed with bcrypt
- JWT for authentication
- HTTPS ready (add your certs)
- Input validation everywhere

## Setup
1. Install dependencies: `npm install`
2. Set up PostgreSQL and update `.env`
3. Run migrations: `npm run typeorm migration:run`
4. Start server: `npm run dev`

## For Flutter Integration
- Use a GraphQL client (e.g. `graphql_flutter`)
- Authenticate with JWT
- Query/mutate users, contacts, and messages

---
Replace this README with your own details as you build further.
