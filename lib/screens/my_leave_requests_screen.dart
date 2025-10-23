import 'package:flutter/material.dart';
import '../services/leave_request_service.dart';
import '../models/leave_request_dto.dart';
import 'create_leave_request_screen.dart';

class MyLeaveRequestsScreen extends StatefulWidget {
  const MyLeaveRequestsScreen({super.key});

  @override
  State<MyLeaveRequestsScreen> createState() => _MyLeaveRequestsScreenState();
}

class _MyLeaveRequestsScreenState extends State<MyLeaveRequestsScreen> {
  final _scrollController = ScrollController();

  List<LeaveRequestSummary> _requests = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _requests.clear();
    });

    try {
      final result = await LeaveRequestService.getMyLeaveRequests(
        status: _selectedStatus,
        pageNumber: _currentPage,
        pageSize: 20,
      );

      setState(() {
        _requests = result.items;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    try {
      final result = await LeaveRequestService.getMyLeaveRequests(
        status: _selectedStatus,
        pageNumber: _currentPage,
        pageSize: 20,
      );

      setState(() {
        _requests.addAll(result.items);
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentPage--;
      });
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
        return Colors.black;
    }
  }

  String _getStatusText(String status) {
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

  Future<void> _cancelRequest(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc muốn hủy đơn này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await LeaveRequestService.cancelLeaveRequest(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã hủy đơn thành công'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRequests(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
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
        title: const Text('Đơn của tôi'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedStatus = value == 'ALL' ? null : value;
              });
              _loadRequests();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'ALL', child: Text('Tất cả')),
              PopupMenuItem(value: 'PENDING', child: Text('Chờ duyệt')),
              PopupMenuItem(value: 'APPROVED', child: Text('Đã duyệt')),
              PopupMenuItem(value: 'REJECTED', child: Text('Từ chối')),
              PopupMenuItem(value: 'CANCELLED', child: Text('Đã hủy')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _requests.isEmpty && !_isLoading
            ? const Center(child: Text('Chưa có đơn nào'))
            : ListView.builder(
                controller: _scrollController,
                itemCount: _requests.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _requests.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final request = _requests[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(
                        request.leaveTypeName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Mã: ${request.requestCode}'),
                          Text(
                            '${request.startDate} → ${request.endDate}',
                          ),
                          Text('${request.totalDays} ngày'),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(request.status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(request.status),
                              style: TextStyle(
                                color: _getStatusColor(request.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (request.status == 'PENDING')
                            TextButton(
                              onPressed: () => _cancelRequest(request.id),
                              child: const Text(
                                'Hủy',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        // Navigate to detail screen
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => LeaveRequestDetailScreen(
                        //       requestId: request.id,
                        //     ),
                        //   ),
                        // );
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateLeaveRequestScreen(),
            ),
          );
          if (result == true) {
            _loadRequests(); // Refresh list
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
