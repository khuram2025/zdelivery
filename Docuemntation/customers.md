# Customer Management APIs

This document provides comprehensive details about the Customer Management API endpoints available in the Zayyrah POS system, including GPS/Location features for mobile app integration.

## Base URL
```
http://your-domain.com/api/v1/customers/
```

## Authentication
All Customer API endpoints require JWT authentication. Include the access token in the Authorization header:
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

## Customer Model Fields

### Basic Information
- `id` (integer, read-only): Unique customer identifier
- `name` (string, optional): Customer's full name
- `mobile_number` (string, optional): Customer's mobile number (6-15 digits)
- `email` (string, optional): Customer's email address
- `notes` (text, optional): Additional notes about the customer

### Location Information (NEW - GPS Features)
- `city` (string, optional): Customer's city (e.g., "Lahore", "Karachi")
- `street_address` (text, optional): Full street address, area, landmark
- `latitude` (decimal, optional): GPS latitude coordinate (-90 to 90)
- `longitude` (decimal, optional): GPS longitude coordinate (-180 to 180)
- `has_location` (boolean, read-only): True if customer has GPS coordinates

### Financial Information
- `opening_balance` (decimal, default: 0.00): Initial balance for the customer
- `credit_limit` (decimal, default: 0.00): Maximum credit allowed for the customer

### Clearance Schedule Configuration
- `clearance_type` (string, choices): Type of clearance schedule
  - `"fixed_date"`: Fixed Date of Month (default)
  - `"weekly"`: Day of Week
  - `"custom"`: Custom Date
- `clearance_day_of_month` (integer, optional): Day of month (1-31) for fixed date clearance
- `clearance_day_of_week` (integer, optional): Day of week for weekly clearance (1-7, where 1=Monday)
- `clearance_custom_date` (date, optional): Custom clearance date (YYYY-MM-DD format)

### System Fields
- `created_at` (datetime, read-only): Customer creation timestamp
- `updated_at` (datetime, read-only): Last update timestamp
- `total_sales` (integer, read-only): Total number of sales transactions
- `total_amount` (string, read-only): Total sales amount

### Display Fields (Read-only)
- `clearance_type_display` (string): Human-readable clearance type
- `clearance_day_of_week_display` (string): Human-readable day of week

---

## Core Customer API Endpoints

### 1. List Customers
**GET** `/api/v1/customers/`

Retrieve a paginated list of customers with search, filtering, and sales analytics.

#### Query Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `search` | string | - | Search by customer name or mobile number |
| `ordering` | string | - | Order results by field (e.g., `name`, `-created_at`) |
| `sort_by` | string | `period_sales_desc` | Sort option: `period_sales_desc`, `period_sales_asc`, `lifetime_sales_desc`, etc. |
| `page` | integer | 1 | Page number for pagination |
| `page_size` | integer | 20 | Number of results per page (max 100) |
| `time_filter` | string | `today` | Filter by time period: `today`, `yesterday`, `last_7_days`, `this_week`, `last_week`, `this_month`, `last_month`, `this_year`, `all_time`, `custom` |
| `start_date` | date | - | Start date for custom filter (YYYY-MM-DD) |
| `end_date` | date | - | End date for custom filter (YYYY-MM-DD) |

