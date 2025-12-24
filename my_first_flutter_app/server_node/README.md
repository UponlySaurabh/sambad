Private OTP server (demo)

This is a small Node.js Express server that implements two endpoints used for OTP-based login in the `Private` Flutter app demo.

Endpoints

- POST /send-otp
  - Body: { "phone": "+911234567890" }
  - Response: { success: true, message: 'OTP sent (debug)', ttl: 120 }
  - Note: Server logs the OTP to the console (only for development).

- POST /verify-otp
  - Body: { "phone": "+911234567890", "code": "123456" }
  - Response: { success: true, message: 'Verified', token: '<jwt>' }

The server returns a JWT token on successful verification (demo). Use this token to authenticate further requests in your Flutter app.

Run locally

```bash
cd server_node
npm install
npm start
```

For development with auto-reload:

```bash
npm run dev
```

Notes

- This is a demo only: OTPs are stored in-memory and will be lost when the process restarts.
- Replace the console log in `/send-otp` with a real SMS provider (Twilio, MSG91, etc.) before production.
