# 📱 API Integration Guide - Leave Management System

This guide explains how to use the updated API integration for the Leave Management System with the new endpoints and models.

## 🔄 What's New

### Updated API Endpoints
- **Base URL**: `http://10.0.2.2:5119/api`
- **New Leave Request Endpoints**: Updated to match the API documentation
- **User Registration**: New format with department and role integration
- **Enhanced Models**: Complete model classes for all API responses

### Key Changes
1. **Leave Request API**: Updated to use `/api/leaverequests` endpoints
2. **User Registration**: New format with `departmentId`, `positionTypeId`, and `roleIds`
3. **Department Integration**: Dynamic loading of departments, roles, and position types
4. **Enhanced UI**: Updated add user screen with proper form validation

## 📦 New Models

### Leave Request Models (`lib/models/leave_request_dto.dart`)
```dart
// Create leave request
class LeaveRequestDto {
  final int leaveTypeId;
  final String startDate;
  final String endDate;
  final String startSession;
  final String endSession;
  final double totalDays;
  final String reason;
}

// Response models
class LeaveRequestResponse { ... }
class LeaveRequestSummary { ... }
class LeaveRequestDetail { ... }
class PagedResult<T> { ... }
class LeaveStatistics { ... }
```

### User Registration Models (`lib/models/user_registration.dart`)
```dart
class UserRegistrationRequest {
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;
  final String dateOfBirth;
  final String joinDate;
  final int departmentId;
  final int positionTypeId;
  final List<int> roleIds;
}

class Department { ... }
class PositionType { ... }
class Role { ... }
```

## 🚀 Usage Examples

### 1. Create Leave Request

```dart
import '../services/leave_request_service.dart';
import '../models/leave_request_dto.dart';

// Create a leave request
final dto = LeaveRequestDto(
  leaveTypeId: 1,
  startDate: '2025-01-15',
  endDate: '2025-01-17',
  startSession: 'FULL',
  endSession: 'FULL',
  totalDays: 3.0,
  reason: 'Nghỉ phép cá nhân',
);

final result = await LeaveRequestService.createLeaveRequest(dto);
print('Request created: ${result.requestCode}');
```

### 2. Get My Leave Requests

```dart
// Get paginated list of my requests
final result = await LeaveRequestService.getMyLeaveRequests(
  status: 'PENDING',
  pageNumber: 1,
  pageSize: 20,
);

for (final request in result.items) {
  print('${request.leaveTypeName}: ${request.status}');
}
```

### 3. Get Leave Request Detail

```dart
final detail = await LeaveRequestService.getLeaveRequestDetail(1);
print('Employee: ${detail.employeeName}');
print('Reason: ${detail.reason}');
print('Approvals: ${detail.approvals.length}');
```

### 4. Cancel Leave Request

```dart
await LeaveRequestService.cancelLeaveRequest(1);
```

### 5. Manager/Admin Operations

```dart
// Get pending approvals
final pending = await LeaveRequestService.getPendingApprovals(
  pageNumber: 1,
  pageSize: 20,
);

// Approve request
final approved = await LeaveRequestService.approveLeaveRequest(
  1, 
  'Đồng ý cho nghỉ'
);

// Reject request
final rejected = await LeaveRequestService.rejectLeaveRequest(
  1, 
  'Lý do không rõ ràng'
);
```

### 6. Get Statistics

```dart
final stats = await LeaveRequestService.getMyStatistics(year: 2025);
print('Total requests: ${stats.summary.totalRequests}');
print('Approved: ${stats.summary.approvedCount}');
```

### 7. Get Leave Types

```dart
final leaveTypes = await LeaveRequestService.getLeaveTypes();
for (final type in leaveTypes) {
  print('${type.leaveTypeName} (${type.leaveTypeCode})');
}
```

## 👥 User Registration

### Updated Add User Screen

The `AddUserScreen` now includes:
- **Dynamic Department Loading**: Fetches departments from API
- **Position Type Selection**: Dropdown for position types
- **Multi-Role Selection**: Checkbox list for multiple roles
- **Date Pickers**: For date of birth and join date
- **Form Validation**: Comprehensive validation for all fields

### Usage Example