#### Request Example
```bash
curl -X GET "http://localhost:8003/api/v1/customers/?time_filter=this_month&page=1&page_size=20" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Response Format
```json
{
  "success": true,
  "data": {
    "customers": [
      {
        "id": 25,
        "name": "Ahmed Ali",
        "mobile_number": "03001234567",
        "email": "ahmed@example.com",
        "created_at": "2025-09-22T17:04:57.703577+00:00",
        "updated_at": "2026-01-28T07:18:50.514057+00:00",
        "period_sales": {
          "total_amount": 15000.0,
          "total_transactions": 5,
          "pos_transactions": {
            "count": 3,
            "amount": 10000.0
          },
          "manual_sales": {
            "count": 2,
            "amount": 5000.0
          }
        },
        "lifetime_sales": {
          "total_amount": 50000.0,
          "total_transactions": 25
        },
        "credit_info": {
          "credit_limit": 5000.0,
          "current_balance": 2500.0,
          "available_credit": 2500.0
        }
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_customers": 100,
      "page_size": 20,
      "has_next": true,
      "has_previous": false
    },
    "period_summary": {
      "time_filter": "this_month",
      "date_range": {
        "start_date": "2026-01-01",
        "end_date": "2026-01-28"
      },
      "total_customers": 100,
      "customers_with_sales": 45,
      "customers_without_sales": 55,
      "total_sales_amount": 500000.0,
      "total_transactions": 250,
      "avg_sale_per_customer": 5000.0,
      "avg_transactions_per_customer": 2.5
    },
    "filters_applied": {
      "time_filter": "this_month",
      "sort_by": "period_sales_desc",
      "start_date": "2026-01-01",
      "end_date": "2026-01-28"
    }
  }
}
```

#### Customer Object Fields in List Response
| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique customer identifier |
| `name` | string | Customer's full name |
| `mobile_number` | string | Customer's mobile number |
| `email` | string | Customer's email address |
| `created_at` | datetime | Customer creation timestamp |
| `updated_at` | datetime | Last update timestamp |
| `period_sales` | object | Sales data for the filtered time period |
| `period_sales.total_amount` | decimal | Total sales amount for the period |
| `period_sales.total_transactions` | integer | Total transaction count for the period |
| `period_sales.pos_transactions` | object | POS transaction breakdown (count, amount) |
| `period_sales.manual_sales` | object | Manual sales breakdown (count, amount) |
| `lifetime_sales` | object | All-time sales data |
| `lifetime_sales.total_amount` | decimal | Total sales amount all time |
| `lifetime_sales.total_transactions` | integer | Total transaction count all time |
| `credit_info` | object | Customer credit information |
| `credit_info.credit_limit` | decimal | Maximum credit allowed |
| `credit_info.current_balance` | decimal | Current outstanding balance |
| `credit_info.available_credit` | decimal | Remaining available credit |

---

### 2. Create Customer (with Location)
**POST** `/api/v1/customers/`

Create a new customer with location/GPS information.

#### Request Body (Full Example with Location)
```json
{
  "name": "Ahmed Ali",
  "mobile_number": "03001234567",
  "email": "ahmed@example.com",
  "notes": "VIP customer with credit facility",
  "opening_balance": "1500.00",
  "credit_limit": "5000.00",
  "clearance_type": "weekly",
  "clearance_day_of_week": 1,
  "city": "Lahore",
  "street_address": "123 Main Street, Model Town",
  "latitude": 31.5204,
  "longitude": 74.3587
}
```

#### Validation Rules
- At least one of `name` or `mobile_number` must be provided
- `mobile_number` must be 6-15 digits if provided
- `email` must be valid email format if provided
- `latitude` must be between -90 and 90
- `longitude` must be between -180 and 180
- Financial fields accept decimal values with up to 10 digits and 2 decimal places

#### Request Example (cURL)
```bash
curl -X POST "http://localhost:8003/api/v1/customers/" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "name": "Ahmed Ali",
    "mobile_number": "03001234567",
    "city": "Lahore",
    "street_address": "123 Main Street, Model Town",
    "latitude": 31.5204,
    "longitude": 74.3587,
    "credit_limit": "5000.00"
  }'
```

#### Success Response
```json
{
  "success": true,
  "message": "Customer created successfully",
  "data": {
    "id": 6,
    "name": "Ahmed Ali",
    "mobile_number": "03001234567",
    "email": null,
    "notes": "",
    "opening_balance": "0.00",
    "credit_limit": "5000.00",
    "clearance_type": "fixed_date",
    "clearance_type_display": "Fixed Date of Month",
    "clearance_day_of_month": null,
    "clearance_day_of_week": null,
    "clearance_day_of_week_display": null,
    "clearance_custom_date": null,
    "city": "Lahore",
    "street_address": "123 Main Street, Model Town",
    "latitude": "31.5204000",
    "longitude": "74.3587000",
    "has_location": true,
    "created_at": "2025-09-18T18:26:37.363777Z",
    "updated_at": "2025-09-18T18:26:37.363805Z",
    "total_sales": 0,
    "total_amount": "0.00",
    "recent_sales": []
  }
}
```

#### Error Response
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "latitude": ["Latitude must be between -90 and 90"],
    "mobile_number": ["Enter 6 to 15 digits."]
  }
}
```

