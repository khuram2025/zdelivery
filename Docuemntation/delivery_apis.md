# Delivery APIs Documentation

Complete API documentation for the Home Delivery module. Includes Business Owner APIs, Delivery Agent APIs, and Public APIs.

**Base URL:** `/api/v1/delivery/`

**Authentication:** JWT Bearer Token (required for most endpoints)

---

## Table of Contents

1. [Business Owner APIs](#business-owner-apis)
   - [Dashboard & Stats](#dashboard--stats)
   - [Order Management](#order-management)
   - [Order Editing](#order-editing)
   - [Schedule Management](#schedule-management)
   - [Search & Helpers](#search--helpers)
2. [Delivery Agent APIs](#delivery-agent-apis)
   - [Authentication](#agent-authentication)
   - [Profile & Status](#agent-profile--status)
   - [Orders](#agent-orders)
   - [Mobile Dashboard](#mobile-dashboard)
3. [Public APIs](#public-apis)
   - [Tracking](#tracking)
   - [Zone & Fee](#zone--fee)

---

## Business Owner APIs

APIs for business owners to manage delivery orders via mobile app (Flutter).

**Authentication:** Requires business owner JWT token.

### Dashboard & Stats

#### Get Delivery Statistics

```
GET /api/v1/delivery/business/stats/
```

Get dashboard statistics for the business.

**Query Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| date | string | No | Today | Date filter (YYYY-MM-DD) |

**Response:**
```json
{
    "success": true,
    "date": "2026-01-28",
    "stats": {
        "today_total": 25,
        "pending": 8,
        "in_transit": 5,
        "delivered_today": 10,
        "cancelled_today": 1,
        "failed_today": 1,
        "revenue_today": 15000.00,
        "delivery_fees_today": 500.00,
        "agents": {
            "total": 5,
            "available": 2,
            "busy": 2,
            "offline": 1
        }
    }
}
```

---

#### List Delivery Agents

```
GET /api/v1/delivery/business/agents/
```

Get all delivery agents for the business.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| status | string | No | Filter by status (AVAILABLE, BUSY, OFFLINE, ON_BREAK) |

**Response:**
```json
{
    "success": true,
    "agents": [
        {
            "id": 1,
            "agent_code": "DEL-0001",
            "name": "John Rider",
            "phone_number": "03001234567",
            "profile_photo": "/media/agents/photo.jpg",
            "vehicle_type": "BIKE",
            "status": "AVAILABLE",
            "current_orders": 0,
            "total_deliveries": 150,
            "average_rating": 4.5,
            "is_verified": true,
            "is_active": true,
            "zones": ["Zone A", "Zone B"]
        }
    ],
    "stats": {
        "total": 5,
        "available": 2,
        "busy": 2,
        "offline": 1
    }
}
```

---

#### List Delivery Zones

```
GET /api/v1/delivery/business/zones/
```

Get all delivery zones for the business.

**Query Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| active_only | bool | No | false | Only return active zones |

**Response:**
```json
{
    "success": true,
    "zones": [
        {
            "id": 1,
            "name": "Zone A - Downtown",
            "code": "ZONE-DT-001",
            "base_delivery_fee": 50.00,
            "minimum_order_value": 500.00,
            "estimated_delivery_minutes": 30,
            "is_active": true,
            "agents_count": 3,
            "orders_today": 12
        }
    ]
}
```

---

### Order Management

#### List Orders

```
GET /api/v1/delivery/business/orders/
```

List delivery orders with filtering and pagination.

**Query Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| status | string | No | all | Filter by status (PENDING, PREPARING, READY, ASSIGNED, OUT_FOR_DELIVERY, DELIVERED, CANCELLED, FAILED) |
| date | string | No | Today | Date filter (YYYY-MM-DD) or 'all' for all dates |
| search | string | No | - | Search by order number, customer name, or mobile |
| page | int | No | 1 | Page number |
| page_size | int | No | 20 | Items per page (max: 100) |

**Response:**
```json
{
    "success": true,
    "total": 150,
    "page": 1,
    "page_size": 20,
    "total_pages": 8,
    "orders": [
        {
            "id": 123,
            "order_number": "HD-20260128-0001",
            "status": "PENDING",
            "status_display": "Pending",
            "priority": 1,
            "priority_display": "Normal",
            "customer_name": "Ahmed Khan",
            "customer_mobile": "03001234567",
            "delivery_address": "123 Main Street, Lahore",
            "delivery_city": "Lahore",
            "subtotal": 1500.00,
            "delivery_fee": 50.00,
            "discount": 0.00,
            "total": 1550.00,
            "payment_method": "COD",
            "payment_method_display": "Cash on Delivery",
            "payment_status": "PENDING",
            "scheduled_date": "2026-01-28",
            "scheduled_time": "14:00",
            "deliver_asap": false,
            "is_scheduled": true,
            "items_count": 3,
            "business_name": "My Store",
            "time_since_created": "10 min ago",
            "created_at": "2026-01-28T10:30:00Z"
        }
    ]
}
```

---

#### Create Order

```
POST /api/v1/delivery/business/orders/create/
```

Create a new delivery order.

**Request Body:**
```json
{
    "customer_name": "Ahmed Khan",
    "customer_mobile": "03001234567",
    "delivery_address": "123 Main Street, Lahore",
    "delivery_city": "Lahore",
    "delivery_area": "Gulberg",
    "delivery_latitude": 31.5204,
    "delivery_longitude": 74.3587,
    "zone_id": 1,
    "payment_method": "COD",
    "priority": 1,
    "customer_notes": "Ring doorbell twice",
    "internal_notes": "VIP customer",
    "deliver_asap": false,
    "scheduled_date": "2026-01-29",
    "scheduled_time": "10:00",
    "is_recurring": false,
    "discount": 100,
    "items": [
        {
            "product_id": 101,
            "quantity": 2,
            "unit_price": 250.00
        },
        {
            "product_id": 102,
            "quantity": 1,
            "unit_price": 500.00
        }
    ]
}
```

**Recurring Order Fields (when is_recurring=true):**
```json
{
    "is_recurring": true,
    "frequency": "DAILY",
    "recurring_start": "2026-01-29",
    "recurring_end": "2026-02-28",
    "recurring_time": "08:00"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| customer_name | string | Yes | Customer's full name |
| customer_mobile | string | Yes | Customer's mobile number |
| delivery_address | string | Yes | Full delivery address |
| delivery_city | string | No | City name |
| delivery_area | string | No | Area/neighborhood |
| delivery_latitude | decimal | No | GPS latitude |
| delivery_longitude | decimal | No | GPS longitude |
| zone_id | int | No | Delivery zone ID |
| payment_method | string | No | COD, PREPAID, CREDIT (default: COD) |
| priority | int | No | 1=Normal, 2=High, 3=Express (default: 1) |
| customer_notes | string | No | Notes visible to delivery agent |
| internal_notes | string | No | Internal business notes |
| deliver_asap | bool | No | Deliver immediately (default: true) |
| scheduled_date | string | No | Scheduled date (YYYY-MM-DD) |
| scheduled_time | string | No | Scheduled time (HH:MM) |
| is_recurring | bool | No | Create recurring schedule (default: false) |
| frequency | string | No | DAILY, WEEKLY, MONTHLY (required if recurring) |
| recurring_start | string | No | Start date for recurring (YYYY-MM-DD) |
| recurring_end | string | No | End date for recurring (YYYY-MM-DD) |
| recurring_time | string | No | Time for recurring deliveries (HH:MM) |
| discount | decimal | No | Discount amount (default: 0) |
| items | array | Yes | List of order items |

**Response (201 Created):**
```json
{
    "success": true,
    "message": "Order HD-20260128-0001 created successfully",
    "instances_created": 30,
    "order": {
        "id": 123,
        "order_number": "HD-20260128-0001",
        ...
    }
}
```

---

#### Get Order Detail

```
GET /api/v1/delivery/business/orders/{id}/
```

Get detailed order information.

**Response:**
```json
{
    "success": true,
    "order": {
        "id": 123,
        "order_number": "HD-20260128-0001",
        "status": "PENDING",
        "status_display": "Pending",
        "priority": 1,
        "priority_display": "Normal",
        "business_info": {
            "id": 1,
            "name": "My Store",
            "address": "456 Business Ave",
            "city": "Lahore",
            "phone": "03001111111"
        },
        "customer_info": {
            "name": "Ahmed Khan",
            "mobile": "03001234567",
            "email": "ahmed@example.com"
        },
        "delivery_info": {
            "address": "123 Main Street",
            "city": "Lahore",
            "area": "Gulberg",
            "latitude": 31.5204,
            "longitude": 74.3587,
            "zone": "Zone A"
        },
        "items": [
            {
                "id": 1,
                "product_name": "Product A",
                "product_sku": "SKU-001",
                "quantity": 2,
                "unit_price": 250.00,
                "line_total": 500.00
            }
        ],
        "payment_breakdown": {
            "subtotal": 1000.00,
            "delivery_fee": 50.00,
            "discount": 0.00,
            "total": 1050.00,
            "payment_method": "COD",
            "payment_status": "PENDING",
            "is_cod": true,
            "amount_to_collect": 1050.00
        },
        "schedule_info": {
            "deliver_asap": false,
            "scheduled_date": "2026-01-29",
            "scheduled_time": "10:00",
            "is_recurring": false,
            "frequency": null
        },
        "timestamps": {
            "created_at": "2026-01-28T10:30:00Z",
            "updated_at": "2026-01-28T10:30:00Z",
            "prepared_at": null,
            "ready_at": null,
            "delivered_at": null
        },
        "customer_notes": "Ring doorbell twice",
        "internal_notes": "VIP customer",
        "available_agents": [...],
        "is_schedule_paused": false,
        "parent_order_id": null,
        "has_recurring_children": false
    }
}
```

---

#### Update Order Status

```
POST /api/v1/delivery/business/orders/{id}/status/
```

Update order status (follows valid transition rules).

**Valid Status Transitions:**
- PENDING → PREPARING, CANCELLED
- PREPARING → READY, CANCELLED
- READY → ASSIGNED, CANCELLED
- ASSIGNED → OUT_FOR_DELIVERY, CANCELLED
- OUT_FOR_DELIVERY → DELIVERED, FAILED

**Request Body:**
```json
{
    "status": "PREPARING",
    "reason": "Customer not available"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| status | string | Yes | New status |
| reason | string | No | Required for FAILED status |

**Response:**
```json
{
    "success": true,
    "new_status": "Preparing",
    "message": "Order status updated"
}
```

---

#### Assign Agent

```
POST /api/v1/delivery/business/orders/{id}/assign/
```

Assign a delivery agent to an order.

**Request Body:**
```json
{
    "agent_id": 5
}
```

**Response:**
```json
{
    "success": true,
    "agent_name": "John Rider",
    "new_status": "Assigned to Agent"
}
```

---

#### Bulk Status Update

```
POST /api/v1/delivery/business/orders/bulk-status/
```

Update status for multiple orders at once.

**Request Body:**
```json
{
    "order_ids": [123, 124, 125],
    "status": "PREPARING"
}
```

**Response:**
```json
{
    "success": true,
    "updated_count": 3,
    "message": "3 order(s) updated to PREPARING",
    "warnings": []
}
```

---

#### Bulk Assign Agent

```
POST /api/v1/delivery/business/orders/bulk-assign/
```

Assign agent to multiple orders at once.

**Request Body:**
```json
{
    "order_ids": [123, 124, 125],
    "agent_id": 5
}
```

**Response:**
```json
{
    "success": true,
    "assigned_count": 3,
    "agent_name": "John Rider",
    "message": "3 order(s) assigned to John Rider"
}
```

---

### Order Editing

#### Update Order Items

```
POST /api/v1/delivery/business/orders/{id}/items/
```

Update items in an order (add/remove/change quantities).

**Request Body:**
```json
{
    "items": [
        {
            "product_id": 101,
            "quantity": 3,
            "unit_price": 250.00,
            "product_name": "Product A",
            "product_sku": "SKU-001"
        },
        {
            "product_id": 103,
            "quantity": 1,
            "unit_price": 800.00,
            "product_name": "Product C",
            "product_sku": "SKU-003"
        }
    ]
}
```

**Response:**
```json
{
    "success": true,
    "message": "Items updated successfully",
    "subtotal": 1550.00,
    "total": 1600.00
}
```

---

#### Update Order Details

```
POST /api/v1/delivery/business/orders/{id}/details/
```

Update order details (delivery fee, discount, notes).

**Request Body:**
```json
{
    "delivery_fee": 75.00,
    "discount": 50.00,
    "customer_notes": "Updated instructions",
    "internal_notes": "Priority delivery",
    "payment_method": "COD"
}
```

| Field | Type | Description |
|-------|------|-------------|
| delivery_fee | decimal | Delivery fee amount |
| discount | decimal | Discount amount |
| customer_notes | string | Customer-visible notes |
| internal_notes | string | Internal business notes |
| payment_method | string | COD, PREPAID, or CREDIT |

**Response:**
```json
{
    "success": true,
    "message": "Order details updated",
    "total": 1575.00
}
```

---

#### Reschedule Order

```
POST /api/v1/delivery/business/orders/{id}/reschedule/
```

Reschedule order to a different date/time.

**Request Body:**
```json
{
    "scheduled_date": "2026-02-01",
    "scheduled_time": "15:00"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Order rescheduled to 2026-02-01"
}
```

---

### Schedule Management

These APIs are for managing recurring delivery schedules.

#### Skip Order

```
POST /api/v1/delivery/business/orders/{id}/skip/
```

Skip a scheduled delivery (cancels with reason).

**Request Body:**
```json
{
    "reason": "Customer traveling"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Delivery skipped"
}
```

---

#### Pause Schedule

```
POST /api/v1/delivery/business/orders/{id}/pause-schedule/
```

Pause a recurring schedule (no new orders generated).

**Response:**
```json
{
    "success": true,
    "message": "Schedule paused. No new orders will be generated."
}
```

---

#### Resume Schedule

```
POST /api/v1/delivery/business/orders/{id}/resume-schedule/
```

Resume a paused recurring schedule.

**Response:**
```json
{
    "success": true,
    "message": "Schedule resumed. New orders will be generated."
}
```

---

#### End Schedule

```
POST /api/v1/delivery/business/orders/{id}/end-schedule/
```

End a recurring schedule (sets end date to today).

**Request Body:**
```json
{
    "cancel_pending": true
}
```

| Field | Type | Description |
|-------|------|-------------|
| cancel_pending | bool | Also cancel all pending future orders |

**Response:**
```json
{
    "success": true,
    "message": "Schedule ended. 15 pending orders cancelled."
}
```

---

#### Apply Changes to Future Orders

```
POST /api/v1/delivery/business/orders/{id}/apply-to-future/
```

Apply item/detail changes from one order to all pending future orders in the schedule.

**Request Body:**
```json
{
    "update_items": true,
    "update_delivery_fee": true,
    "update_time": false,
    "force_update": false
}
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| update_items | bool | true | Update items in future orders |
| update_delivery_fee | bool | true | Update delivery fee and discount |
| update_time | bool | false | Update scheduled time |
| force_update | bool | false | Update even manually modified orders |

**Response:**
```json
{
    "success": true,
    "message": "Changes applied to 25 pending orders and parent template"
}
```

---

### Search & Helpers

#### Search Customers

```
GET /api/v1/delivery/business/customers/search/?q={query}
```

Search customers by name or mobile number. Returns delivery history and location data.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| q | string | Yes | Search query (min 2 chars) |

**Response:**
```json
{
    "customers": [
        {
            "id": 45,
            "name": "Ahmed Khan",
            "mobile": "03001234567",
            "email": "ahmed@example.com",
            "order_count": 15,
            "source": "delivery_history",
            "address": "123 Main Street",
            "city": "Lahore",
            "latitude": 31.5204,
            "longitude": 74.3587
        }
    ],
    "found": true,
    "customer": {...}
}
```

#### Create Quick Customer

```
POST /api/v1/delivery/business/customers/search/
```

Create a customer on-the-fly during order creation.

**Request Body:**
```json
{
    "name": "New Customer",
    "mobile": "03009876543"
}
```

**Response:**
```json
{
    "success": true,
    "customer": {
        "id": 123,
        "name": "New Customer",
        "mobile": "03009876543"
    }
}
```

---

#### Search Products

```
GET /api/v1/delivery/business/products/search/?q={query}
```

Search products by name, SKU, or barcode.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| q | string | Yes | Search query (min 2 chars) |

**Response:**
```json
{
    "products": [
        {
            "id": 101,
            "name": "Product A",
            "sku": "SKU-001",
            "price": 250.00,
            "stock": 50,
            "image": "/media/products/product-a.jpg"
        }
    ]
}
```

---

## Delivery Agent APIs

APIs for delivery agents to manage their orders and profile.

### Agent Authentication

#### Register

```
POST /api/v1/delivery/auth/register/
```

Register as a new delivery agent.

**Request Body:**
```json
{
    "mobile_number": "03001234567",
    "password": "SecurePass123",
    "password_confirm": "SecurePass123",
    "name": "John Rider",
    "email": "john@example.com",
    "vehicle_type": "BIKE",
    "vehicle_number": "ABC-123",
    "business_code": "store-slug"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| mobile_number | string | Yes | Agent's mobile number |
| password | string | Yes | Password (min 8 chars) |
| password_confirm | string | Yes | Password confirmation |
| name | string | Yes | Agent's full name |
| email | string | No | Email address |
| vehicle_type | string | No | BIKE, BICYCLE, CAR, VAN, TRUCK, WALK |
| vehicle_number | string | No | Vehicle registration number |
| business_code | string | No | Business ID or store slug to join |

**Response (201):**
```json
{
    "success": true,
    "message": "Registration successful. Your account is pending verification.",
    "tokens": {
        "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
        "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
    },
    "agent": {
        "id": 1,
        "agent_code": "DEL-0001",
        "name": "John Rider",
        "mobile_number": "03001234567",
        "is_verified": false
    }
}
```

---

#### Login

```
POST /api/v1/delivery/auth/login/
```

**Request Body:**
```json
{
    "mobile_number": "03001234567",
    "password": "SecurePass123"
}
```

**Response:**
```json
{
    "success": true,
    "tokens": {
        "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
        "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
    },
    "agent": {
        "id": 1,
        "agent_code": "DEL-0001",
        "name": "John Rider",
        "mobile_number": "03001234567",
        "status": "AVAILABLE",
        "is_verified": true,
        "total_deliveries": 150,
        "average_rating": 4.5,
        "earnings_balance": 2500.00
    }
}
```

---

#### Logout

```
POST /api/v1/delivery/auth/logout/
```

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response:**
```json
{
    "success": true,
    "message": "Logged out successfully"
}
```

---

#### Refresh Token

```
POST /api/v1/delivery/auth/refresh/
```

**Request Body:**
```json
{
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Response:**
```json
{
    "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

---

#### Forgot Password

```
POST /api/v1/delivery/auth/forgot-password/
```

**Request Body:**
```json
{
    "mobile_number": "03001234567"
}
```

**Response:**
```json
{
    "success": true,
    "message": "OTP sent to your mobile number"
}
```

---

#### Verify OTP

```
POST /api/v1/delivery/auth/verify-otp/
```

**Request Body:**
```json
{
    "mobile_number": "03001234567",
    "otp_code": "123456"
}
```

**Response:**
```json
{
    "success": true,
    "message": "OTP verified successfully"
}
```

---

#### Reset Password

```
POST /api/v1/delivery/auth/reset-password/
```

**Request Body:**
```json
{
    "mobile_number": "03001234567",
    "otp_code": "123456",
    "new_password": "NewPass123",
    "confirm_password": "NewPass123"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Password reset successfully"
}
```

---

#### Change Password

```
POST /api/v1/delivery/auth/change-password/
```

**Headers:**
```
Authorization: Bearer {access_token}
```

**Request Body:**
```json
{
    "current_password": "OldPass123",
    "new_password": "NewPass123",
    "confirm_password": "NewPass123"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Password changed successfully"
}
```

---

### Agent Profile & Status

#### Get Profile

```
GET /api/v1/delivery/agents/profile/
```

**Response:**
```json
{
    "id": 1,
    "agent_code": "DEL-0001",
    "name": "John Rider",
    "phone_number": "03001234567",
    "alternate_phone": "",
    "profile_photo": "/media/agents/photo.jpg",
    "vehicle_type": "BIKE",
    "vehicle_number": "ABC-123",
    "status": "AVAILABLE",
    "total_deliveries": 150,
    "successful_deliveries": 145,
    "average_rating": 4.5,
    "total_ratings": 120,
    "earnings_balance": 2500.00,
    "total_earnings": 45000.00,
    "is_verified": true
}
```

---

#### Update Status

```
POST /api/v1/delivery/agents/status/
```

**Request Body:**
```json
{
    "status": "AVAILABLE",
    "latitude": 31.5204,
    "longitude": 74.3587
}
```

| Status | Description |
|--------|-------------|
| AVAILABLE | Ready to accept orders |
| BUSY | Currently on delivery |
| OFFLINE | Not available |
| ON_BREAK | Taking a break |

**Response:**
```json
{
    "success": true,
    "status": "AVAILABLE",
    "message": "Status updated"
}
```

---

#### Update Location

```
POST /api/v1/delivery/agents/location/
```

Batch update location for GPS tracking.

**Request Body:**
```json
{
    "locations": [
        {
            "latitude": 31.5204,
            "longitude": 74.3587,
            "timestamp": "2026-01-28T10:30:00Z",
            "accuracy": 10.5,
            "speed": 25.0,
            "heading": 180.0,
            "battery_level": 75
        }
    ],
    "assignment_id": 123
}
```

**Response:**
```json
{
    "success": true,
    "message": "Location updated"
}
```

---

#### Get Earnings

```
GET /api/v1/delivery/agents/earnings/
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| start_date | string | Start date (YYYY-MM-DD) |
| end_date | string | End date (YYYY-MM-DD) |

**Response:**
```json
{
    "summary": {
        "total_earnings": 5000.00,
        "delivery_commission": 4500.00,
        "tips": 400.00,
        "bonuses": 100.00,
        "deductions": 0.00,
        "pending_payout": 2500.00,
        "paid_amount": 2500.00
    },
    "earnings": [
        {
            "id": 1,
            "earning_type": "DELIVERY",
            "amount": 50.00,
            "description": "Delivery commission",
            "assignment_number": "DEL-20260128-0001",
            "created_at": "2026-01-28T10:30:00Z",
            "is_paid": false
        }
    ]
}
```

---

### Agent Orders

#### Get Active Orders

```
GET /api/v1/delivery/orders/
```

Get orders assigned to the agent.

**Response:**
```json
{
    "orders": [
        {
            "id": 123,
            "assignment_number": "DEL-20260128-0001",
            "order_number": "HD-20260128-0001",
            "status": "ASSIGNED",
            "customer_name": "Ahmed Khan",
            "delivery_address": "123 Main Street",
            "total": 1550.00,
            "payment_method": "COD",
            "scheduled_time": "14:00"
        }
    ]
}
```

---

#### Accept Order

```
POST /api/v1/delivery/orders/{assignment_id}/accept/
```

**Request Body:**
```json
{
    "latitude": 31.5204,
    "longitude": 74.3587
}
```

**Response:**
```json
{
    "success": true,
    "message": "Order accepted"
}
```

---

#### Reject Order

```
POST /api/v1/delivery/orders/{assignment_id}/reject/
```

**Request Body:**
```json
{
    "reason": "Too far from my location",
    "latitude": 31.5204,
    "longitude": 74.3587
}
```

---

#### Pickup Order

```
POST /api/v1/delivery/orders/{assignment_id}/pickup/
```

Mark order as picked up from store.

**Request Body:**
```json
{
    "latitude": 31.5204,
    "longitude": 74.3587,
    "notes": "All items collected"
}
```

---

#### Mark In Transit

```
POST /api/v1/delivery/orders/{assignment_id}/in-transit/
```

---

#### Mark Arrived

```
POST /api/v1/delivery/orders/{assignment_id}/arrived/
```

---

#### Complete Delivery

```
POST /api/v1/delivery/orders/{assignment_id}/deliver/
```

**Request Body:**
```json
{
    "latitude": 31.5204,
    "longitude": 74.3587,
    "recipient_name": "Ahmed Khan",
    "delivery_notes": "Left at reception",
    "cod_collected": 1550.00
}
```

---

#### Fail Delivery

```
POST /api/v1/delivery/orders/{assignment_id}/fail/
```

**Request Body:**
```json
{
    "failure_reason": "CUSTOMER_UNAVAILABLE",
    "failure_notes": "No one answered door after 3 attempts",
    "latitude": 31.5204,
    "longitude": 74.3587
}
```

| Failure Reason | Description |
|----------------|-------------|
| CUSTOMER_UNAVAILABLE | Customer not available |
| WRONG_ADDRESS | Wrong or incomplete address |
| CUSTOMER_REFUSED | Customer refused delivery |
| DAMAGED_GOODS | Goods damaged |
| PAYMENT_ISSUE | Payment issue (COD) |
| WEATHER | Bad weather |
| VEHICLE_ISSUE | Vehicle breakdown |
| OTHER | Other reason |

---

### Mobile Dashboard

#### Get Dashboard

```
GET /api/v1/delivery/mobile/dashboard/
```

**Response:**
```json
{
    "agent": {
        "id": 1,
        "name": "John Rider",
        "code": "DEL-0001",
        "status": "AVAILABLE",
        "is_verified": true,
        "vehicle_type": "Motorcycle/Bike",
        "rating": 4.5,
        "total_ratings": 120
    },
    "stats": {
        "today_deliveries": 5,
        "today_earnings": 250.00,
        "pending_orders": 2,
        "completed_today": 5
    },
    "active_orders": [...],
    "upcoming_orders": [...]
}
```

---

#### Get Order History

```
GET /api/v1/delivery/mobile/history/
```

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| status | string | Filter by status (DELIVERED, FAILED, CANCELLED) |
| start_date | string | Start date (YYYY-MM-DD) |
| end_date | string | End date (YYYY-MM-DD) |

---

## Public APIs

APIs accessible without authentication.

### Tracking

#### Track Order

```
GET /api/v1/delivery/track/{order_number}/
```

Track delivery status by order number.

**Response:**
```json
{
    "order_number": "HD-20260128-0001",
    "delivery_status": "OUT_FOR_DELIVERY",
    "status_history": [
        {
            "status": "PENDING",
            "timestamp": "2026-01-28T10:00:00Z"
        },
        {
            "status": "PREPARING",
            "timestamp": "2026-01-28T10:30:00Z"
        },
        {
            "status": "OUT_FOR_DELIVERY",
            "timestamp": "2026-01-28T11:00:00Z"
        }
    ],
    "agent": {
        "name": "John R.",
        "phone_masked": "0300***4567",
        "vehicle_type": "BIKE"
    },
    "estimated_delivery": "2026-01-28T12:00:00Z",
    "delivery_address": {
        "address": "123 Main Street",
        "city": "Lahore"
    }
}
```

---

#### Live Tracking

```
GET /api/v1/delivery/track/{order_number}/live/
```

Get real-time agent location.

**Response:**
```json
{
    "agent_location": {
        "latitude": 31.5204,
        "longitude": 74.3587,
        "updated_at": "2026-01-28T11:30:00Z"
    },
    "delivery_location": {
        "latitude": 31.5300,
        "longitude": 74.3600
    },
    "estimated_arrival_minutes": 15,
    "distance_remaining_km": 2.5,
    "status": "IN_TRANSIT"
}
```

---

### Zone & Fee

#### Check Zone Coverage

```
POST /api/v1/delivery/zones/check/
```

Check if location is within delivery coverage.

**Request Body:**
```json
{
    "business_id": 1,
    "latitude": 31.5204,
    "longitude": 74.3587
}
```

**Response:**
```json
{
    "is_serviceable": true,
    "zone": {
        "id": 1,
        "name": "Zone A",
        "base_delivery_fee": 50.00,
        "estimated_delivery_minutes": 30
    },
    "delivery_options": [
        {
            "type": "standard",
            "fee": 50.00,
            "estimated_minutes": 30
        },
        {
            "type": "express",
            "fee": 100.00,
            "estimated_minutes": 15
        }
    ]
}
```

---

#### Calculate Delivery Fee

```
POST /api/v1/delivery/fee/calculate/
```

Calculate delivery fee based on location and order total.

**Request Body:**
```json
{
    "business_id": 1,
    "latitude": 31.5204,
    "longitude": 74.3587,
    "order_total": 1500.00,
    "is_express": false
}
```

**Response:**
```json
{
    "base_fee": 50.00,
    "distance_fee": 20.00,
    "express_fee": 0.00,
    "total_fee": 70.00,
    "distance_km": 4.5,
    "is_free_delivery": false,
    "free_delivery_threshold": 5000.00,
    "amount_for_free_delivery": 3500.00
}
```

---

## Error Responses

All APIs return consistent error responses:

```json
{
    "success": false,
    "error": "Error message description"
}
```

**Common HTTP Status Codes:**
| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request (validation error) |
| 401 | Unauthorized (missing/invalid token) |
| 403 | Forbidden (no permission) |
| 404 | Not Found |
| 500 | Internal Server Error |

---

## Flutter/Dart Code Examples

### API Service Setup

```dart
import 'package:dio/dio.dart';

class DeliveryApiService {
  final Dio _dio;
  final String baseUrl = 'https://your-domain.com/api/v1/delivery';

  DeliveryApiService(String accessToken) : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
  }

  // Get delivery stats
  Future<Map<String, dynamic>> getStats({String? date}) async {
    final response = await _dio.get('/business/stats/',
      queryParameters: date != null ? {'date': date} : null);
    return response.data;
  }

  // List orders
  Future<Map<String, dynamic>> listOrders({
    String? status,
    String? date,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get('/business/orders/', queryParameters: {
      if (status != null) 'status': status,
      if (date != null) 'date': date,
      if (search != null) 'search': search,
      'page': page,
      'page_size': pageSize,
    });
    return response.data;
  }

  // Create order
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final response = await _dio.post('/business/orders/create/', data: orderData);
    return response.data;
  }

  // Update order status
  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status, {String? reason}) async {
    final response = await _dio.post('/business/orders/$orderId/status/', data: {
      'status': status,
      if (reason != null) 'reason': reason,
    });
    return response.data;
  }

  // Assign agent
  Future<Map<String, dynamic>> assignAgent(int orderId, int agentId) async {
    final response = await _dio.post('/business/orders/$orderId/assign/', data: {
      'agent_id': agentId,
    });
    return response.data;
  }

  // Search customers
  Future<Map<String, dynamic>> searchCustomers(String query) async {
    final response = await _dio.get('/business/customers/search/',
      queryParameters: {'q': query});
    return response.data;
  }

  // Search products
  Future<Map<String, dynamic>> searchProducts(String query) async {
    final response = await _dio.get('/business/products/search/',
      queryParameters: {'q': query});
    return response.data;
  }
}
```

### Usage Example

```dart
void main() async {
  final apiService = DeliveryApiService('your-access-token');

  // Get today's stats
  final stats = await apiService.getStats();
  print('Today\'s deliveries: ${stats['stats']['today_total']}');

  // List pending orders
  final orders = await apiService.listOrders(status: 'PENDING');
  print('Pending orders: ${orders['total']}');

  // Create new order
  final newOrder = await apiService.createOrder({
    'customer_name': 'John Doe',
    'customer_mobile': '03001234567',
    'delivery_address': '123 Main St',
    'items': [
      {'product_id': 1, 'quantity': 2, 'unit_price': 500}
    ]
  });
  print('Created order: ${newOrder['order']['order_number']}');
}
```

---

## Order Status Flow

```
PENDING → PREPARING → READY → ASSIGNED → OUT_FOR_DELIVERY → DELIVERED
   ↓          ↓         ↓         ↓              ↓
CANCELLED  CANCELLED  CANCELLED  CANCELLED     FAILED
```

**Status Descriptions:**
| Status | Description | Who Can Update |
|--------|-------------|----------------|
| PENDING | Order created, waiting to be prepared | Business |
| PREPARING | Order being prepared in kitchen/warehouse | Business |
| READY | Order ready for pickup by agent | Business |
| ASSIGNED | Agent assigned to order | Business |
| OUT_FOR_DELIVERY | Agent picked up, on the way | Agent |
| DELIVERED | Successfully delivered | Agent/Business |
| CANCELLED | Order cancelled | Business |
| FAILED | Delivery attempted but failed | Agent |

---

## Webhooks (Coming Soon)

Webhooks will be available to notify your systems of order status changes:

- `order.created` - New order created
- `order.status_changed` - Order status updated
- `order.assigned` - Agent assigned to order
- `order.delivered` - Order delivered
- `order.failed` - Delivery failed
- `order.cancelled` - Order cancelled

---

*Last Updated: January 2026*
*API Version: 1.0*
