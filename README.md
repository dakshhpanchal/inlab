# InLab

InLab is a comprehensive attendance management system designed for labs and sessions. It features a cross-platform mobile application built with Flutter for user interaction and a robust backend powered by Node.js and PostgreSQL. Users can authenticate securely via GitHub OAuth and check in or out of sessions by scanning QR codes.

## Features

- **Secure Authentication**: Users log in securely using their GitHub accounts via OAuth2.
- **QR Code Attendance**: Simple and fast check-in and check-out process by scanning a QR code associated with a lab or session.
- **Attendance Toggling**: Scan the same QR code to check in, and scan it again to check out. The system automatically handles the state.
- **History and Summary**: View a detailed history of all attendance records, including check-in/out times, duration, and notes.
- **User Profiles**: View your basic profile information fetched from GitHub.
- **Containerized Backend**: The backend services (Node.js API, PostgreSQL database, pgAdmin) are fully containerized with Docker for easy setup and deployment.

## Tech Stack

- **Frontend**: Flutter, Dart
- **Backend**: Node.js, Express.js
- **Database**: PostgreSQL
- **Authentication**: Passport.js (GitHub Strategy), JSON Web Tokens (JWT)
- **Containerization**: Docker, Docker Compose

## Project Structure

The repository is organized into two main parts:

-   `./backend/`: Contains the Node.js Express server, database initialization script (`init.sql`), and Dockerfile.
-   `./frontend/`: Contains the Flutter mobile application source code.

## Getting Started

Follow these instructions to get the project up and running on your local machine.

### Prerequisites

-   [Docker](https://www.docker.com/products/docker-desktop/) and [Docker Compose](https://docs.docker.com/compose/install/)
-   [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.9.0 or higher)
-   A code editor like [VS Code](https://code.visualstudio.com/)

### 1. Configuration

#### A. Backend Environment

1.  Navigate to the `backend` directory.
2.  Create a `.env` file by copying the example below.

    ```sh
    # backend/.env

    # GitHub OAuth App Credentials
    # Get these from your GitHub Developer Settings
    # https://github.com/settings/developers
    GITHUB_CLIENT_ID=your_github_client_id
    GITHUB_CLIENT_SECRET=your_github_client_secret

    JWT_SECRET=a_very_strong_and_secret_key_for_jwt
    ```

#### B. Network IP Address

The application uses hardcoded IP addresses for communication between the frontend and backend. You **must** replace the placeholder `192.168.1.8` with your local machine's network IP address.

Find your IP address:
- **macOS/Linux**: a`ifconfig | grep "inet " | grep -v 127.0.0.1`
- **Windows**: `ipconfig | findstr "IPv4 Address"`

Update the IP address in the following files:

-   `backend/src/index.js` (for the GitHub callback URL):
    ```javascript
    // Change this line
    callbackURL: "http://192.168.1.8:3001/auth/github/callback"
    ```
-   `frontend/lib/login_screen.dart`:
    ```dart
    // Change this line
    final baseUrl = Platform.isAndroid ? 'http://192.168.1.8:3001' : 'http://localhost:3001';
    ```
-   `frontend/lib/home_screen.dart`:
    ```dart
    // Change this line
    Uri.parse('http://192.168.1.8:3001/auth/me'),
    ```
-   `frontend/lib/attendance_screen.dart`:
    ```dart
    // Change this line
    Uri.parse('http://192.168.1.8:3001/api/attendance'),
    ```
-   `frontend/lib/qr_scan_screen.dart`:
    ```dart
    // Change this line
    Uri.parse('http://192.168.1.8:3001/api/attendance/toggle'),
    ```
    
#### C. GitHub OAuth Callback URL

In your GitHub OAuth App settings, set the "Authorization callback URL" to `http://<YOUR_IP_ADDRESS>:3001/auth/github/callback`. This must match the URL configured in `backend/src/index.js`.

### 2. Run the Application

#### A. Run Backend Services

Open a terminal in the root directory of the project and run:

```sh
docker compose up --build
```
This command will:
- Build the Docker images for the Node.js API.
- Start the PostgreSQL database, pgAdmin, and the backend API service.
- The API will be available at `http://<YOUR_IP_ADDRESS>:3001`.
- You can access pgAdmin at `http://localhost:8080` (Email: `admin@inlab.com`, Password: `admin`).

#### B. Run the Frontend App

1.  Open a new terminal.
2.  Navigate to the `frontend` directory.
3.  Install dependencies:
    ```sh
    flutter pub get
    ```
4.  Run the app on a connected device or simulator:
    ```sh
    flutter run
    ```

### Development Script

For a streamlined development experience, the `dev.sh` script launches the entire stack in separate `kitty` terminal windows.

```sh
./dev.sh
```

## API Endpoints

The backend exposes the following REST API endpoints. All protected routes require a `Bearer <token>` in the Authorization header.

| Endpoint                   | Method | Protected | Description                                          |
| -------------------------- | :----: | :-------: | ---------------------------------------------------- |
| `/api/health`              | `GET`  |    No     | Checks the health of the server.                     |
| `/auth/github`             | `GET`  |    No     | Initiates the GitHub OAuth login flow.               |
| `/auth/github/callback`    | `GET`  |    No     | Handles the callback from GitHub after authorization.|
| `/auth/me`                 | `GET`  |    Yes    | Retrieves the authenticated user's profile data.     |
| `/api/attendance`          | `GET`  |    Yes    | Fetches all attendance records for the logged-in user.|
| `/api/attendance/toggle`   | `POST` |    Yes    | Toggles the check-in/check-out status for a given lab. |
