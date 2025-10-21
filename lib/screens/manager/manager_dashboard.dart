import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../approval_screen.dart';
import '../leave_request_screen.dart';
import '../leave_history_screen.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard Quản lý'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await authProvider.logout();
                  // Navigation is handled by AuthWrapper
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin cá nhân
                _buildPersonalInfoCard(context, user),
                const SizedBox(height: 16),

                // Thống kê nghỉ phép
                _buildLeaveStatsCard(context, user),
                const SizedBox(height: 16),

                // Các chức năng chính
                _buildActionButtons(context),
                const SizedBox(height: 16),

                // Đơn nghỉ phép chờ duyệt
                _buildPendingApprovalsCard(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, user) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    user.fullName.split(' ').last[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.departments.isNotEmpty
                            ? user.departments.first.departmentName
                            : 'Chưa xác định',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      Text(
                        user.departments.isNotEmpty
                            ? user.departments.first.positionName
                            : 'Quản lý',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveStatsCard(BuildContext context, user) {
    return FutureBuilder<Map<String, dynamic>>(
      future:
          Provider.of<AuthProvider>(
            context,
            listen: false,
          ).getMyLeaveStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Thống kê nghỉ phép năm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        final totalDaysApproved = (stats['TotalDaysApproved'] ?? 0).toDouble();

        // Giả sử Manager có 16 ngày phép (có thể lấy từ API sau)
        final annualLeaveDays = 16.0;
        final remainingDays = annualLeaveDays - totalDaysApproved;
        final percentage =
            annualLeaveDays > 0 ? totalDaysApproved / annualLeaveDays : 0.0;

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thống kê nghỉ phép năm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Thanh tiến trình
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage > 0.8 ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Đã sử dụng: ${totalDaysApproved.toInt()}/${annualLeaveDays.toInt()} ngày (${(percentage * 100).toStringAsFixed(1)}%)',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Thông tin chi tiết
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width:
                          MediaQuery.of(context).size.width > 600
                              ? null
                              : (MediaQuery.of(context).size.width - 48) / 2,
                      child: _buildStatItem(
                        'Tổng ngày nghỉ',
                        '${annualLeaveDays.toInt()}',
                        Icons.calendar_today,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(
                      width:
                          MediaQuery.of(context).size.width > 600
                              ? null
                              : (MediaQuery.of(context).size.width - 48) / 2,
                      child: _buildStatItem(
                        'Đã sử dụng',
                        '${totalDaysApproved.toInt()}',
                        Icons.check_circle,
                        Colors.orange,
                      ),
                    ),
                    SizedBox(
                      width:
                          MediaQuery.of(context).size.width > 600
                              ? null
                              : (MediaQuery.of(context).size.width - 48) / 2,
                      child: _buildStatItem(
                        'Còn lại',
                        '${remainingDays.toInt()}',
                        Icons.schedule,
                        Colors.green,
                      ),
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

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chức năng chính',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Grid layout cho các nút chức năng
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildActionButton(
                  context,
                  'Duyệt đơn nghỉ',
                  Icons.approval,
                  Colors.blue,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ApprovalScreen(),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  'Xin nghỉ phép',
                  Icons.add_circle_outline,
                  Colors.orange,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LeaveRequestScreen(),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  'Lịch sử nghỉ',
                  Icons.history,
                  Colors.purple,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LeaveHistoryScreen(),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  'Báo cáo',
                  Icons.assessment,
                  Colors.green,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chức năng đang phát triển'),
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

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovalsCard(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future:
          Provider.of<AuthProvider>(
            context,
            listen: false,
          ).getPendingApprovals(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?['totalCount'] ?? 0;

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đơn nghỉ phép chờ duyệt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (pendingCount == 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Không có đơn nghỉ phép nào chờ duyệt',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                else
                  // TODO: Hiển thị danh sách đơn nghỉ phép chờ duyệt
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Có $pendingCount đơn nghỉ phép chờ duyệt',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
