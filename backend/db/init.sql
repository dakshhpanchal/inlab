-- Create a table for storing user information
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    github_id INTEGER UNIQUE, -- Will store the unique ID provided by GitHub
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255),
    avatar_url VARCHAR(255),
    profile_url TEXT,
    name VARCHAR(255),
    -- Auth fields for non-Github login (if needed later)
    password_hash VARCHAR(255), 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create a table for storing attendance records
CREATE TABLE IF NOT EXISTS attendance (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- The lab or session identifier scanned from the QR code
    lab_id VARCHAR(255) NOT NULL,
    -- Timestamp of when the check-in was recorded
    check_in_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- Optional: Timestamp for check-out
    check_out_time TIMESTAMP WITH TIME ZONE,
    -- Optional: Additional metadata
    notes TEXT,
    -- Ensure a user can't have multiple active check-ins for the same lab without checking out
    UNIQUE(user_id, lab_id, check_out_time)
);

-- Create an index to speed up queries looking for a user's attendance records
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_lab_id ON attendance(lab_id);