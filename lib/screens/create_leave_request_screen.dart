import 'package:flutter/material.dart';
import '../services/leave_request_service.dart';
import '../models/leave_request_dto.dart';

class CreateLeaveRequestScreen extends StatefulWidget {
  const CreateLeaveRequestScreen({super.key});

  @override
  State<CreateLeaveRequestScreen> createState() => _CreateLeaveRequestScreenState();
}

class _CreateLeaveRequestScreenState extends State<CreateLeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  
  int? _selectedLeaveTypeId;
  DateTime? _startDate;
  DateTime? _endDate;
  String _startSession = 'FULL';
  String _endSession = 'FULL';
  
  List<LeaveType> _leaveTypes = [];
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadLeaveTypes();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaveTypes() async {
    try {
      final types = await LeaveRequestService.getLeaveTypes();
      setState(() {
        _leaveTypes = types;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách loại phép: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: _loadLeaveTypes,
            ),
          ),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày bắt đầu và kết thúc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedLeaveTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn loại nghỉ phép'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final totalDays = _endDate!.difference(_startDate!).inDays + 1;

      final dto = LeaveRequestDto(
        leaveTypeId: _selectedLeaveTypeId!,
        startDate: _startDate!.toIso8601String().split('T')[0],
        endDate: _endDate!.toIso8601String().split('T')[0],
        startSession: _startSession,
        endSession: _endSession,
        totalDays: totalDays.toDouble(),
        reason: _reasonController.text.trim(),
      );

      final result = await LeaveRequestService.createLeaveRequest(dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Tạo đơn thành công: ${result.requestCode}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo đơn xin nghỉ'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingData
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải dữ liệu...'),
                ],
              ),
            )
          : _leaveTypes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Không thể tải dữ liệu',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Vui lòng kiểm tra kết nối mạng'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLeaveTypes,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Leave Type Dropdown
                      DropdownButtonFormField<int>(
                        value: _selectedLeaveTypeId,
                        decoration: const InputDecoration(
                          labelText: 'Loại nghỉ phép',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _leaveTypes.map((type) {
                          return DropdownMenuItem(
                            value: type.id,
                            child: Text(type.leaveTypeName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedLeaveTypeId = value);
                        },
                        validator: (value) =>
                            value == null ? 'Vui lòng chọn loại phép' : null,
                      ),

                      const SizedBox(height: 16),

                      // Start Date
                      ListTile(
                        title: const Text('Ngày bắt đầu'),
                        subtitle: Text(_startDate?.toString().split(' ')[0] ?? 'Chưa chọn'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _startDate = date);
                          }
                        },
                      ),

                      // End Date
                      ListTile(
                        title: const Text('Ngày kết thúc'),
                        subtitle: Text(_endDate?.toString().split(' ')[0] ?? 'Chưa chọn'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? _startDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => _endDate = date);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Session Selection
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _startSession,
                              decoration: const InputDecoration(
                                labelText: 'Buổi bắt đầu',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.wb_sunny),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'MORNING', child: Text('Buổi sáng')),
                                DropdownMenuItem(value: 'AFTERNOON', child: Text('Buổi chiều')),
                                DropdownMenuItem(value: 'FULL', child: Text('Cả ngày')),
                              ],
                              onChanged: (value) {
                                setState(() => _startSession = value!);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _endSession,
                              decoration: const InputDecoration(
                                labelText: 'Buổi kết thúc',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.wb_sunny_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'MORNING', child: Text('Buổi sáng')),
                                DropdownMenuItem(value: 'AFTERNOON', child: Text('Buổi chiều')),
                                DropdownMenuItem(value: 'FULL', child: Text('Cả ngày')),
                              ],
                              onChanged: (value) {
                                setState(() => _endSession = value!);
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Reason
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Lý do',
                          border: OutlineInputBorder(),
                          hintText: 'Nhập lý do xin nghỉ...',
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Vui lòng nhập lý do'
                                : null,
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'GỬI ĐƠN',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
