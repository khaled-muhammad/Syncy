# SyncPlay Backend

A Django backend with WebSocket support for real-time video synchronization across multiple users.

## Features

- 🏠 **Room Management**: Create and join video sync rooms
- 🎥 **Video Synchronization**: Real-time play, pause, and seek synchronization
- 👥 **User Management**: Host privileges and user tracking
- 🔌 **WebSocket Support**: Real-time communication using Django Channels
- 📊 **Admin Interface**: Django admin for monitoring and management
- 🧹 **Cleanup Commands**: Automatic cleanup of old rooms and sessions

## Tech Stack

- **Django 5.0.1**: Web framework
- **Django REST Framework**: API development
- **Django Channels**: WebSocket support
- **Redis**: Channel layer backend (production)
- **SQLite**: Database (development)
- **PostgreSQL**: Database (production)

## Setup Instructions

### Prerequisites

- Python 3.8+
- pip and virtualenv
- Redis (for production WebSocket scaling)

### Installation

1. **Clone and navigate to backend:**
   ```bash
   cd backend
   ```

2. **Create virtual environment:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Environment setup:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. **Database setup:**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

6. **Create superuser:**
   ```bash
   python manage.py createsuperuser
   ```

7. **Run development server:**
   ```bash
   python manage.py runserver 8000
   ```

8. **For WebSocket support with Redis (production):**
   ```bash
   # Install and start Redis
   redis-server
   
   # Run with Daphne for WebSocket support
   daphne -p 8000 syncplay_backend.asgi:application
   ```

## API Endpoints

### Base URL: `http://localhost:8000/api/`

### Room Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/rooms/create/` | Create a new room |
| POST | `/rooms/join/` | Join an existing room |
| GET | `/rooms/` | List active rooms |
| GET | `/rooms/{room_id}/` | Get room details |
| DELETE | `/rooms/{room_id}/leave/` | Leave a room |

### Video Control

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/rooms/{room_id}/control/` | Control video playback |
| POST | `/rooms/{room_id}/change-video/` | Change current video |

### Messages

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/rooms/{room_id}/messages/` | Get room messages |

### Health

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health/` | Health check |

## API Examples

### Create Room
```bash
curl -X POST http://localhost:8000/api/rooms/create/ \
  -H "Content-Type: application/json" \
  -d '{
    "room_name": "Movie Night",
    "user_name": "Alice"
  }'
```

### Join Room
```bash
curl -X POST http://localhost:8000/api/rooms/join/ \
  -H "Content-Type: application/json" \
  -d '{
    "room_id": "550e8400-e29b-41d4-a716-446655440000",
    "user_name": "Bob"
  }'
```

### Control Video (Host only)
```bash
curl -X POST http://localhost:8000/api/rooms/{room_id}/control/ \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "host-user-id",
    "action": "play",
    "position": 120
  }'
```

## WebSocket API

### Connection
Connect to: `ws://localhost:8000/ws/room/{room_id}/`

### Message Format
```json
{
  "type": "message_type",
  "userId": "user-uuid",
  "data": {
    // Message-specific data
  }
}
```

### Message Types

#### Join Room
```json
{
  "type": "join",
  "userId": "user-uuid",
  "data": {
    "userName": "User Name"
  }
}
```

#### Video Control
```json
{
  "type": "play",
  "userId": "user-uuid",
  "data": {
    "position": 120
  }
}
```

#### Video Change
```json
{
  "type": "video_changed",
  "userId": "user-uuid",
  "data": {
    "videoUrl": "https://example.com/video.mp4",
    "videoTitle": "Video Title"
  }
}
```

## Database Models

### Room
- `id`: UUID primary key
- `name`: Room name
- `host_id`: Host user UUID
- `current_video_url`: Current video URL
- `current_video_title`: Current video title
- `current_position`: Playback position
- `is_playing`: Playing state
- `created_at`: Creation timestamp

### User
- `id`: UUID primary key
- `room`: Foreign key to Room
- `name`: User name
- `is_host`: Host flag
- `is_online`: Online status
- `joined_at`: Join timestamp

### Message
- `id`: UUID primary key
- `room`: Foreign key to Room
- `user_id`: User UUID
- `message_type`: Message type
- `data`: JSON data
- `timestamp`: Message timestamp

### RoomSession
- `room`: Foreign key to Room
- `user_id`: User UUID
- `channel_name`: WebSocket channel name
- `connected_at`: Connection timestamp
- `last_activity`: Last activity timestamp

## Management Commands

### Cleanup Old Rooms
```bash
# Dry run (show what would be deleted)
python manage.py cleanup_rooms --dry-run

# Clean up rooms older than 24 hours
python manage.py cleanup_rooms

# Clean up rooms older than 6 hours
python manage.py cleanup_rooms --hours 6
```

## Admin Interface

Access the Django admin at: `http://localhost:8000/admin/`

Default credentials (if using the setup script):
- Username: `admin`
- Password: `admin123`

## Deployment

### Production Settings

1. **Environment Variables:**
   ```bash
   SECRET_KEY=your-production-secret-key
   DEBUG=False
   DB_NAME=syncplay_production
   DB_USER=syncplay_user
   DB_PASSWORD=secure-password
   DB_HOST=localhost
   DB_PORT=5432
   ```

2. **PostgreSQL Setup:**
   ```sql
   CREATE DATABASE syncplay_production;
   CREATE USER syncplay_user WITH PASSWORD 'secure-password';
   GRANT ALL PRIVILEGES ON DATABASE syncplay_production TO syncplay_user;
   ```

3. **Redis Setup:**
   ```bash
   sudo apt install redis-server
   sudo systemctl enable redis
   sudo systemctl start redis
   ```

4. **ASGI Server (Daphne):**
   ```bash
   daphne -p 8000 syncplay_backend.asgi:application
   ```

5. **Nginx Configuration:**
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;
       
       location / {
           proxy_pass http://127.0.0.1:8000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection "upgrade";
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

## Testing

### Run Tests
```bash
python manage.py test
```

### API Testing with curl
```bash
# Health check
curl http://localhost:8000/api/health/

# List rooms
curl http://localhost:8000/api/rooms/
```

### WebSocket Testing
Use a WebSocket client to connect to `ws://localhost:8000/ws/room/{room_id}/`

## Monitoring

### Logs
Logs are written to `syncplay.log` in the project root.

### Admin Interface
Monitor rooms, users, and messages through the Django admin interface.

### Health Check
Use `/api/health/` endpoint for health monitoring.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License # syncplay_backend
