import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/leave_request.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  // Leave types from API
  List<Map<String, dynamic>> _leaveTypes = [];
  int? _selectedLeaveTypeId;

  // Sessions per spec: MORNING/AFTERNOON
  String _startSession = 'MORNING';
  String _endSession = 'AFTERNOON';

  LeaveType _selectedType = LeaveType.fullDay; // fallback for total day calc UI
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLeaveTypes();
  }

  Future<void> _loadLeaveTypes() async {
    try {
      final types = await ApiService.getLeaveTypes();
      if (!mounted) return;
      setState(() {
        _leaveTypes = types;
        if (_leaveTypes.isNotEmpty) {
          _selectedLeaveTypeId = _leaveTypes.first['id'] as int?;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải loại nghỉ phép: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Kiểm tra ngày bắt đầu không được trong quá khứ
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
    );

    if (startDate.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày bắt đầu không được trong quá khứ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra ngày kết thúc phải sau ngày bắt đầu
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày kết thúc phải sau ngày bắt đầu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Tính tổng số ngày nghỉ
      final totalDays = LeaveRequest.calculateTotalDays(
        _selectedType,
        _startDate,
        _endDate,
      );

      // Kiểm tra số ngày nghỉ còn lại
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final stats = await authProvider.getMyLeaveStatistics();
      final totalDaysApproved = (stats['TotalDaysApproved'] ?? 0).toDouble();
      final annualLeaveDays = 12.0; // TODO: Get from API
      final remainingDays = annualLeaveDays - totalDaysApproved;
      if (totalDays > remainingDays) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Số ngày nghỉ còn lại không đủ (còn $remainingDays ngày)',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Submit theo tài liệu API
      final success = await Provider.of<AuthProvider>(context, listen: false)
          .createLeaveRequest({
        'leaveTypeId': _selectedLeaveTypeId,
        'startDate': _startDate.toUtc().toIso8601String(),
        'endDate': _endDate.toUtc().toIso8601String(),
        'startSession': _startSession,
        'endSession': _endSession,
        'reason': _reasonController.text.trim(),
        'attachmentUrl': null,
      });

      if (!success) {
        throw Exception('Gửi đơn nghỉ phép thất bại');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đơn nghỉ phép đã được gửi thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xin nghỉ phép'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin người xin nghỉ
              _buildUserInfoCard(context),
              const SizedBox(height: 16),

              // Form xin nghỉ
              _buildLeaveFormCard(context),
              const SizedBox(height: 16),

              // Nút gửi đơn
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitLeaveRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Gửi đơn nghỉ phép',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser!;

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin người xin nghỉ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        user.fullName.split(' ').last[0].toUpperCase(),
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
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          FutureBuilder<Map<String, dynamic>>(
                            future: authProvider.getMyLeaveStatistics(),
                            builder: (context, snapshot) {
                              final stats = snapshot.data ?? {};
                              final totalDaysApproved =
                                  (stats['TotalDaysApproved'] ?? 0).toDouble();
                              final annualLeaveDays = 12.0;
                              final remainingDays =
                                  annualLeaveDays - totalDaysApproved;

                              return Text(
                                user.departments.isNotEmpty
                                    ? '${user.departments.first.departmentName} • Còn lại: ${remainingDays.toInt()} ngày'
                                    : 'Chưa xác định phòng ban • Còn lại: ${remainingDays.toInt()} ngày',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
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
      },
    );
  }

  Widget _buildLeaveFormCard(BuildContext context) {
    final totalDays = LeaveRequest.calculateTotalDays(
      _selectedType,
      _startDate,
      _endDate,
    );

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin nghỉ phép',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Loại nghỉ (từ API)
            const Text(
              'Loại nghỉ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedLeaveTypeId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _leaveTypes
                  .map(
                    (t) => DropdownMenuItem<int>(
                      value: t['id'] as int?,
                      child: Text(
                        (t['leaveTypeName'] ?? t['name'] ?? 'Loại nghỉ')
                            .toString(),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLeaveTypeId = value;
                });
              },
              validator: (value) => value == null ? 'Chọn loại nghỉ' : null,
            ),
            const SizedBox(height: 16),

            // Phiên bắt đầu/kết thúc
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.blue[700], size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Phiên làm việc',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSessionDropdown(
                          'Bắt đầu',
                          _startSession,
                          (v) => setState(() => _startSession = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSessionDropdown(
                          'Kết thúc',
                          _endSession,
                          (v) => setState(() => _endSession = v!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ngày bắt đầu và kết thúc
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Ngày bắt đầu',
                    _startDate,
                    Icons.calendar_today,
                    Colors.green,
                    () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                          if (_endDate.isBefore(_startDate)) {
                            _endDate = _startDate;
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    'Ngày kết thúc',
                    _endDate,
                    Icons.calendar_today,
                    Colors.red,
                    () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tổng số ngày
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng số ngày nghỉ: $totalDays ngày',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lý do nghỉ
            const Text(
              'Lý do nghỉ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập lý do nghỉ phép...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập lý do nghỉ phép';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionDropdown(String label, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(
              value: 'MORNING',
              child: Text('Sáng', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: 'AFTERNOON',
              child: Text('Chiều', style: TextStyle(fontSize: 12)),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date, IconData icon, Color color, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(6),
              color: color.withOpacity(0.05),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