---

### 3. Get Customer Details (with Location)
**GET** `/api/v1/customers/{customer_id}/`

Retrieve detailed information about a specific customer, including location data, financial info, clearance settings, and recent sales.

#### Request Example
```bash
curl -X GET "http://localhost:8003/api/v1/customers/25/" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Response Format
```json
{
  "id": 25,
  "name": "Ahmed Ali",
  "mobile_number": "03001234567",
  "email": "ahmed@example.com",
  "notes": "VIP customer with credit facility",
  "opening_balance": "1500.00",
  "credit_limit": "5000.00",
  "clearance_type": "weekly",
  "clearance_type_display": "Day of Week",
  "clearance_day_of_month": null,
  "clearance_day_of_week": 1,
  "clearance_day_of_week_display": "Monday",
  "clearance_custom_date": null,
  "city": "Lahore",
  "street_address": "123 Main Street, Model Town",
  "latitude": "31.5204000",
  "longitude": "74.3587000",
  "has_location": true,
  "created_at": "2025-09-22T17:04:57.703577Z",
  "updated_at": "2026-01-28T07:18:50.514057Z",
  "total_sales": 15,
  "total_amount": "25000.00",
  "recent_sales": [
    {
      "id": 101,
      "sale_number": "INV-2026-0001",
      "total": "5000.00",
      "created_at": "2026-01-28T10:30:00Z",
      "status": "completed"
    },
    {
      "id": 98,
      "sale_number": "INV-2026-0002",
      "total": "3500.00",
      "created_at": "2026-01-27T14:15:00Z",
      "status": "completed"
    }
  ]
}
```

#### Customer Detail Response Fields
| Field | Type | Description |
|-------|------|-------------|
| **Basic Information** | | |
| `id` | integer | Unique customer identifier |
| `name` | string | Customer's full name |
| `mobile_number` | string | Customer's mobile number |
| `email` | string | Customer's email address |
| `notes` | text | Additional notes about the customer |
| **Financial Information** | | |
| `opening_balance` | decimal | Initial balance for the customer |
| `credit_limit` | decimal | Maximum credit allowed |
| **Clearance Schedule** | | |
| `clearance_type` | string | Type: `fixed_date`, `weekly`, `custom` |
| `clearance_type_display` | string | Human-readable clearance type |
| `clearance_day_of_month` | integer | Day of month (1-31) for fixed date |
| `clearance_day_of_week` | integer | Day of week (1=Monday, 7=Sunday) |
| `clearance_day_of_week_display` | string | Human-readable day name |
| `clearance_custom_date` | date | Custom clearance date (YYYY-MM-DD) |
| **Location/GPS** | | |
| `city` | string | Customer's city |
| `street_address` | text | Full street address |
| `latitude` | decimal | GPS latitude (-90 to 90) |
| `longitude` | decimal | GPS longitude (-180 to 180) |
| `has_location` | boolean | True if GPS coordinates exist |
| **Sales Summary** | | |
| `total_sales` | integer | Total number of sales transactions |
| `total_amount` | decimal | Total sales amount (all time) |
| `recent_sales` | array | Last 5 sales transactions |
| **Timestamps** | | |
| `created_at` | datetime | Customer creation timestamp |
| `updated_at` | datetime | Last update timestamp |

#### Recent Sales Object Fields
| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Sale transaction ID |
| `sale_number` | string | Invoice/sale number |
| `total` | decimal | Total sale amount |
| `created_at` | datetime | Sale timestamp |
| `status` | string | Sale status (pending, completed, etc.)
```

---

### 4. Update Customer (with Location)
**PATCH** `/api/v1/customers/{customer_id}/`

Update specific fields of an existing customer including location. Also supports **PUT** for full updates.

#### Request Body (Partial Update - Location Only)
```json
{
  "city": "Karachi",
  "street_address": "456 Business Avenue, Clifton",
  "latitude": 24.8607,
  "longitude": 67.0011
}
```

#### Request Example
```bash
curl -X PATCH "http://localhost:8003/api/v1/customers/6/" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "city": "Karachi",
    "street_address": "456 Business Avenue, Clifton",
    "latitude": 24.8607,
    "longitude": 67.0011
  }'
```

