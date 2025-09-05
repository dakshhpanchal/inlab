require('dotenv').config();
const express = require('express');
const session = require('express-session');
const cors = require('cors');
const passport = require('passport');
const GitHubStrategy = require('passport-github2').Strategy;
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3001;

// ======================
// Middleware
// ======================
app.use(express.json());

// CORS - Allow requests from our Flutter frontend (will run on various ports)
app.use(cors({
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'HEAD'], // Allow requests from any origin during development
  credentials: true // Allow cookies/session to be sent
}));

// Session configuration - REQUIRED for passport session support
app.use(session({
  secret: process.env.JWT_SECRET, // Using our JWT secret for session encryption
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    secure: false, // Set to true in production if using HTTPS
    maxAge: 24 * 60 * 60 * 1000, // 24 hours
    sameSite: 'lax'
  }
}));

// Initialize Passport and session support
app.use(passport.initialize());
app.use(passport.session());

// ======================
// Passport Configuration
// ======================
passport.use(new GitHubStrategy({
  clientID: process.env.GITHUB_CLIENT_ID,
  clientSecret: process.env.GITHUB_CLIENT_SECRET,
  callbackURL: "http://localhost:3001/auth/github/callback"
}, async (accessToken, refreshToken, profile, done) => {
  try {
    console.log('GitHub Profile:', profile);
    
    const githubId = profile.id;
    const username = profile.username;
    const name = profile.displayName || username;
    const email = profile.emails?.[0]?.value || null;
    const avatarUrl = profile.photos?.[0]?.value || null;
    const profileUrl = profile.profileUrl;

    // Check if user already exists
    const existingUser = await db.query('SELECT * FROM users WHERE github_id = $1', [githubId]);
    
    if (existingUser.rows.length > 0) {
      console.log('User exists:', existingUser.rows[0]);
      return done(null, existingUser.rows[0]);
    }

    // Create new user
    const newUser = await db.query(`
      INSERT INTO users (github_id, username, name, email, avatar_url, profile_url)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [githubId, username, name, email, avatarUrl, profileUrl]);

    console.log('New user created:', newUser.rows[0]);
    return done(null, newUser.rows[0]);
  } catch (err) {
    console.error('Error in GitHub strategy:', err);
    return done(err);
  }
}));

// Serialize user into session
passport.serializeUser((user, done) => {
  done(null, user.id);
});

// Deserialize user from session
passport.deserializeUser(async (id, done) => {
  try {
    const result = await db.query('SELECT * FROM users WHERE id = $1', [id]);
    done(null, result.rows[0]);
  } catch (err) {
    done(err);
  }
});

// ======================
// Routes
// ======================
// Health check (keep our existing test route)
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Server is up and running!' });
});

// Test DB connection (keep our existing test route)
app.get('/api/test-db', async (req, res) => {
  try {
    const result = await db.query('SELECT NOW() as current_time');
    res.json({ 
      message: 'Database connection successful!', 
      time: result.rows[0].current_time 
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Database connection failed!' });
  }
});

// GitHub authentication routes
app.get('/auth/github', passport.authenticate('github', { scope: ['user:email'] }));

app.get('/auth/github/callback',
  passport.authenticate('github', { failureRedirect: '/' }),
  (req, res) => {
    // Successful authentication, redirect to your Flutter app
    // We'll change this later to work with Flutter
    res.redirect('http://localhost:3001/api/health');
  }
);

// Get current user
app.get('/auth/user', (req, res) => {
  if (req.isAuthenticated()) {
    res.json(req.user);
  } else {
    res.status(401).json({ error: 'Not logged in' });
  }
});

// Logout
app.get('/auth/logout', (req, res) => {
  req.logout((err) => {
    if (err) {
      return res.status(500).json({ error: 'Logout failed' });
    }
    res.clearCookie('connect.sid'); // Clear the session cookie
    res.json({ message: 'Logged out successfully' });
  });
});

// ======================
// Start Server
// ======================
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`GitHub auth available at: http://localhost:${PORT}/auth/github`);
});