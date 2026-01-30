# Delivery Agent Authentication API Documentation

## Overview

This document provides complete API specifications for the Delivery Agent Authentication system. These endpoints are specifically designed for the Flutter Delivery App.

**Base URL:** `http://54.166.200.11:8001/api/v1/delivery/`

---

## Authentication Endpoints Summary

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/auth/register/` | POST | No | Agent self-registration |
| `/auth/login/` | POST | No | Agent login |
| `/auth/logout/` | POST | Yes | Agent logout |
| `/auth/forgot-password/` | POST | No | Request password reset OTP |
| `/auth/verify-otp/` | POST | No | Verify OTP code |
| `/auth/reset-password/` | POST | No | Reset password with OTP |
| `/auth/refresh/` | POST | No | Refresh access token |
| `/auth/change-password/` | POST | Yes | Change password (authenticated) |

---

## 1. Agent Registration

Register a new delivery agent account.

### Endpoint
```
POST /api/v1/delivery/auth/register/
```

### Request Headers
```
Content-Type: application/json
```

### Request Body
```json
{
    "mobile_number": "03001234567",
    "password": "SecurePass@123",
    "password_confirm": "SecurePass@123",
    "name": "Ahmed Khan",
    "email": "ahmed@example.com",
    "alternate_phone": "03009876543",
    "vehicle_type": "BIKE",
    "vehicle_number": "LEA-1234",
    "business_code": "1"
}
```

### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `mobile_number` | string | Yes | Agent's mobile number (supports +92, 92, or local format) |
| `password` | string | Yes | Password (min 8 chars, must include uppercase, lowercase, number) |
| `password_confirm` | string | Yes | Password confirmation (must match password) |
| `name` | string | Yes | Agent's full name |
| `email` | string | No | Email address |
| `alternate_phone` | string | No | Alternate contact number |
| `vehicle_type` | string | No | One of: BIKE, BICYCLE, CAR, VAN, TRUCK, WALK (default: BIKE) |
| `vehicle_number` | string | No | Vehicle registration number |
| `business_code` | string | No | Business ID or slug to join a specific business |

### Success Response (201 Created)
```json
{
    "success": true,
    "message": "Registration successful. Your account is pending verification.",
    "data": {
        "agent": {
            "id": 5,
            "agent_code": "DEL-0005",
            "name": "Ahmed Khan",
            "mobile_number": "03001234567",
            "email": "ahmed@example.com",
            "phone_number": "03001234567",
            "alternate_phone": "03009876543",
            "profile_photo": null,
            "vehicle_type": "BIKE",
            "vehicle_number": "LEA-1234",
            "status": "OFFLINE",
            "total_deliveries": 0,
            "successful_deliveries": 0,
            "average_rating": "0.00",
            "total_ratings": 0,
            "earnings_balance": "0.00",
            "is_active": true,
            "is_verified": false,
            "business_name": "Zayyrah Store",
            "date_joined": "2026-01-26"
        },
        "tokens": {
            "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
            "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
        },
        "is_verified": false
    }
}
```

### Error Response (400 Bad Request)
```json
{
    "success": false,
    "message": "Registration failed",
    "errors": {
        "mobile_number": ["An account with this mobile number already exists."],
        "password_confirm": ["Passwords don't match."]
    }
}
```

---

## 2. Agent Login

Authenticate a delivery agent and receive JWT tokens.

### Endpoint
```
POST /api/v1/delivery/auth/login/
```

### Request Headers
```
Content-Type: application/json
```

### Request Body
```json
{
    "mobile_number": "03001234567",
    "password": "SecurePass@123"
}
```

### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `mobile_number` | string | Yes | Agent's registered mobile number |
| `password` | string | Yes | Account password |

### Success Response (200 OK)
```json
{
    "success": true,
    "message": "Login successful",
    "data": {
        "agent": {
            "id": 5,
            "agent_code": "DEL-0005",
            "name": "Ahmed Khan",
            "mobile_number": "03001234567",
            "email": "ahmed@example.com",
            "phone_number": "03001234567",
            "alternate_phone": "03009876543",
            "profile_photo": null,
            "vehicle_type": "BIKE",
            "vehicle_number": "LEA-1234",
            "status": "AVAILABLE",
            "total_deliveries": 25,
            "successful_deliveries": 24,
            "average_rating": "4.75",
            "total_ratings": 20,
            "earnings_balance": "5000.00",
            "is_active": true,
            "is_verified": true,
            "business_name": "Zayyrah Store",
            "date_joined": "2026-01-15"
        },
        "tokens": {
            "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
            "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
        },
        "is_verified": true
    }
}
```

### Error Response (401 Unauthorized)
```json
{
    "success": false,
    "message": "Login failed",
    "errors": {
        "non_field_errors": ["Invalid mobile number or password."]
    }
}
```

### Error Response - Not a Delivery Agent
```json
{
    "success": false,
    "message": "Login failed",
    "errors": {
        "non_field_errors": ["This account is not registered as a delivery agent."]
    }
}
```

---

## 3. Agent Logout

Logout the agent and blacklist the refresh token.

### Endpoint
```
POST /api/v1/delivery/auth/logout/
```

### Request Headers
```
Content-Type: application/json
Authorization: Bearer <access_token>
```

### Request Body
```json
{
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `refresh_token` | string | No | Refresh token to blacklist |

### Success Response (200 OK)
```json
{
    "success": true,
    "message": "Logged out successfully"
}
```

### Notes
- Sets agent status to "OFFLINE"
- Blacklists the refresh token (if provided)
- Access token should be discarded on client side

---

## 4. Forgot Password

Request an OTP to reset the password.

### Endpoint
```
POST /api/v1/delivery/auth/forgot-password/
```

### Request Headers
```
Content-Type: application/json
```

### Request Body
```json
{
    "mobile_number": "03001234567"
}
```

### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `mobile_number` | string | Yes | Registered mobile number |

### Success Response (200 OK)
```json
{
    "success": true,
    "message": "OTP sent to your registered mobile number",
    "data": {
        "mobile_number": "03001234567",
        "expires_at": "2026-01-26T15:30:00+05:00",
        "otp_length": 6
    }
}
```

### Error Response (400 Bad Request)
```json
{
    "success": false,
    "message": "Request failed",
    "errors": {
        "mobile_number": ["No account found with this mobile number."]
    }
}
```

### Notes
- OTP is valid for 10 minutes
- Maximum 3 verification attempts allowed
- In development, OTP is printed to server terminal

---

## 5. Verify OTP

Verify the OTP code before resetting password.

### Endpoint
```
POST /api/v1/delivery/auth/verify-otp/
```

### Request Headers
```
Content-Type: application/json
```

### Request Body
```json
{
    "mobile_number": "03001234567",
    "otp_code": "123456"
}
```

### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `mobile_number` | string | Yes | Registered mobile number |
| `otp_code` | string | Yes | 6-digit OTP received |

### Success Response (200 OK)
```json
{
    "success": true,
    "message": "OTP verified successfully",
    "data": {
        "mobile_number": "03001234567",
        "verified": true
    }
}
```

### Error Response (400 Bad Request)
```json
{
    "success": false,
    "message": "OTP verification failed",
    "errors": {
        "otp_code": ["OTP has expired. Please request a new one."]
    }
}
```

---

## 6. Reset Password

Reset password using verified OTP.

### Endpoint
```
POST /api/v1/delivery/auth/reset-password/
```

### Request Headers
```
Content-Type: application/json
```

### Request Body
```json
{
    "mobile_number": "03001234567",
    "otp_code": "123456",
    "new_password": "NewSecurePass@123",
    "confirm_password": "NewSecurePass@123"
}
```

### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `mobile_number` | string | Yes | Registered mobile number |
| `otp_code` | string | Yes | Valid OTP code |
| `new_password` | string | Yes | New password |
| `confirm_password` | string | Yes | Password confirmation |

### Success Response (200 OK)
```json
{
    "success": true,
    "message": "Password reset successful",
    "data": {
        "agent": {
            "id": 5,
            "agent_code": "DEL-0005",
            "name": "Ahmed Khan",
            "mobile_number": "03001234567",
            "email": "ahmed@example.com",
            "status": "OFFLINE",
            "is_verified": true,
            "business_name": "Zayyrah Store"
        },
        "tokens": {
            "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
            "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
        }
    }
}
```

### Error Response (400 Bad Request)
```json
{
    "success": false,
    "message": "Password reset failed",
    "errors": {
        "confirm_password": ["Passwords don't match."],
        "otp_code": ["Invalid or expired OTP."]
    }
}
```

### Notes
- Returns JWT tokens for immediate login after password reset
- OTP is marked as used after successful reset

---

## 7. Refresh Token

Get a new access token using the refresh token.

### Endpoint
```
POST /api/v1/delivery/auth/refresh/
```

### Request Headers
```
Content-Type: application/json
```

### Request Body
```json
{
    "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `refresh_token` | string | Yes | Valid refresh token |

### Success Response (200 OK)
```json
{
    "success": true,
    "message": "Token refreshed",
    "data": {
        "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
    }
}
```

### Error Response (401 Unauthorized)
```json
{
    "success": false,
    "message": "Invalid or expired refresh token"
}
```

---

## 8. Change Password

Change password for authenticated agent.

### Endpoint
```
POST /api/v1/delivery/auth/change-password/
```

### Request Headers
```
Content-Type: application/json
Authorization: Bearer <access_token>
```

### Request Body
```json
{
    "current_password": "OldPassword@123",
    "new_password": "NewPassword@123",
    "confirm_password": "NewPassword@123"
}
```

### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `current_password` | string | Yes | Current password |
| `new_password` | string | Yes | New password |
| `confirm_password` | string | Yes | Confirm new password |

### Success Response (200 OK)
```json
{
    "success": true,
    "message": "Password changed successfully",
    "data": {
        "tokens": {
            "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
            "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
        }
    }
}
```

### Error Response (400 Bad Request)
```json
{
    "success": false,
    "message": "Current password is incorrect"
}
```

---

## Agent Profile Endpoints (Authenticated)

After login, use these endpoints to manage the agent's profile and work.

### Get Profile
```
GET /api/v1/delivery/agents/profile/
Authorization: Bearer <access_token>
```

### Update Status
```
PATCH /api/v1/delivery/agents/status/
Authorization: Bearer <access_token>

{
    "status": "AVAILABLE",
    "latitude": 31.5204,
    "longitude": 74.3587
}
```

Status options: `AVAILABLE`, `BUSY`, `OFFLINE`, `ON_BREAK`

### Update Location
```
POST /api/v1/delivery/agents/location/
Authorization: Bearer <access_token>

{
    "locations": [
        {
            "latitude": 31.5204,
            "longitude": 74.3587,
            "accuracy": 10.5,
            "speed": 25.0,
            "heading": 180,
            "battery_level": 85
        }
    ],
    "assignment_id": 123
}
```

---

## Complete URL Reference

### Authentication (Public)
```
POST http://54.166.200.11:8001/api/v1/delivery/auth/register/
POST http://54.166.200.11:8001/api/v1/delivery/auth/login/
POST http://54.166.200.11:8001/api/v1/delivery/auth/logout/
POST http://54.166.200.11:8001/api/v1/delivery/auth/forgot-password/
POST http://54.166.200.11:8001/api/v1/delivery/auth/verify-otp/
POST http://54.166.200.11:8001/api/v1/delivery/auth/reset-password/
POST http://54.166.200.11:8001/api/v1/delivery/auth/refresh/
POST http://54.166.200.11:8001/api/v1/delivery/auth/change-password/
```

### Agent Profile (Authenticated)
```
GET    http://54.166.200.11:8001/api/v1/delivery/agents/profile/
PATCH  http://54.166.200.11:8001/api/v1/delivery/agents/profile/
PATCH  http://54.166.200.11:8001/api/v1/delivery/agents/status/
POST   http://54.166.200.11:8001/api/v1/delivery/agents/location/
GET    http://54.166.200.11:8001/api/v1/delivery/agents/earnings/
GET    http://54.166.200.11:8001/api/v1/delivery/agents/statistics/
```

### Order Management (Authenticated)
```
GET    http://54.166.200.11:8001/api/v1/delivery/orders/
GET    http://54.166.200.11:8001/api/v1/delivery/orders/pending/
GET    http://54.166.200.11:8001/api/v1/delivery/orders/{id}/
POST   http://54.166.200.11:8001/api/v1/delivery/orders/{id}/accept/
POST   http://54.166.200.11:8001/api/v1/delivery/orders/{id}/reject/
POST   http://54.166.200.11:8001/api/v1/delivery/orders/{id}/pickup/
POST   http://54.166.200.11:8001/api/v1/delivery/orders/{id}/in-transit/
POST   http://54.166.200.11:8001/api/v1/delivery/orders/{id}/arrived/
POST   http://54.166.200.11:8001/api/v1/delivery/orders/{id}/deliver/
POST   http://54.166.200.11:8001/api/v1/delivery/orders/{id}/fail/
POST   http://54.166.200.11:8001/api/v1/delivery/orders/{id}/cod-collect/
```

---

## Flutter Integration Example

### Auth Service (Dart)
```dart
class DeliveryAuthService {
  static const String baseUrl = 'http://54.166.200.11:8001/api/v1/delivery';

  // Login
  Future<AuthResponse> login(String mobile, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile_number': mobile,
        'password': password,
      }),
    );
    return AuthResponse.fromJson(jsonDecode(response.body));
  }

  // Register
  Future<AuthResponse> register({
    required String mobile,
    required String password,
    required String name,
    String? vehicleType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile_number': mobile,
        'password': password,
        'password_confirm': password,
        'name': name,
        'vehicle_type': vehicleType ?? 'BIKE',
      }),
    );
    return AuthResponse.fromJson(jsonDecode(response.body));
  }

  // Refresh Token
  Future<String?> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['access'];
    }
    return null;
  }
}
```

---

## Error Codes Reference

| HTTP Code | Meaning |
|-----------|---------|
| 200 | Success |
| 201 | Created (Registration successful) |
| 400 | Bad Request (Validation errors) |
| 401 | Unauthorized (Invalid credentials/token) |
| 403 | Forbidden (Account disabled/not verified) |
| 404 | Not Found |
| 500 | Server Error |

---

## Notes

1. **Mobile Number Formats**: The API accepts these formats:
   - `03001234567` (local)
   - `+923001234567` (international)
   - `923001234567` (without +)
   - `3001234567` (10 digits)

2. **Token Expiry**:
   - Access Token: 30 minutes
   - Refresh Token: 7 days

3. **Password Requirements**:
   - Minimum 8 characters
   - At least one uppercase letter
   - At least one lowercase letter
   - At least one number

4. **Agent Verification**: New agents are created with `is_verified: false`. Business admin must verify them before they can receive orders.
