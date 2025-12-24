# Sambad Backend

A secure backend for chat/contact app using Node.js (TypeScript), Apollo Server (GraphQL), PostgreSQL, JWT authentication, and HTTPS.

## Features
- User, contact, and message models
- GraphQL API (Apollo Server)
- PostgreSQL database
- JWT authentication
- Security best practices

## Setup
1. Install dependencies: `npm install`
2. Set up PostgreSQL and configure `.env`
3. Run migrations: `npm run migrate`
4. Start server: `npm run start:dev`

## Security
- All sensitive data is encrypted in transit (HTTPS)
- JWT for authentication
- Input validation and sanitization

## For Flutter Integration
- Use GraphQL endpoint for all data operations
- See schema in `src/schema.graphql`