#### Success Response
```json
{
  "success": true,
  "message": "Customer updated successfully",
  "data": {
    "id": 6,
    "name": "Ahmed Ali",
    "mobile_number": "03001234567",
    "city": "Karachi",
    "street_address": "456 Business Avenue, Clifton",
    "latitude": "24.8607000",
    "longitude": "67.0011000",
    "has_location": true,
    "...": "other fields"
  }
}
```

---

### 5. Delete Customer
**DELETE** `/api/v1/customers/{customer_id}/`

Permanently delete a customer and all associated data.

#### Success Response
```json
{
  "success": true,
  "message": "Customer deleted successfully"
}
```

---

## Location/GPS API Endpoints

These endpoints support the GPS features shown on the web customer form.

### 6. Update Customer Location (GPS Only)
**PATCH** `/api/v1/customers/{customer_id}/location/`

Dedicated endpoint for updating only the GPS location of a customer. Used by:
- Delivery agents to mark customer location when at delivery address
- Mobile app for quick location updates

#### Request Body
```json
{
  "latitude": 31.5204,
  "longitude": 74.3587,
  "city": "Lahore",
  "street_address": "123 Main Street, Model Town",
  "source": "delivery_agent"
}
```

#### Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `latitude` | decimal | Yes | GPS latitude (-90 to 90) |
| `longitude` | decimal | Yes | GPS longitude (-180 to 180) |
| `city` | string | No | City name |
| `street_address` | string | No | Full street address |
| `source` | string | No | Source of update: `delivery_agent`, `business_owner`, `customer`, `api` |

#### Request Example
```bash
curl -X PATCH "http://localhost:8003/api/v1/customers/6/location/" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "latitude": 31.5204,
    "longitude": 74.3587,
    "source": "delivery_agent"
  }'
```

#### Success Response
```json
{
  "success": true,
  "message": "Customer location updated successfully",
  "data": {
    "id": 6,
    "name": "Ahmed Ali",
    "mobile_number": "03001234567",
    "latitude": "31.5204000",
    "longitude": "74.3587000",
    "city": "Lahore",
    "street_address": "123 Main Street, Model Town",
    "has_location": true
  }
}
```

---

### 7. Parse Google Maps URL
**POST** `/api/v1/customers/location/resolve-url/`

Extract GPS coordinates from a Google Maps URL (short or long format). Useful when user shares a location via Google Maps link.

#### Supported URL Formats
- Short URLs: `https://maps.app.goo.gl/UQ5jSxXyvFyfVcJC9`
- Standard URLs: `https://goo.gl/maps/abc123`
- Full URLs: `https://www.google.com/maps/@31.5204,74.3587,15z`
- Place URLs: `https://www.google.com/maps/place/.../@31.5204,74.3587,17z`

#### Request Body
```json
{
  "url": "https://maps.app.goo.gl/UQ5jSxXyvFyfVcJC9"
}
```

#### Request Example
```bash
curl -X POST "http://localhost:8003/api/v1/customers/location/resolve-url/" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "url": "https://maps.app.goo.gl/UQ5jSxXyvFyfVcJC9"
  }'
```

#### Success Response
```json
{
  "success": true,
  "data": {
    "latitude": 31.3096992,
    "longitude": 72.5205025,
    "original_url": "https://maps.app.goo.gl/UQ5jSxXyvFyfVcJC9",
    "resolved_url": "https://www.google.com/maps/place/..."
  }
}
```

#### Error Response
```json
{
  "success": false,
  "error": "Could not extract coordinates from URL"
}
```

---

### 8. Reverse Geocode (Get Address from Coordinates)
**POST** `/api/v1/customers/location/reverse-geocode/`

Convert GPS coordinates to a street address using Google Maps Geocoding API.

**Note:** Requires Google Maps API key to be configured in Business Settings.

#### Request Body
```json
{
  "latitude": 31.5204,
  "longitude": 74.3587
}
```

#### Request Example
```bash
curl -X POST "http://localhost:8003/api/v1/customers/location/reverse-geocode/" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "latitude": 31.5204,
    "longitude": 74.3587
  }'
```