```dart
// The screen automatically loads departments, roles, and position types
// User fills out the form with:
// - Basic info (email, password, full name, phone)
// - Personal info (date of birth, join date)
// - Work info (department, position, roles)

// When submitted, it creates a UserRegistrationRequest:
final userData = UserRegistrationRequest(
  email: 'user@example.com',
  password: 'password123',
  fullName: 'Nguyễn Văn A',
  phoneNumber: '0123456789',
  dateOfBirth: '1990-01-01',
  joinDate: '2025-01-01',
  departmentId: 1,
  positionTypeId: 1,
  roleIds: [1, 2], // Multiple roles
);

await ApiService.createUser(userData.toJson());
```

## 🎨 UI Components

### Leave Request Example Screen
- **Form Validation**: Complete form with date pickers
- **Session Selection**: Morning/Afternoon/Full day options
- **Leave Type Dropdown**: Dynamic loading from API
- **Error Handling**: User-friendly error messages

### My Leave Requests Screen
- **Infinite Scroll**: Pagination with scroll detection
- **Status Filtering**: Filter by request status
- **Pull to Refresh**: Refresh data by pulling down
- **Cancel Requests**: Cancel pending requests
- **Status Indicators**: Color-coded status badges

## 🔧 API Service Methods

### Leave Request Methods
```dart
// Create
static Future<Map<String, dynamic>> createLeaveRequest(Map<String, dynamic> requestData)

// Read
static Future<Map<String, dynamic>> getMyLeaveRequests({...})
static Future<Map<String, dynamic>> getLeaveRequestDetail(int id)
static Future<Map<String, dynamic>> getPendingApprovals({...})

// Update
static Future<Map<String, dynamic>> approveLeaveRequest(int id, String? comments)
static Future<Map<String, dynamic>> rejectLeaveRequest(int id, String comments)

// Delete
static Future<void> cancelLeaveRequest(int id)

// Statistics
static Future<Map<String, dynamic>> getMyStatistics({int? year})
static Future<List<Map<String, dynamic>>> getLeaveTypes()
```

### User Management Methods
```dart
// User Registration
static Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData)

// Department Management
static Future<List<Map<String, dynamic>>> getDepartmentsForDropdown()
static Future<List<Map<String, dynamic>>> getPositionTypes()
static Future<List<Map<String, dynamic>>> getRoles()
```

## 📱 Screen Integration

### Navigation Example
```dart
// Navigate to create leave request
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const LeaveRequestExampleScreen(),
  ),
);

// Navigate to my requests
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MyLeaveRequestsScreen(),
  ),
);

// Navigate to add user
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AddUserScreen(),
  ),
);
```

## 🛠️ Error Handling

### API Error Handling
```dart
try {
  final result = await LeaveRequestService.createLeaveRequest(dto);
  // Success
} catch (e) {
  // Handle error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Lỗi: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

### Form Validation
```dart
// All forms include comprehensive validation:
// - Required fields
// - Email format validation
// - Phone number validation
// - Date range validation
// - Selection validation
```

## 🔄 State Management

### Using with Provider
```dart
// The AuthProvider has been updated to use the new API methods
final authProvider = Provider.of<AuthProvider>(context, listen: false);

// Create user
await authProvider.createUser(userData);

// Get leave requests
final requests = await authProvider.getMyLeaveRequests();
```

## 📊 Data Flow

1. **Load Data**: Screens load initial data (departments, roles, leave types)
2. **User Input**: User fills out forms with validation
3. **API Call**: Data is sent to appropriate API endpoint
4. **Response Handling**: Success/error responses are handled
5. **UI Update**: UI is updated based on response
6. **Navigation**: User is navigated to appropriate screen

## 🎯 Best Practices

1. **Always validate forms** before making API calls
2. **Handle loading states** to show progress indicators
3. **Show error messages** in user-friendly format
4. **Use proper navigation** with result handling
5. **Implement pull-to-refresh** for list screens
6. **Use infinite scroll** for paginated data
7. **Cache data** when appropriate to reduce API calls

## 🚀 Next Steps

1. **Test all endpoints** with real data
2. **Implement offline support** with local storage
3. **Add push notifications** for status updates
4. **Implement file uploads** for attachments
5. **Add advanced filtering** and search capabilities
6. **Create admin dashboard** with comprehensive statistics

## 📞 Support

For any issues or questions about the API integration:
1. Check the API documentation
2. Verify endpoint URLs and parameters
3. Test with Postman/Thunder Client first
4. Check network connectivity
5. Review error messages for specific issues

---

**🎉 Happy Coding!** The new API integration provides a robust foundation for the Leave Management System with modern Flutter practices and comprehensive error handling.
