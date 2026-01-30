# Delivery Agent Mobile App - Flutter Development Guide

## Overview

This document provides complete API specifications for the Flutter team to build the **Delivery Agent Mobile App**. The app enables delivery personnel to manage their deliveries, update order statuses, track earnings, and provide proof of delivery.

**Base URL:** `http://54.166.200.11:8002/api/v1/`
**Authentication:** JWT Bearer Token
**Content-Type:** `application/json` (unless uploading files, then `multipart/form-data`)

---

## Table of Contents

1. [Authentication](#1-authentication)
2. [App Screens Overview](#2-app-screens-overview)
3. [API Endpoints by Screen](#3-api-endpoints-by-screen)
4. [Data Models](#4-data-models)
5. [Status Workflows](#5-status-workflows)
6. [Error Handling](#6-error-handling)
7. [Real-time Features](#7-real-time-features)

---

## 1. Authentication

### 1.1 Login

**Screen:** Login Screen

```
POST /accounts/login/
```

**Request Body:**
```json
{
  "mobile_number": "03101234567",
  "password": "Agent@123"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "id": 28,
    "mobile_number": "03101234567",
    "email": null,
    "account_type": "business",
    "shop_name": "Ahmad Delivery",
    "is_active": true,
    "date_joined": "2026-01-25T18:28:03.207603Z"
  },
  "tokens": {
    "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Flutter Implementation Notes:**
- Store `access` token in secure storage (flutter_secure_storage)
- Store `refresh` token for token renewal
- Access token expires in 24 hours
- Include token in all subsequent requests: `Authorization: Bearer <access_token>`

### 1.2 Refresh Token

```
POST /accounts/token/refresh/
```

**Request Body:**
```json
{
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

## 2. App Screens Overview

| # | Screen Name | Primary APIs | Description |
|---|-------------|--------------|-------------|
| 1 | Login | `/accounts/login/` | Agent login |
| 2 | Home/Dashboard | `/delivery/agents/profile/`, `/delivery/orders/` | Overview with active orders |
| 3 | Profile | `/delivery/agents/profile/` | View/edit profile |
| 4 | Go Online/Offline | `/delivery/agents/status/` | Toggle availability |
| 5 | Pending Orders | `/delivery/orders/pending/` | Orders waiting to be accepted |
| 6 | Order Details | `/delivery/orders/{id}/` | Full order information |
| 7 | Active Delivery | Multiple status APIs | Ongoing delivery workflow |
| 8 | Delivery Completion | `/delivery/orders/{id}/deliver/` | Complete with proof |
| 9 | Failed Delivery | `/delivery/orders/{id}/fail/` | Mark delivery as failed |
| 10 | Earnings | `/delivery/agents/earnings/` | View earnings |
| 11 | Statistics | `/delivery/agents/statistics/` | Performance metrics |

---

## 3. API Endpoints by Screen

### 3.1 Home/Dashboard Screen

#### Get Agent Profile

```
GET /delivery/agents/profile/
```

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "agent_code": "DEL-4133",
    "name": "Ahmad Delivery",
    "phone_number": "03101234567",
    "alternate_phone": "",
    "profile_photo": null,
    "vehicle_type": "BIKE",
    "vehicle_number": "ABC-1234",
    "status": "AVAILABLE",
    "total_deliveries": 150,
    "successful_deliveries": 145,
    "average_rating": "4.75",
    "total_ratings": 120,
    "earnings_balance": "5000.00",
    "total_earnings": "45000.00",
    "is_verified": true
  }
}
```

**Usage:** Display agent info, rating, today's earnings summary on dashboard.

---

#### Get Active Orders (Dashboard)

```
GET /delivery/orders/
```

**Optional Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | Filter by status (e.g., `ACCEPTED`, `IN_TRANSIT`) |
| `date` | string | Filter by date (YYYY-MM-DD) |

**Response:**
```json
{
  "success": true,
  "data": {
    "active_orders": [
      {
        "id": 45,
        "assignment_number": "DEL-2024-00045",
        "order_number": "ORD-2024-00123",
        "order_total": "2500.00",
        "payment_method": "COD",
        "status": "ACCEPTED",
        "priority": 1,
        "customer_name": "Ali Khan",
        "agent_name": "Ahmad Delivery",
        "zone_name": "Downtown Lahore",
        "delivery_address": "123 Main Street, Gulberg",
        "cod_amount": "2500.00",
        "scheduled_delivery_time": "2026-01-25T14:00:00Z",
        "created_at": "2026-01-25T10:30:00Z"
      }
    ],
    "completed_today": 5,
    "pending_count": 2
  }
}
```

**Usage:** Show active orders list, today's completed count, pending notifications.

---

### 3.2 Profile Screen

#### Update Profile

```
PATCH /delivery/agents/profile/
```

**Request Body (multipart/form-data for photo):**
```json
{
  "phone_number": "03101234567",
  "alternate_phone": "03219876543",
  "vehicle_number": "ABC-5678"
}
```

**For profile photo upload:**
```
Content-Type: multipart/form-data

profile_photo: <file>
```

**Response:**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": 1,
    "agent_code": "DEL-4133",
    "name": "Ahmad Delivery",
    "phone_number": "03101234567",
    "alternate_phone": "03219876543",
    "profile_photo": "/media/delivery_agents/photos/agent_1.jpg",
    "vehicle_type": "BIKE",
    "vehicle_number": "ABC-5678",
    "status": "AVAILABLE"
  }
}
```

---

### 3.3 Go Online/Offline Screen

#### Update Status

```
PATCH /delivery/agents/status/
```

**Request Body:**
```json
{
  "status": "AVAILABLE",
  "latitude": "31.5497",
  "longitude": "74.3436"
}
```

**Valid Status Values:**
| Status | Description | Color Suggestion |
|--------|-------------|------------------|
| `AVAILABLE` | Ready to receive orders | Green |
| `BUSY` | Currently on delivery | Yellow |
| `OFFLINE` | Not working | Gray |
| `ON_BREAK` | Taking a break | Orange |

**Response:**
```json
{
  "success": true,
  "message": "Status updated to Available",
  "data": {
    "status": "AVAILABLE",
    "last_location_update": "2026-01-25T18:29:08.926445Z"
  }
}
```

**Flutter Implementation Notes:**
- Call this API when agent toggles online/offline switch
- Include current GPS coordinates
- Update local state and UI accordingly

---

### 3.4 Location Updates (Background Service)

#### Send Location Batch

```
POST /delivery/agents/location/
```

**Request Body:**
```json
{
  "assignment_id": 45,
  "locations": [
    {
      "latitude": "31.5497",
      "longitude": "74.3436",
      "timestamp": "2026-01-25T18:30:00Z",
      "speed": 25.5,
      "heading": 90,
      "accuracy": 10.0,
      "battery_level": 85
    },
    {
      "latitude": "31.5500",
      "longitude": "74.3440",
      "timestamp": "2026-01-25T18:30:30Z",
      "speed": 30.2,
      "heading": 95,
      "accuracy": 8.0,
      "battery_level": 84
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Location updated",
  "data": {
    "logged_count": 2,
    "current_location": {
      "latitude": "31.5500",
      "longitude": "74.3440"
    }
  }
}
```

**Flutter Implementation Notes:**
- Use `geolocator` package for GPS
- Send locations in batches (every 30 seconds or 5-10 points)
- Store locally if offline, sync when connected
- Include `assignment_id` when on active delivery
- Run as background service using `workmanager` or `flutter_background_service`

---

### 3.5 Pending Orders Screen

#### Get Pending Orders

```
GET /delivery/orders/pending/
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 46,
      "assignment_number": "DEL-2024-00046",
      "order_number": "ORD-2024-00124",
      "order_total": "1800.00",
      "payment_method": "PREPAID",
      "status": "ASSIGNED",
      "priority": 2,
      "customer_name": "Sara Ahmed",
      "agent_name": null,
      "zone_name": "Gulberg District",
      "delivery_address": "45 Liberty Market, Gulberg",
      "cod_amount": "0.00",
      "scheduled_delivery_time": "2026-01-25T15:00:00Z",
      "created_at": "2026-01-25T11:00:00Z"
    }
  ]
}
```

**Usage:** Show list of orders waiting for agent to accept/reject.

---

### 3.6 Order Details Screen

#### Get Order Details

```
GET /delivery/orders/{assignment_id}/
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 45,
    "assignment_number": "DEL-2024-00045",
    "status": "ACCEPTED",
    "priority": 1,
    "order": {
      "order_number": "ORD-2024-00123",
      "status": "PROCESSING",
      "subtotal": 2300.00,
      "tax_total": 200.00,
      "shipping_total": 0,
      "total_amount": 2500.00,
      "payment_method": "COD",
      "payment_status": "PENDING",
      "customer_notes": "Please call before arriving",
      "items": [
        {
          "product_name": "Samsung Galaxy A54",
          "quantity": 1,
          "unit_price": 2300.00,
          "line_total": 2300.00
        }
      ]
    },
    "customer": {
      "name": "Ali Khan",
      "phone": "03001234567",
      "email": "ali@example.com"
    },
    "pickup_location": {
      "name": "TestStore",
      "address": "Shop 5, Main Market",
      "phone": "",
      "latitude": 31.5204,
      "longitude": 74.3587
    },
    "delivery_location": {
      "name": "Ali Khan",
      "phone": "03001234567",
      "address": "123 Main Street, Gulberg",
      "city": "Lahore",
      "state": "Punjab",
      "postal_code": "54000",
      "latitude": 31.5150,
      "longitude": 74.3500
    },
    "timestamps": {
      "created_at": "2026-01-25T10:30:00Z",
      "assigned_at": "2026-01-25T10:35:00Z",
      "accepted_at": "2026-01-25T10:40:00Z",
      "picked_up_at": null,
      "in_transit_at": null,
      "arrived_at": null,
      "delivered_at": null,
      "failed_at": null,
      "scheduled_pickup_time": "2026-01-25T11:00:00Z",
      "scheduled_delivery_time": "2026-01-25T14:00:00Z"
    },
    "distance_km": "5.50",
    "delivery_fee": "150.00",
    "agent_commission": "15.00",
    "cod_amount": "2500.00",
    "cod_collected": "0.00",
    "cod_status": "PENDING",
    "delivery_photo": null,
    "signature_image": null,
    "recipient_name": "",
    "delivery_notes": "",
    "failure_reason": null,
    "failure_notes": "",
    "retry_count": 0,
    "max_retries": 3,
    "customer_rating": null,
    "customer_feedback": "",
    "tip_amount": "0.00",
    "status_history": [
      {
        "from_status": "PENDING",
        "to_status": "ASSIGNED",
        "changed_at": "2026-01-25T10:35:00Z",
        "notes": ""
      },
      {
        "from_status": "ASSIGNED",
        "to_status": "ACCEPTED",
        "changed_at": "2026-01-25T10:40:00Z",
        "notes": ""
      }
    ],
    "route": {
      "distance_km": 5.5,
      "estimated_duration_minutes": 30,
      "navigation_url": "https://www.google.com/maps/dir/?api=1&destination=31.5150,74.3500"
    },
    "created_at": "2026-01-25T10:30:00Z",
    "updated_at": "2026-01-25T10:40:00Z"
  }
}
```

**Flutter Implementation Notes:**
- Use `navigation_url` to launch Google Maps for navigation
- Display order items in expandable list
- Show pickup → delivery addresses on map
- Highlight COD amount if payment_method is COD

---

### 3.7 Order Actions (Delivery Workflow)

#### Accept Order

**Screen:** Pending Orders / Order Details

```
POST /delivery/orders/{assignment_id}/accept/
```

**Request Body:**
```json
{
  "latitude": "31.5497",
  "longitude": "74.3436"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Order accepted successfully",
  "data": {
    "id": 45,
    "status": "ACCEPTED",
    "accepted_at": "2026-01-25T10:40:00Z"
  }
}
```

---

#### Reject Order

**Screen:** Pending Orders / Order Details

```
POST /delivery/orders/{assignment_id}/reject/
```

**Request Body:**
```json
{
  "reason": "Too far from current location",
  "latitude": "31.5497",
  "longitude": "74.3436"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Order rejected",
  "data": {
    "id": 45,
    "status": "REJECTED"
  }
}
```

---

#### Mark as Picked Up

**Screen:** Active Delivery (at store)

```
POST /delivery/orders/{assignment_id}/pickup/
```

**Request Body (multipart/form-data):**
```json
{
  "latitude": "31.5204",
  "longitude": "74.3587",
  "notes": "All items verified",
  "photo": "<file>"  // Optional pickup photo
}
```

**Response:**
```json
{
  "success": true,
  "message": "Order picked up",
  "data": {
    "id": 45,
    "status": "PICKED_UP",
    "picked_up_at": "2026-01-25T11:15:00Z"
  }
}
```

---

#### Start Delivery (In Transit)

**Screen:** Active Delivery (leaving store)

```
POST /delivery/orders/{assignment_id}/in-transit/
```

**Request Body:**
```json
{
  "latitude": "31.5204",
  "longitude": "74.3587"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Delivery started",
  "data": {
    "id": 45,
    "status": "IN_TRANSIT",
    "in_transit_at": "2026-01-25T11:20:00Z"
  }
}
```

---

#### Mark as Arrived

**Screen:** Active Delivery (at customer location)

```
POST /delivery/orders/{assignment_id}/arrived/
```

**Request Body:**
```json
{
  "latitude": "31.5150",
  "longitude": "74.3500"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Marked as arrived",
  "data": {
    "id": 45,
    "status": "ARRIVED",
    "arrived_at": "2026-01-25T11:45:00Z"
  }
}
```

---

### 3.8 Delivery Completion Screen

#### Complete Delivery

```
POST /delivery/orders/{assignment_id}/deliver/
```

**Request Body (multipart/form-data):**
```json
{
  "latitude": "31.5150",
  "longitude": "74.3500",
  "recipient_name": "Ali Khan",
  "delivery_notes": "Received by customer",
  "cod_collected": "2500.00",
  "delivery_photo": "<file>",
  "signature_image": "<file>"
}
```

**Field Details:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `latitude` | decimal | No | Current GPS latitude |
| `longitude` | decimal | No | Current GPS longitude |
| `recipient_name` | string | No | Name of person who received |
| `delivery_notes` | string | No | Any notes about delivery |
| `cod_collected` | decimal | If COD | Amount collected (must match COD amount) |
| `delivery_photo` | file | Recommended | Photo proof of delivery |
| `signature_image` | file | Recommended | Customer signature image |

**Response:**
```json
{
  "success": true,
  "message": "Delivery completed successfully",
  "data": {
    "id": 45,
    "status": "DELIVERED",
    "delivered_at": "2026-01-25T11:50:00Z",
    "cod_collected": 2500.00,
    "agent_commission": 15.00,
    "delivery_duration_minutes": 80
  }
}
```

**Flutter Implementation Notes:**
- Use `image_picker` package for delivery photo
- Use `signature_pad` package for customer signature
- For COD orders, show calculator/numpad for amount entry
- Validate COD amount matches expected amount
- Show success animation after completion

---

### 3.9 Failed Delivery Screen

#### Mark Delivery as Failed

```
POST /delivery/orders/{assignment_id}/fail/
```

**Request Body:**
```json
{
  "latitude": "31.5150",
  "longitude": "74.3500",
  "failure_reason": "CUSTOMER_UNAVAILABLE",
  "failure_notes": "Called 3 times, no response"
}
```

**Valid Failure Reasons:**
| Code | Display Text |
|------|--------------|
| `CUSTOMER_UNAVAILABLE` | Customer Not Available |
| `WRONG_ADDRESS` | Wrong/Incomplete Address |
| `CUSTOMER_REFUSED` | Customer Refused |
| `DAMAGED_GOODS` | Goods Damaged |
| `PAYMENT_ISSUE` | Payment Issue (COD) |
| `WEATHER` | Bad Weather |
| `VEHICLE_ISSUE` | Vehicle Breakdown |
| `OTHER` | Other |

**Response:**
```json
{
  "success": true,
  "message": "Delivery marked as failed",
  "data": {
    "id": 45,
    "status": "FAILED",
    "failure_reason": "CUSTOMER_UNAVAILABLE",
    "retry_count": 1,
    "max_retries": 3,
    "can_retry": true
  }
}
```

**Flutter Implementation Notes:**
- Show dropdown for failure reason selection
- If "OTHER" selected, show text field for notes
- Show `can_retry` status to agent

---

### 3.10 COD Collection Screen

#### Record COD Collection (Separate from delivery)

```
POST /delivery/orders/{assignment_id}/cod-collect/
```

**Request Body:**
```json
{
  "amount_collected": "2500.00",
  "payment_method": "CASH",
  "notes": "Exact amount received"
}
```

**Response:**
```json
{
  "success": true,
  "message": "COD collection recorded",
  "data": {
    "cod_amount": 2500.00,
    "cod_collected": 2500.00,
    "cod_status": "COLLECTED"
  }
}
```

---

### 3.11 Earnings Screen

#### Get Earnings

```
GET /delivery/agents/earnings/
```

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `period` | string | `today` | `today`, `week`, `month` |
| `start_date` | date | - | Custom start date (YYYY-MM-DD) |
| `end_date` | date | - | Custom end date (YYYY-MM-DD) |

**Example:** `GET /delivery/agents/earnings/?period=week`

**Response:**
```json
{
  "success": true,
  "data": {
    "summary": {
      "total_earnings": 5500.00,
      "delivery_commission": 4500.00,
      "tips": 800.00,
      "bonuses": 500.00,
      "deductions": 300.00,
      "pending_payout": 2000.00,
      "paid_amount": 3500.00
    },
    "deliveries_count": 45,
    "average_per_delivery": 122.22,
    "transactions": [
      {
        "id": 1,
        "assignment_number": "DEL-2024-00045",
        "earning_type": "DELIVERY",
        "amount": "15.00",
        "description": "Delivery commission for DEL-2024-00045",
        "is_paid": false,
        "created_at": "2026-01-25T11:50:00Z"
      },
      {
        "id": 2,
        "assignment_number": "DEL-2024-00045",
        "earning_type": "TIP",
        "amount": "50.00",
        "description": "Customer tip for DEL-2024-00045",
        "is_paid": false,
        "created_at": "2026-01-25T12:00:00Z"
      }
    ]
  }
}
```

**Earning Types:**
| Type | Description |
|------|-------------|
| `DELIVERY` | Commission from delivery |
| `TIP` | Customer tip |
| `BONUS` | Performance bonus |
| `PENALTY` | Deduction/penalty |
| `ADJUSTMENT` | Manual adjustment |

---

### 3.12 Statistics Screen

#### Get Performance Statistics

```
GET /delivery/agents/statistics/
```

**Response:**
```json
{
  "success": true,
  "data": {
    "performance": {
      "total_deliveries": 150,
      "successful_deliveries": 145,
      "failed_deliveries": 5,
      "success_rate": 96.67,
      "average_rating": 4.75,
      "total_ratings": 120,
      "on_time_rate": 95.0
    },
    "today": {
      "deliveries_completed": 8,
      "earnings": 1200.00,
      "hours_online": 6,
      "distance_covered_km": 45
    },
    "this_week": {
      "deliveries_completed": 45,
      "earnings": 5500.00,
      "average_per_day": 785.71
    },
    "rating_breakdown": {
      "1_star": 2,
      "2_star": 3,
      "3_star": 10,
      "4_star": 35,
      "5_star": 70
    }
  }
}
```

**Flutter Implementation Notes:**
- Use charts package (fl_chart) for rating breakdown
- Show progress indicators for success_rate and on_time_rate
- Highlight today's performance prominently

---

## 4. Data Models

### 4.1 Agent Status Values

```dart
enum AgentStatus {
  AVAILABLE,   // Ready to receive orders
  BUSY,        // Currently on delivery
  OFFLINE,     // Not working
  ON_BREAK,    // Taking a break
}
```

### 4.2 Order/Assignment Status Values

```dart
enum DeliveryStatus {
  PENDING,      // Waiting for agent assignment
  ASSIGNED,     // Assigned to agent (pending acceptance)
  ACCEPTED,     // Agent accepted the order
  REJECTED,     // Agent rejected the order
  PICKED_UP,    // Picked up from store
  IN_TRANSIT,   // On the way to customer
  ARRIVED,      // Arrived at customer location
  DELIVERED,    // Successfully delivered
  FAILED,       // Delivery failed
  RETURNED,     // Returned to store
  CANCELLED,    // Order cancelled
}
```

### 4.3 Priority Levels

```dart
enum OrderPriority {
  NORMAL = 1,
  HIGH = 2,
  EXPRESS = 3,
}
```

### 4.4 COD Status Values

```dart
enum CODStatus {
  NOT_APPLICABLE,  // Not a COD order
  PENDING,         // Awaiting collection
  COLLECTED,       // Cash collected
  DEPOSITED,       // Deposited to business
}
```

### 4.5 Payment Methods

```dart
enum PaymentMethod {
  COD,       // Cash on Delivery
  PREPAID,   // Already paid online
  CARD,      // Card payment
}
```

---

## 5. Status Workflows

### 5.1 Happy Path (Successful Delivery)

```
ASSIGNED → ACCEPTED → PICKED_UP → IN_TRANSIT → ARRIVED → DELIVERED
```

### 5.2 Agent Rejects

```
ASSIGNED → REJECTED
```
Order goes back to pool for reassignment.

### 5.3 Delivery Failed

```
ASSIGNED → ACCEPTED → PICKED_UP → IN_TRANSIT → ARRIVED → FAILED
```
Can be retried up to `max_retries` times.

### 5.4 Status Button Logic

| Current Status | Available Actions |
|----------------|-------------------|
| ASSIGNED | Accept, Reject |
| ACCEPTED | Mark Picked Up |
| PICKED_UP | Start Delivery |
| IN_TRANSIT | Mark Arrived |
| ARRIVED | Complete Delivery, Mark Failed |

---

## 6. Error Handling

### 6.1 Standard Error Response

```json
{
  "success": false,
  "message": "Error description",
  "errors": {
    "field_name": ["Error message"]
  }
}
```

### 6.2 HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Process response |
| 400 | Bad Request | Show validation errors |
| 401 | Unauthorized | Redirect to login |
| 403 | Forbidden | Show access denied |
| 404 | Not Found | Show not found message |
| 500 | Server Error | Show retry option |

### 6.3 Token Expired

When you receive 401 with token expired message:
1. Call `/accounts/token/refresh/` with refresh token
2. If successful, update access token and retry original request
3. If refresh fails, redirect to login screen

---

## 7. Real-time Features

### 7.1 Background Location Service

**Recommended Packages:**
- `geolocator` - GPS location
- `flutter_background_service` - Background execution
- `workmanager` - Periodic tasks

**Implementation:**
```dart
// Send location every 30 seconds when AVAILABLE or on delivery
Timer.periodic(Duration(seconds: 30), (timer) {
  if (agentStatus == 'AVAILABLE' || hasActiveDelivery) {
    sendLocationBatch();
  }
});
```

### 7.2 Push Notifications

**Events to Handle:**
| Event | Notification | Action |
|-------|--------------|--------|
| New Order Assigned | "New delivery assigned!" | Open pending orders |
| Order Reassigned | "Order reassigned" | Refresh orders |
| Order Cancelled | "Order cancelled by customer" | Remove from list |

**Recommended Package:** `firebase_messaging`

### 7.3 Offline Support

Store these locally when offline:
- Location updates (sync when online)
- Order list cache
- Profile data

**Recommended Package:** `hive` or `sqflite`

---

## 8. Recommended Flutter Packages

| Purpose | Package |
|---------|---------|
| HTTP Client | `dio` |
| State Management | `riverpod` or `bloc` |
| Secure Storage | `flutter_secure_storage` |
| GPS | `geolocator` |
| Maps | `google_maps_flutter` |
| Image Picker | `image_picker` |
| Signature | `signature` |
| Charts | `fl_chart` |
| Local DB | `hive` |
| Push Notifications | `firebase_messaging` |
| Background Tasks | `flutter_background_service` |

---

## 9. Screen Mockup Reference

### Login Screen
- Mobile number input
- Password input
- Login button
- "Forgot Password?" link

### Home/Dashboard
- Agent profile card (photo, name, rating)
- Online/Offline toggle
- Today's summary (deliveries, earnings)
- Active orders list
- Bottom navigation

### Order Card Components
- Order number
- Customer name
- Address (shortened)
- COD amount badge (if applicable)
- Priority badge
- Status chip
- Time elapsed/remaining

### Delivery Screen
- Map with route
- Pickup/Delivery markers
- Current location
- Order details card
- Action button (changes based on status)
- Call customer button
- Navigate button

### Completion Screen
- Camera for delivery photo
- Signature pad
- COD amount input (if applicable)
- Recipient name input
- Notes input
- Complete button

---

## 10. Testing Credentials

**Test Agent Account:**
```
Mobile: 03101234567
Password: Agent@123
```

**Test API Base URLs:**
- Development: `http://localhost:8001/api/v1/`
- Production: `http://54.166.200.11:8002/api/v1/`

---

## 11. Contact

For API issues or questions, contact the backend team with:
- API endpoint
- Request body
- Response received
- Expected behavior

---

*Document Version: 1.0*
*Last Updated: January 25, 2026*
