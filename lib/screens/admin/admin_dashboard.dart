import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../user_management_screen.dart';
import 'department_management_screen.dart';
import 'leave_type_management_screen.dart';
import 'approval_config_management_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard Admin'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authProvider.logout();
                },
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(
                0.05,
              ), // Thay gradient bằng solid color
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin cá nhân
                  _buildPersonalInfoCard(context, user),
                  const SizedBox(height: 20),

                  // Thống kê tổng quan
                  _buildOverviewStatsCard(context),
                  const SizedBox(height: 20),

                  // Các chức năng chính
                  _buildActionButtons(context),
                  const SizedBox(height: 20),

                  // Thống kê nghỉ phép
                  _buildLeaveStatsCard(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, user) {
    return Card(
      elevation: 4, // Giảm từ 8 xuống 4
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // Giảm từ 16 xuống 12
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              Theme.of(
                context,
              ).colorScheme.primary, // Thay gradient bằng solid color
        ),
        padding: const EdgeInsets.all(16), // Giảm từ 20 xuống 16
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8), // Giảm từ 12 xuống 8
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8), // Giảm từ 12 xuống 8
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 24, // Giảm từ 32 xuống 24
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12), // Giảm từ 16 xuống 12
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 18, // Giảm từ 22 xuống 18
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2), // Giảm từ 4 xuống 2
                  Text(
                    user.departments.isNotEmpty
                        ? user.departments.first.departmentName
                        : 'Chưa xác định',
                    style: TextStyle(
                      fontSize: 14, // Giảm từ 16 xuống 14
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 2), // Giảm từ 4 xuống 2
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ), // Giảm padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        6,
                      ), // Giảm từ 8 xuống 6
                    ),
                    child: const Text(
                      'Quản trị viên',
                      style: TextStyle(
                        fontSize: 10, // Giảm từ 12 xuống 10
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
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

  Widget _buildOverviewStatsCard(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Provider.of<AuthProvider>(context, listen: false).getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Thống kê tổng quan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        // Test API connection khi có lỗi
        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<AuthProvider>(
              context,
              listen: false,
            ).testApiConnection();
          });
        }

        final users = snapshot.data ?? [];
        final totalUsers = users.length;
        final adminCount =
            users
                .where((u) => (u['roles'] as List?)?.contains('Admin') == true)
                .length;
        final managerCount =
            users
                .where(
                  (u) => (u['roles'] as List?)?.contains('Manager') == true,
                )
                .length;
        final employeeCount =
            users
                .where(
                  (u) => (u['roles'] as List?)?.contains('Employee') == true,
                )
                .length;

        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Thống kê tổng quan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatCard(
                      context,
                      'Tổng nhân viên',
                      '$totalUsers',
                      Icons.group,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      context,
                      'Nhân viên',
                      '$employeeCount',
                      Icons.person,
                      Colors.green,
                    ),
                    _buildStatCard(
                      context,
                      'Quản lý',
                      '$managerCount',
                      Icons.supervisor_account,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      context,
                      'Admin',
                      '$adminCount',
                      Icons.admin_panel_settings,
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: (MediaQuery.of(context).size.width - 80) / 2,
      padding: const EdgeInsets.all(12), // Giảm từ 16 xuống 12
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8), // Giảm từ 12 xuống 8
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20), // Giảm từ 28 xuống 20
          const SizedBox(height: 6), // Giảm từ 8 xuống 6
          Text(
            value,
            style: TextStyle(
              fontSize: 18, // Giảm từ 24 xuống 18
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2), // Giảm từ 4 xuống 2
          Text(
            title,
            style: TextStyle(
              fontSize: 10, // Giảm từ 12 xuống 10
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Card(
      elevation: 4, // Giảm từ 8 xuống 4
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // Giảm từ 16 xuống 12
      child: Padding(
        padding: const EdgeInsets.all(16), // Giảm từ 20 xuống 16
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Chức năng quản lý',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionCard(
                  context,
                  'Quản lý người dùng',
                  Icons.people,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  'Quản lý phòng ban',
                  Icons.business,
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const DepartmentManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  'Loại nghỉ phép',
                  Icons.event_available,
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaveTypeManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  'Cấu hình duyệt',
                  Icons.approval,
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const ApprovalConfigManagementScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 80) / 2,
        padding: const EdgeInsets.all(12), // Giảm từ 16 xuống 12
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8), // Giảm từ 12 xuống 8
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24), // Giảm từ 32 xuống 24
            const SizedBox(height: 6), // Giảm từ 8 xuống 6
            Text(
              title,
              style: TextStyle(
                fontSize: 12, // Giảm từ 14 xuống 12
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveStatsCard(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future:
          Provider.of<AuthProvider>(
            context,
            listen: false,
          ).getMyLeaveStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Thống kê nghỉ phép',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        final totalRequests = stats['TotalRequests'] ?? 0;
        final pendingCount = stats['PendingCount'] ?? 0;
        final approvedCount = stats['ApprovedCount'] ?? 0;
        final rejectedCount = stats['RejectedCount'] ?? 0;
        final totalDaysRequested = stats['TotalDaysRequested'] ?? 0;
        final totalDaysApproved = stats['TotalDaysApproved'] ?? 0;

        return Card(
          elevation: 4, // Giảm từ 8 xuống 4
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Giảm từ 16 xuống 12
          ),
          child: Padding(
            padding: const EdgeInsets.all(16), // Giảm từ 20 xuống 16
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Thống kê nghỉ phép',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Giảm từ 20 xuống 16
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatCard(
                      context,
                      'Tổng đơn',
                      '$totalRequests',
                      Icons.description,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      context,
                      'Chờ duyệt',
                      '$pendingCount',
                      Icons.pending,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      context,
                      'Đã duyệt',
                      '$approvedCount',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildStatCard(
                      context,
                      'Từ chối',
                      '$rejectedCount',
                      Icons.cancel,
                      Colors.red,
                    ),
                    _buildStatCard(
                      context,
                      'Ngày xin',
                      '$totalDaysRequested',
                      Icons.date_range,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      context,
                      'Ngày duyệt',
                      '$totalDaysApproved',
                      Icons.event_available,
                      Colors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
