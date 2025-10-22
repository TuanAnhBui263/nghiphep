import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/leave_request_models.dart';
import '../../services/leave_request_service.dart';

class LeaveStatisticsScreen extends StatefulWidget {
  const LeaveStatisticsScreen({super.key});

  @override
  State<LeaveStatisticsScreen> createState() =>
      _LeaveStatisticsScreenState();
}

class _LeaveStatisticsScreenState extends State<LeaveStatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoading = false;
  LeaveStatistics? _myStatistics;
  DepartmentStatistics? _departmentStatistics;
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Load my statistics
      final myStats = await LeaveRequestService.getMyStatistics(year: _selectedYear);
      
      // Load department statistics if user is manager or admin
      DepartmentStatistics? deptStats;
      if (authProvider.isManager || authProvider.isAdmin) {
        deptStats = await LeaveRequestService.getDepartmentStatistics(
          year: _selectedYear,
          month: _selectedMonth,
        );
      }
      
      setState(() {
        _myStatistics = myStats;
        _departmentStatistics = deptStats;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải thống kê: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showYearMonthPicker() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chọn thời gian'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Năm',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(5, (index) {
                  final year = DateTime.now().year - index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) {
                  setDialogState(() {
                    _selectedYear = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: _selectedMonth,
                decoration: const InputDecoration(
                  labelText: 'Tháng (tùy chọn)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả tháng')),
                  ...List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text('Tháng ${index + 1}'),
                    );
                  }),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _selectedMonth = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadStatistics();
              },
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyStatisticsTab() {
    if (_myStatistics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _myStatistics!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                title: 'Tổng đơn',
                value: stats.totalRequests.toString(),
                icon: Icons.description,
                color: Colors.blue,
              ),
              _buildStatCard(
                title: 'Chờ duyệt',
                value: stats.pendingCount.toString(),
                icon: Icons.pending,
                color: Colors.orange,
              ),
              _buildStatCard(
                title: 'Đã duyệt',
                value: stats.approvedCount.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              _buildStatCard(
                title: 'Từ chối',
                value: stats.rejectedCount.toString(),
                icon: Icons.cancel,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Days Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng số ngày nghỉ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Đã yêu cầu',
                          value: stats.totalDaysRequested.toString(),
                          icon: Icons.calendar_today,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Đã được duyệt',
                          value: stats.totalDaysApproved.toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Monthly Statistics
          if (stats.byMonth.isNotEmpty) ...[
            const Text(
              'Thống kê theo tháng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.byMonth.map((monthStat) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    monthStat.month.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text('Tháng ${monthStat.month}'),
                subtitle: Text('${monthStat.count} đơn - ${monthStat.totalDays} ngày'),
                trailing: Text(
                  '${monthStat.totalDays} ngày',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            )),
            const SizedBox(height: 24),
          ],
          
          // Leave Type Statistics
          if (stats.byLeaveType.isNotEmpty) ...[
            const Text(
              'Thống kê theo loại nghỉ phép',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.byLeaveType.map((leaveTypeStat) => Card(
              child: ListTile(
                leading: const Icon(Icons.work_off),
                title: Text(leaveTypeStat.leaveType),
                subtitle: Text('${leaveTypeStat.count} đơn'),
                trailing: Text(
                  '${leaveTypeStat.totalDays} ngày',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildDepartmentStatisticsTab() {
    if (_departmentStatistics == null) {
      return const Center(
        child: Text('Không có quyền xem thống kê phòng ban'),
      );
    }

    final stats = _departmentStatistics!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Tổng đơn nghỉ phép: ${stats.totalRequests}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (stats.month != null)
                    Text(
                      'Tháng ${stats.month}/${stats.year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    Text(
                      'Năm ${stats.year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Status Statistics
          if (stats.byStatus.isNotEmpty) ...[
            const Text(
              'Thống kê theo trạng thái',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.byStatus.map((statusStat) => Card(
              child: ListTile(
                leading: Icon(
                  _getStatusIcon(statusStat.status),
                  color: _getStatusColor(statusStat.status),
                ),
                title: Text(_getStatusDisplayName(statusStat.status)),
                subtitle: Text('${statusStat.count} đơn'),
                trailing: Text(
                  '${statusStat.totalDays} ngày',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            )),
            const SizedBox(height: 24),
          ],
          
          // Leave Type Statistics
          if (stats.byLeaveType.isNotEmpty) ...[
            const Text(
              'Thống kê theo loại nghỉ phép',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.byLeaveType.map((leaveTypeStat) => Card(
              child: ListTile(
                leading: const Icon(Icons.work_off),
                title: Text(leaveTypeStat.leaveType),
                subtitle: Text('${leaveTypeStat.count} đơn'),
                trailing: Text(
                  '${leaveTypeStat.totalDays} ngày',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            )),
            const SizedBox(height: 24),
          ],
          
          // Employee Statistics
          if (stats.byEmployee.isNotEmpty) ...[
            const Text(
              'Thống kê theo nhân viên',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.byEmployee.map((employeeStat) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(employeeStat.employeeName),
                subtitle: Text('${employeeStat.count} đơn - ${employeeStat.approvedDays}/${employeeStat.totalDays} ngày duyệt'),
                trailing: Text(
                  '${employeeStat.totalDays} ngày',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.pending;
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ duyệt';
      case 'APPROVED':
        return 'Đã duyệt';
      case 'REJECTED':
        return 'Từ chối';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê nghỉ phép'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showYearMonthPicker,
            icon: const Icon(Icons.date_range),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Cá nhân'),
            Tab(text: 'Phòng ban'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildMyStatisticsTab(),
                  _buildDepartmentStatisticsTab(),
                ],
              ),
      ),
    );
  }
}
