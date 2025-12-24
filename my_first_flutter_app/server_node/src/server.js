const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;

// In-memory OTP store: phone -> { code, expiresAt }
const otps = new Map();
const OTP_TTL_MS = 2 * 60 * 1000; // 2 minutes

// Development: default OTP (useful for emulator testing). Set DEV_OTP env to override.
const DEV_OTP = process.env.DEV_OTP || '123456';

// JWT secret and settings (in production, keep secret in env)
const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'replace_this_with_a_real_secret';
const JWT_EXPIRES = '7d';

function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function cleanupOtps() {
  const now = Date.now();
  for (const [phone, entry] of otps.entries()) {
    if (entry.expiresAt <= now) otps.delete(phone);
  }
}
setInterval(cleanupOtps, 30 * 1000);

app.post('/send-otp', (req, res) => {
  const { phone } = req.body || {};
  if (!phone || typeof phone !== 'string' || phone.trim().length < 6) {
    return res.status(400).json({ success: false, message: 'Invalid phone' });
  }
  const normalized = phone.trim();
  // For development convenience use DEV_OTP; change to generateOtp() in production
  const code = DEV_OTP;
  const expiresAt = Date.now() + OTP_TTL_MS;
  otps.set(normalized, { code, expiresAt });

  // In a real server, integrate with an SMS provider here (Twilio, MSG91, etc.)
  // For development return debug info in response (or log it).
  console.log(`DEBUG OTP for ${normalized}: ${code} (expires in ${OTP_TTL_MS/1000}s)`);

  return res.json({ success: true, message: 'OTP sent (debug)', ttl: OTP_TTL_MS / 1000 });
});

app.post('/verify-otp', (req, res) => {
  const { phone, code } = req.body || {};
  if (!phone || !code) {
    return res.status(400).json({ success: false, message: 'phone and code required' });
  }
  const normalized = phone.trim();
  const entry = otps.get(normalized);

  // Accept DEV_OTP as a development backdoor (if provided) even when no stored OTP exists.
  const provided = String(code);
  const isDevBackdoor = DEV_OTP && provided === DEV_OTP;

  if (!entry && !isDevBackdoor) {
    return res.status(400).json({ success: false, message: 'OTP not found or expired' });
  }

  if (!isDevBackdoor && entry.code !== provided) {
    return res.status(400).json({ success: false, message: 'Invalid code' });
  }

  // Verified — remove OTP (if present) and return success. In production you'd authenticate the user and return a token.
  if (entry) otps.delete(normalized);

  // Issue a JWT for the phone number (demo token)
  const payload = { phone: normalized };
  const token = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES });
  return res.json({ success: true, message: 'Verified', token });
});

app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Authenticated endpoint to return current user profile based on JWT
app.get('/me', (req, res) => {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth) return res.status(401).json({ success: false, message: 'Authorization header missing' });
  const parts = String(auth).split(' ');
  if (parts.length !== 2 || parts[0].toLowerCase() !== 'bearer') return res.status(401).json({ success: false, message: 'Invalid authorization format' });
  const token = parts[1];
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    // For demo return a mock profile
    const user = {
      phone: payload.phone,
      name: `User ${payload.phone.slice(-4)}`,
      email: `${payload.phone.replace(/[^0-9]/g, '')}@example.com`,
    };
    return res.json({ success: true, user });
  } catch (e) {
    return res.status(401).json({ success: false, message: 'Invalid or expired token' });
  }
});

app.listen(PORT, () => {
  console.log(`OTP server listening on http://localhost:${PORT}`);
});
