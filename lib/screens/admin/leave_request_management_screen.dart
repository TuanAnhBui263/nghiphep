import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/leave_request_models.dart';
import '../../services/leave_request_service.dart';
import 'leave_request_detail_screen.dart';
import 'create_leave_request_screen.dart';

class LeaveRequestManagementScreen extends StatefulWidget {
  const LeaveRequestManagementScreen({super.key});

  @override
  State<LeaveRequestManagementScreen> createState() =>
      _LeaveRequestManagementScreenState();
}

class _LeaveRequestManagementScreenState
    extends State<LeaveRequestManagementScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'ALL';
  String _selectedSortBy = 'CreatedAt';
  String _selectedSortDirection = 'DESC';
  
  bool _isLoading = false;
  List<LeaveRequestSummary> _requests = [];
  int _totalCount = 0;
  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _requests.clear();
      });
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      PagedResult<LeaveRequestSummary> result;
      
      if (authProvider.isAdmin) {
        // Admin: Lấy tất cả đơn
        result = await LeaveRequestService.getAllRequests(
          status: _selectedStatus == 'ALL' ? null : _selectedStatus,
          employeeName: _searchController.text.isNotEmpty 
              ? _searchController.text 
              : null,
          sortBy: _selectedSortBy,
          sortDirection: _selectedSortDirection,
          pageNumber: _currentPage,
          pageSize: _pageSize,
        );
      } else if (authProvider.isManager) {
        // Manager: Lấy đơn cần duyệt
        result = await LeaveRequestService.getPendingApprovals(
          employeeName: _searchController.text.isNotEmpty 
              ? _searchController.text 
              : null,
          sortBy: _selectedSortBy,
          sortDirection: _selectedSortDirection,
          pageNumber: _currentPage,
          pageSize: _pageSize,
        );
      } else {
        // Employee: Lấy đơn của mình
        result = await LeaveRequestService.getMyRequests(
          status: _selectedStatus == 'ALL' ? null : _selectedStatus,
          pageNumber: _currentPage,
          pageSize: _pageSize,
        );
      }

      setState(() {
        if (refresh) {
          _requests = result.items;
        } else {
          _requests.addAll(result.items);
        }
        _totalCount = result.totalCount;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Bộ lọc'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'PENDING', child: Text('Chờ duyệt')),
                  DropdownMenuItem(value: 'APPROVED', child: Text('Đã duyệt')),
                  DropdownMenuItem(value: 'REJECTED', child: Text('Từ chối')),
                  DropdownMenuItem(value: 'CANCELLED', child: Text('Đã hủy')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSortBy,
                decoration: const InputDecoration(
                  labelText: 'Sắp xếp theo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'CreatedAt', child: Text('Ngày tạo')),
                  DropdownMenuItem(value: 'StartDate', child: Text('Ngày bắt đầu')),
                  DropdownMenuItem(value: 'EndDate', child: Text('Ngày kết thúc')),
                  DropdownMenuItem(value: 'Status', child: Text('Trạng thái')),
                  DropdownMenuItem(value: 'TotalDays', child: Text('Số ngày')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _selectedSortBy = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSortDirection,
                decoration: const InputDecoration(
                  labelText: 'Thứ tự',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ASC', child: Text('Tăng dần')),
                  DropdownMenuItem(value: 'DESC', child: Text('Giảm dần')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    _selectedSortDirection = value!;
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
                _loadRequests(refresh: true);
              },
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(LeaveRequestSummary request) {
    Color statusColor;
    IconData statusIcon;
    
    switch (request.status) {
      case LeaveRequestStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case LeaveRequestStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case LeaveRequestStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case LeaveRequestStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel_outlined;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LeaveRequestDetailScreen(requestId: request.id),
            ),
          );
          if (result == true) {
            _loadRequests(refresh: true);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.requestCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.employeeName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          request.status.displayName,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(request.startDate)} - ${_formatDate(request.endDate)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.work_off, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    request.leaveTypeName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${request.totalDays} ngày',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          authProvider.isAdmin 
              ? 'Quản lý đơn nghỉ phép' 
              : authProvider.isManager 
                  ? 'Đơn cần duyệt' 
                  : 'Đơn nghỉ phép của tôi',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
          ),
        ],
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
        child: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên nhân viên...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _loadRequests(refresh: true);
                    },
                    icon: const Icon(Icons.clear),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (value) {
                  _loadRequests(refresh: true);
                },
              ),
            ),
            // Content
            Expanded(
              child: _isLoading && _requests.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Không có đơn nghỉ phép nào',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadRequests(refresh: true),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _requests.length + (_isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _requests.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return _buildRequestCard(_requests[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: authProvider.isEmployee
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateLeaveRequestScreen(),
                  ),
                );
                if (result == true) {
                  _loadRequests(refresh: true);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo đơn nghỉ phép'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
