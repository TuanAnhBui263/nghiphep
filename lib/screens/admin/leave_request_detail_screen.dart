import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/leave_request_models.dart';
import '../../services/leave_request_service.dart';

class LeaveRequestDetailScreen extends StatefulWidget {
  final int requestId;

  const LeaveRequestDetailScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<LeaveRequestDetailScreen> createState() =>
      _LeaveRequestDetailScreenState();
}

class _LeaveRequestDetailScreenState extends State<LeaveRequestDetailScreen> {
  bool _isLoading = false;
  LeaveRequestFull? _request;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequestDetail();
  }

  Future<void> _loadRequestDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = await LeaveRequestService.getLeaveRequest(widget.requestId);
      setState(() {
        _request = request;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showApprovalDialog() {
    final commentsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duyệt đơn nghỉ phép'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn có chắc chắn muốn duyệt đơn nghỉ phép này?'),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _approveRequest(commentsController.text);
            },
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog() {
    final commentsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối đơn nghỉ phép'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn có chắc chắn muốn từ chối đơn nghỉ phép này?'),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentsController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập lý do từ chối'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.of(context).pop();
              await _rejectRequest(commentsController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn nghỉ phép'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn nghỉ phép này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _cancelRequest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(String comments) async {
    if (_request == null) return;

    setState(() => _isLoading = true);
    try {
      // Tìm approval level đầu tiên chưa được duyệt
      final pendingApproval = _request!.approvals.firstWhere(
        (approval) => approval.status == LeaveRequestStatus.pending,
        orElse: () => _request!.approvals.first,
      );

      await LeaveRequestService.approveLeaveRequest(
        _request!.id,
        pendingApproval.id,
        comments,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Duyệt đơn nghỉ phép thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi duyệt đơn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectRequest(String comments) async {
    if (_request == null) return;

    setState(() => _isLoading = true);
    try {
      // Tìm approval level đầu tiên chưa được duyệt
      final pendingApproval = _request!.approvals.firstWhere(
        (approval) => approval.status == LeaveRequestStatus.pending,
        orElse: () => _request!.approvals.first,
      );

      await LeaveRequestService.rejectLeaveRequest(
        _request!.id,
        pendingApproval.id,
        comments,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Từ chối đơn nghỉ phép thành công!'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi từ chối đơn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelRequest() async {
    if (_request == null) return;

    setState(() => _isLoading = true);
    try {
      await LeaveRequestService.cancelLeaveRequest(_request!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hủy đơn nghỉ phép thành công!'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi hủy đơn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStatusChip(LeaveRequestStatus status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case LeaveRequestStatus.pending:
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case LeaveRequestStatus.approved:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case LeaveRequestStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case LeaveRequestStatus.cancelled:
        color = Colors.grey;
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(ApprovalInfo approval) {
    Color statusColor;
    IconData statusIcon;
    
    switch (approval.status) {
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
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, size: 20, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    approval.approvalLevelName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    approval.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Người duyệt: ${approval.approverName}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (approval.comments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ghi chú: ${approval.comments}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
            if (approval.approvedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Thời gian: ${_formatDateTime(approval.approvedAt!)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn nghỉ phép'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_request != null && _request!.status == LeaveRequestStatus.pending)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'approve':
                    _showApprovalDialog();
                    break;
                  case 'reject':
                    _showRejectionDialog();
                    break;
                  case 'cancel':
                    _showCancelDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (authProvider.isManager || authProvider.isAdmin) ...[
                  const PopupMenuItem(
                    value: 'approve',
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Duyệt'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reject',
                    child: Row(
                      children: [
                        Icon(Icons.close, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Từ chối'),
                      ],
                    ),
                  ),
                ],
                if (authProvider.isEmployee) ...[
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Hủy đơn'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lỗi tải dữ liệu',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRequestDetail,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _request == null
                  ? const Center(child: Text('Không có dữ liệu'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _request!.requestCode,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      _buildStatusChip(_request!.status),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nhân viên: ${_request!.employeeName}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Loại nghỉ: ${_request!.leaveTypeName}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Thời gian: ${_formatDate(_request!.startDate)} - ${_formatDate(_request!.endDate)}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Số ngày: ${_request!.totalDays} ngày',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Lý do: ${_request!.reason}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Leave Details
                          const Text(
                            'Chi tiết ngày nghỉ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._request!.leaveDetails.map((detail) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 20),
                                  const SizedBox(width: 8),
                                  Text(_formatDate(detail.leaveDate)),
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
                                      '${detail.session.displayName} (${detail.dayValue} ngày)',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                          const SizedBox(height: 16),
                          
                          // Approval Process
                          const Text(
                            'Quy trình duyệt',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._request!.approvals.map((approval) => _buildApprovalCard(approval)),
                        ],
                      ),
                    ),
    );
  }
}
