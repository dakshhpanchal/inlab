require('dotenv').config();
const express = require('express');
const session = require('express-session');
const cors = require('cors');
const passport = require('passport');
const GitHubStrategy = require('passport-github2').Strategy;
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(express.json());

app.use(cors({
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'HEAD'], 
  credentials: true 
}));

app.use(session({
  secret: process.env.JWT_SECRET, 
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    secure: false, 
    maxAge: 24 * 60 * 60 * 1000, 
    sameSite: 'lax'
  }
}));

app.use(passport.initialize());
app.use(passport.session());

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

    const existingUser = await db.query('SELECT * FROM users WHERE github_id = $1', [githubId]);
    
    if (existingUser.rows.length > 0) {
      console.log('User exists:', existingUser.rows[0]);
      return done(null, existingUser.rows[0]);
    }

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

passport.serializeUser((user, done) => {
  done(null, user.id);
});

passport.deserializeUser(async (id, done) => {
  try {
    const result = await db.query('SELECT * FROM users WHERE id = $1', [id]);
    done(null, result.rows[0]);
  } catch (err) {
    done(err);
  }
});

app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Server is up and running!' });
});

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

app.get('/auth/github', passport.authenticate('github', { scope: ['user:email'] }));

app.get('/auth/github/callback',
  passport.authenticate('github', { failureRedirect: '/' }),
  (req, res) => {
    res.send(`
      <html>
        <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
          <h2>✅ Login Successful!</h2>
          <p>You can close this window and return to the app.</p>
          <p><small>Your session has been established.</small></p>
        </body>
      </html>
    `);
  }
);

app.get('/auth/user', (req, res) => {
  if (req.isAuthenticated()) {
    res.json(req.user);
  } else {
    res.status(401).json({ error: 'Not logged in' });
  }
});

app.get('/auth/logout', (req, res) => {
  req.logout((err) => {
    if (err) {
      return res.status(500).json({ error: 'Logout failed' });
    }
    res.clearCookie('connect.sid'); // Clear the session cookie
    res.json({ message: 'Logged out successfully' });
  });
});

app.get('/auth/token', async (req, res) => {
  if (req.isAuthenticated()) {
    const token = require('crypto').randomBytes(16).toString('hex');
    
    await db.query(
      'UPDATE users SET auth_token = $1 WHERE id = $2',
      [token, req.user.id]
    );
    
    res.json({ token: token });
  } else {
    res.status(401).json({ error: 'Not authenticated' });
  }
});

app.get('/auth/verify-token', async (req, res) => {
  const token = req.query.token;
  
  if (!token) {
    return res.status(400).json({ error: 'Token required' });
  }
  
  try {
    const result = await db.query(
      'SELECT * FROM users WHERE auth_token = $1',
      [token]
    );
    
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid token' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Token verification error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`GitHub auth available at: http://localhost:${PORT}/auth/github`);
});