#### Success Response
```json
{
  "success": true,
  "data": {
    "formatted_address": "123 Main Street, Model Town, Lahore, Punjab 54700, Pakistan",
    "city": "Lahore",
    "street_address": "123 Main Street, Model Town",
    "state": "Punjab",
    "country": "Pakistan",
    "postal_code": "54700"
  }
}
```

#### Error Response (No API Key)
```json
{
  "success": false,
  "error": "Google Maps API key not configured. Please configure it in Business Settings."
}
```

---

### 9. Get Business Location Defaults
**GET** `/api/v1/customers/location/business-defaults/`

Get the default map center location and settings for initializing maps. Returns the business's default location.

#### Request Example
```bash
curl -X GET "http://localhost:8003/api/v1/customers/location/business-defaults/" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### Success Response
```json
{
  "success": true,
  "data": {
    "latitude": 31.5204,
    "longitude": 74.3587,
    "zoom": 14,
    "city": "Lahore",
    "google_maps_enabled": true,
    "has_api_key": true
  }
}
```

---

## Mobile App Integration Guide

### Complete Customer Creation Flow with Location

```dart
// Flutter/Dart example
class CustomerService {
  final String baseUrl = 'http://your-domain.com/api/v1';
  final String token;

  CustomerService(this.token);

  // Step 1: Parse Google Maps URL if user shared a link
  Future<Map<String, dynamic>> parseGoogleMapsUrl(String url) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers/location/resolve-url/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'url': url}),
    );
    return jsonDecode(response.body);
  }

  // Step 2: Get address from coordinates (optional)
  Future<Map<String, dynamic>> reverseGeocode(double lat, double lng) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers/location/reverse-geocode/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'latitude': lat,
        'longitude': lng,
      }),
    );
    return jsonDecode(response.body);
  }

  // Step 3: Create customer with location
  Future<Map<String, dynamic>> createCustomer({
    required String name,
    String? mobileNumber,
    String? email,
    double? latitude,
    double? longitude,
    String? city,
    String? streetAddress,
    double? creditLimit,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        if (mobileNumber != null) 'mobile_number': mobileNumber,
        if (email != null) 'email': email,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (city != null) 'city': city,
        if (streetAddress != null) 'street_address': streetAddress,
        if (creditLimit != null) 'credit_limit': creditLimit.toString(),
      }),
    );
    return jsonDecode(response.body);
  }

  // Update customer location
  Future<Map<String, dynamic>> updateCustomerLocation(
    int customerId,
    double latitude,
    double longitude, {
    String? city,
    String? streetAddress,
    String source = 'mobile_app',
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/customers/$customerId/location/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        if (city != null) 'city': city,
        if (streetAddress != null) 'street_address': streetAddress,
        'source': source,
      }),
    );
    return jsonDecode(response.body);
  }

  // Get business default location for map initialization
  Future<Map<String, dynamic>> getBusinessDefaults() async {
    final response = await http.get(
      Uri.parse('$baseUrl/customers/location/business-defaults/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return jsonDecode(response.body);
  }
}
```

### JavaScript/React Native Example

```javascript
class CustomerAPI {
  constructor(baseUrl, accessToken) {
    this.baseUrl = baseUrl;
    this.headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`
    };
  }

  // Parse Google Maps URL
  async parseGoogleMapsUrl(url) {
    const response = await fetch(`${this.baseUrl}/customers/location/resolve-url/`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({ url })
    });
    return response.json();
  }

  // Reverse geocode coordinates to address
  async reverseGeocode(latitude, longitude) {
    const response = await fetch(`${this.baseUrl}/customers/location/reverse-geocode/`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({ latitude, longitude })
    });
    return response.json();
  }

  // Create customer with location
  async createCustomer(customerData) {
    const response = await fetch(`${this.baseUrl}/customers/`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify(customerData)
    });
    return response.json();
  }

  // Update customer
  async updateCustomer(customerId, customerData) {
    const response = await fetch(`${this.baseUrl}/customers/${customerId}/`, {
      method: 'PATCH',
      headers: this.headers,
      body: JSON.stringify(customerData)
    });
    return response.json();
  }

  // Update customer location only
  async updateCustomerLocation(customerId, locationData) {
    const response = await fetch(`${this.baseUrl}/customers/${customerId}/location/`, {
      method: 'PATCH',
      headers: this.headers,
      body: JSON.stringify(locationData)
    });
    return response.json();
  }

  // Get business default map location
  async getBusinessDefaults() {
    const response = await fetch(`${this.baseUrl}/customers/location/business-defaults/`, {
      headers: this.headers
    });
    return response.json();
  }
}

// Usage example
const api = new CustomerAPI('http://your-domain.com/api/v1', 'YOUR_TOKEN');

// Create customer with GPS location from device
const newCustomer = await api.createCustomer({
  name: 'Ahmed Ali',
  mobile_number: '03001234567',
  latitude: 31.5204,
  longitude: 74.3587,
  city: 'Lahore',
  street_address: '123 Main Street'
});

// Parse Google Maps shared link
const coords = await api.parseGoogleMapsUrl('https://maps.app.goo.gl/abc123');
if (coords.success) {
  console.log(`Latitude: ${coords.data.latitude}, Longitude: ${coords.data.longitude}`);
}
```

---

## Customer List Filtering Examples

### Get customers with sales this month
```bash
curl -X GET "http://localhost:8003/api/v1/customers/?time_filter=this_month&sort_by=period_sales_desc" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Search customers by name or phone
```bash
curl -X GET "http://localhost:8003/api/v1/customers/?search=Ahmed" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Get customers with custom date range
```bash
curl -X GET "http://localhost:8003/api/v1/customers/?time_filter=custom&start_date=2026-01-01&end_date=2026-01-31" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Get all-time customer list sorted by lifetime sales
```bash
curl -X GET "http://localhost:8003/api/v1/customers/?time_filter=all_time&sort_by=lifetime_sales_desc" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Paginate through customers
```bash
# First page
curl -X GET "http://localhost:8003/api/v1/customers/?page=1&page_size=20" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# Second page
curl -X GET "http://localhost:8003/api/v1/customers/?page=2&page_size=20" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/customers/` | List customers with filtering and analytics |
| POST | `/api/v1/customers/` | Create customer (with location) |
| GET | `/api/v1/customers/{id}/` | Get customer details with location and sales |
| PATCH | `/api/v1/customers/{id}/` | Update customer (with location) |
| PUT | `/api/v1/customers/{id}/` | Full update customer |
| DELETE | `/api/v1/customers/{id}/` | Delete customer |
| PATCH | `/api/v1/customers/{id}/location/` | Update location only |
| POST | `/api/v1/customers/location/resolve-url/` | Parse Google Maps URL |
| POST | `/api/v1/customers/location/reverse-geocode/` | Get address from coordinates |
| GET | `/api/v1/customers/location/business-defaults/` | Get default map settings |

---

## Error Handling

All API endpoints follow a consistent error response format:

```json
{
  "success": false,
  "message": "Error description",
  "errors": {
    "field_name": ["Specific error message"]
  }
}
```

### Common HTTP Status Codes
- `200 OK`: Request successful
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request data
- `401 Unauthorized`: Authentication credentials missing or invalid
- `403 Forbidden`: User doesn't have permission to access the resource
- `404 Not Found`: Requested resource not found
- `500 Internal Server Error`: Server error

---

## Security Notes

1. **User Isolation**: Customers are isolated by user account
2. **JWT Authentication**: All endpoints require valid JWT token
3. **Location Privacy**: GPS coordinates are only visible to the business owner
4. **Input Validation**: All coordinates are validated for valid ranges
5. **Delivery Agent Access**: Delivery agents can update customer locations for orders assigned to them

---

## Version History

| Date | Changes |
|------|---------|
| 2026-01-28 | Added comprehensive Customer List API documentation with full response format, filtering examples, period_sales breakdown |
| 2026-01-28 | Added comprehensive Customer Detail API documentation with all fields documented |
| 2026-01-28 | Added Customer List Filtering Examples section for mobile developers |
| 2026-01-27 | Added GPS/Location APIs (resolve-url, reverse-geocode, business-defaults) |
| 2026-01-27 | Added location fields to create/update customer APIs |

---

*Last Updated: 2026-01-28*
*API Version: v1*
