import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'add_user_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  int? _selectedDepartmentId;
  String? _selectedRole;
  String _searchQuery = '';
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _departments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load departments for dropdown
      final departments = await ApiService.getDepartmentsForDropdown();

      // Load users with department filtering
      final users = await ApiService.getEmployees(
        pageNumber: 1,
        pageSize: 1000, // Load all users for now
        departmentId: _selectedDepartmentId,
        searchTerm: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _departments = departments;
        _users = List<Map<String, dynamic>>.from(users['items'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải dữ liệu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => const AddUserScreen(),
                    ),
                  )
                  .then((_) => _loadData()); // Reload after adding user
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Bộ lọc
                  _buildFilterSection(context),

                  // Danh sách người dùng
                  Expanded(child: _buildUsersList()),
                ],
              ),
    );
  }

  Widget _buildUsersList() {
    return _users.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];
            return _buildUserCard(context, user);
          },
        );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Tìm kiếm
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên hoặc email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _loadData(); // Reload with new search term
            },
          ),
          const SizedBox(height: 12),

          // Bộ lọc
          Row(
            children: [
              // Lọc theo phòng ban
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedDepartmentId,
                  decoration: InputDecoration(
                    labelText: 'Phòng ban',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tất cả'),
                    ),
                    ..._departments.map((dept) {
                      return DropdownMenuItem<int?>(
                        value: dept['id'],
                        child: Text(
                          dept['displayText'] ?? dept['departmentName'],
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartmentId = value;
                    });
                    _loadData(); // Reload with new department filter
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Lọc theo vai trò
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Vai trò',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả')),
                    const DropdownMenuItem(
                      value: 'Admin',
                      child: Text('Admin'),
                    ),
                    const DropdownMenuItem(
                      value: 'Manager',
                      child: Text('Quản lý'),
                    ),
                    const DropdownMenuItem(
                      value: 'Employee',
                      child: Text('Nhân viên'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                    _loadData(); // Reload with new role filter
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy người dùng nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi bộ lọc hoặc tìm kiếm',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final roles = (user['roles'] as List?) ?? [];
    final primaryRole = roles.isNotEmpty ? roles.first : 'Employee';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _getRoleColor(primaryRole),
                  child: Text(
                    (user['fullName'] ?? 'U').split(' ').last[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['fullName'] ?? 'Chưa có tên',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user['email'] ?? 'Chưa có email',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(
                                primaryRole,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRoleText(primaryRole),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getRoleColor(primaryRole),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user['primaryDepartment'] ?? 'Chưa xác định',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editUser(context, user);
                        break;
                      case 'delete':
                        _deleteUser(context, user);
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Xóa', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Thông tin nghỉ phép
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLeaveInfo(
                      'Tổng',
                      '${user['remainingLeaveDays'] != null ? (12.0 + user['remainingLeaveDays']).toInt() : 12}',
                    ),
                  ),
                  Expanded(
                    child: _buildLeaveInfo(
                      'Đã dùng',
                      '${user['remainingLeaveDays'] != null ? (12.0 - user['remainingLeaveDays']).toInt() : 0}',
                    ),
                  ),
                  Expanded(
                    child: _buildLeaveInfo(
                      'Còn lại',
                      '${user['remainingLeaveDays']?.toInt() ?? 12}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Employee':
        return Colors.blue;
      case 'Manager':
        return Colors.orange;
      case 'Admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'Employee':
        return 'Nhân viên';
      case 'Manager':
        return 'Quản lý';
      case 'Admin':
        return 'Admin';
      default:
        return 'Chưa xác định';
    }
  }

  void _editUser(BuildContext context, Map<String, dynamic> user) {
    // TODO: Navigate to edit user screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng chỉnh sửa đang phát triển')),
    );
  }

  void _deleteUser(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: Text(
              'Bạn có chắc chắn muốn xóa người dùng ${user['fullName'] ?? 'này'}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await ApiService.deactivateEmployee(user['id'] ?? 0);
                    await _loadData(); // Reload the list
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã vô hiệu hóa người dùng thành công'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Lỗi khi vô hiệu hóa người dùng: ${e.toString()}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );
  }
}
