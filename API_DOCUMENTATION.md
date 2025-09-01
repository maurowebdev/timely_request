# Time-Off Request API Documentation

## Authentication
All API endpoints require authentication via Devise session cookies.

## Endpoints

### Time Off Requests

#### GET /api/v1/time_off_requests
Get all time-off requests for the current user.

**Response:**
```json
{
  "data": [
    {
      "id": "1",
      "type": "time_off_request",
      "attributes": {
        "start_date": "2025-01-15",
        "end_date": "2025-01-17",
        "reason": "Vacation",
        "status": "pending",
        "time_off_type_name": "Vacation"
      }
    }
  ]
}
```

#### POST /api/v1/time_off_requests
Create a new time-off request.

**Request Body:**
```json
{
  "time_off_request": {
    "time_off_type_id": "1",
    "start_date": "2025-01-15",
    "end_date": "2025-01-17",
    "reason": "Family vacation"
  }
}
```

#### PATCH /api/v1/time_off_requests/:id/approve
Approve a time-off request (Manager/Admin only).

**Request Body:**
```json
{
  "comments": "Enjoy your vacation!"
}
```

#### PATCH /api/v1/time_off_requests/:id/deny
Deny a time-off request (Manager/Admin only).

**Request Body:**
```json
{
  "comments": "Insufficient coverage during that period"
}
```

### Manager Dashboard

#### GET /api/v1/time_off_requests/manager_dashboard
Get all pending requests for manager's direct reports.

**Response:**
```json
{
  "data": [
    {
      "id": "1",
      "type": "time_off_request",
      "attributes": {
        "user_name": "John Doe",
        "start_date": "2025-01-15",
        "end_date": "2025-01-17",
        "reason": "Vacation",
        "status": "pending"
      }
    }
  ]
}
```

### Users

#### GET /api/v1/users
Get all users (Admin only).

#### GET /api/v1/users/:id
Get a specific user (Admin only).

## Error Responses

All error responses follow this format:
```json
{
  "errors": ["Error message here"]
}
```

Common HTTP status codes:
- `200` - Success
- `201` - Created
- `422` - Unprocessable Content (validation errors)
- `401` - Unauthorized
- `403` - Forbidden
