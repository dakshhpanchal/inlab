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
  callbackURL: "http://192.168.1.8:3001/auth/github/callback"
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

app.post('/api/attendance/check-in', authenticateJWT, async (req, res) => {
  try {
    const { lab_id, notes } = req.body;
    const user_id = req.user.id;

    if (!lab_id) {
      return res.status(400).json({ error: 'Lab ID is required' });
    }

    // Check if user already has an active check-in for this lab
    const existingCheckIn = await db.query(
      'SELECT * FROM attendance WHERE user_id = $1 AND lab_id = $2 AND check_out_time IS NULL',
      [user_id, lab_id]
    );

    if (existingCheckIn.rows.length > 0) {
      return res.status(400).json({ 
        error: 'You already have an active check-in for this lab',
        attendance: existingCheckIn.rows[0]
      });
    }

    // Create new check-in
    const result = await db.query(
      'INSERT INTO attendance (user_id, lab_id, notes, check_in_time) VALUES ($1, $2, $3, NOW()) RETURNING *',
      [user_id, lab_id, notes || null]
    );

    res.status(201).json({
      message: 'Check-in successful',
      attendance: result.rows[0]
    });

  } catch (err) {
    console.error('Error recording attendance:', err);
    res.status(500).json({ error: 'Failed to record attendance' });
  }
});

// Check out from lab
// Unified check-in/check-out endpoint
app.post('/api/attendance/toggle', authenticateJWT, async (req, res) => {
  try {
    const { lab_id, notes } = req.body;
    const user_id = req.user.id;

    if (!lab_id) {
      return res.status(400).json({ error: 'Lab ID is required' });
    }

    // Check if user has an active check-in for this lab
    const activeCheckIn = await db.query(
      'SELECT * FROM attendance WHERE user_id = $1 AND lab_id = $2 AND check_out_time IS NULL',
      [user_id, lab_id]
    );

    if (activeCheckIn.rows.length > 0) {
      // User has active check-in → Check out
      const result = await db.query(
        'UPDATE attendance SET check_out_time = NOW(), notes = COALESCE($3, notes) WHERE user_id = $1 AND lab_id = $2 AND check_out_time IS NULL RETURNING *',
        [user_id, lab_id, notes]
      );

      res.json({
        action: 'check_out',
        message: 'Check-out successful',
        attendance: result.rows[0],
        duration: calculateDuration(result.rows[0].check_in_time, result.rows[0].check_out_time)
      });

    } else {
      // No active check-in → Check in
      const result = await db.query(
        'INSERT INTO attendance (user_id, lab_id, notes, check_in_time) VALUES ($1, $2, $3, NOW()) RETURNING *',
        [user_id, lab_id, notes || null]
      );

      res.status(201).json({
        action: 'check_in',
        message: 'Check-in successful',
        attendance: result.rows[0]
      });
    }

  } catch (err) {
    console.error('Error toggling attendance:', err);
    res.status(500).json({ error: 'Failed to process attendance' });
  }
});

// Helper function to calculate duration
function calculateDuration(checkIn, checkOut) {
  const start = new Date(checkIn);
  const end = new Date(checkOut);
  const duration = end - start;
  
  const hours = Math.floor(duration / (1000 * 60 * 60));
  const minutes = Math.floor((duration % (1000 * 60 * 60)) / (1000 * 60));
  
  if (hours > 0) {
    return `${hours}h ${minutes}m`;
  } else {
    return `${minutes}m`;
  }
}

app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  // console.log(`🔗 GitHub login: http://localhost:${PORT}/auth/github`);
});
