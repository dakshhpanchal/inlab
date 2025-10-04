require('dotenv').config();
const express = require('express');
const cors = require('cors');
const passport = require('passport');
const session = require('express-session'); // still needed for passport
const GitHubStrategy = require('passport-github2').Strategy;
const jwt = require('jsonwebtoken');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(express.json());

app.use(cors({
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'HEAD'],
  credentials: true
}));

// Passport still needs a session store for the GitHub OAuth handshake
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

// --- GitHub OAuth setup ---
passport.use(new GitHubStrategy({
  clientID: process.env.GITHUB_CLIENT_ID,
  clientSecret: process.env.GITHUB_CLIENT_SECRET,
  callbackURL: "http://10.0.2.2:3001/auth/github/callback"
}, async (accessToken, refreshToken, profile, done) => {
  try {
    const githubId = profile.id;
    const username = profile.username;
    const name = profile.displayName || username;
    const email = profile.emails?.[0]?.value || null;
    const avatarUrl = profile.photos?.[0]?.value || null;
    const profileUrl = profile.profileUrl;

    const existingUser = await db.query('SELECT * FROM users WHERE github_id = $1', [githubId]);
    if (existingUser.rows.length > 0) {
      return done(null, existingUser.rows[0]);
    }

    const newUser = await db.query(`
      INSERT INTO users (github_id, username, name, email, avatar_url, profile_url)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [githubId, username, name, email, avatarUrl, profileUrl]);

    return done(null, newUser.rows[0]);
  } catch (err) {
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

// --- JWT middleware ---
function authenticateJWT(req, res, next) {
  const authHeader = req.headers.authorization;

  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
      if (err) {
        return res.sendStatus(403);
      }
      req.user = user;
      next();
    });
  } else {
    res.sendStatus(401);
  }
}

// --- Routes ---

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
    res.status(500).json({ error: 'Database connection failed!' });
  }
});

app.get('/auth/github', passport.authenticate('github', { scope: ['user:email'] }));

app.get('/auth/github/callback',
  passport.authenticate('github', { failureRedirect: '/' }),
  (req, res) => {
    const token = jwt.sign(
      { id: req.user.id, username: req.user.username },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );
    const redirectUrl = `myapp://login?token=${encodeURIComponent(token)}`;
    console.log('Redirecting to:', redirectUrl); // Debug log
    res.redirect(redirectUrl);
  }
);

// Example protected route
app.get('/api/attendance', authenticateJWT, async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM attendance WHERE user_id = $1', [req.user.id]);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch attendance' });
  }
});

// Get logged-in user info from JWT
app.get('/auth/me', authenticateJWT, async (req, res) => {
  try {
    const result = await db.query(
      'SELECT id, username, name, email, avatar_url, profile_url FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error fetching user:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  // console.log(`🔗 GitHub login: http://localhost:${PORT}/auth/github`);
});
