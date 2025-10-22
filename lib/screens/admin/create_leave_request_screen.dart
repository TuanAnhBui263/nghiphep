import 'package:flutter/material.dart';
import '../../models/leave_request_models.dart';
import '../../models/leave_type.dart';
import '../../services/leave_request_service.dart';

class CreateLeaveRequestScreen extends StatefulWidget {
  const CreateLeaveRequestScreen({super.key});

  @override
  State<CreateLeaveRequestScreen> createState() =>
      _CreateLeaveRequestScreenState();
}

class _CreateLeaveRequestScreenState extends State<CreateLeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  bool _isLoading = false;
  List<LeaveType> _leaveTypes = [];
  LeaveType? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  Session _startSession = Session.full;
  Session _endSession = Session.full;
  double _totalDays = 0;

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
    setState(() => _isLoading = true);
    try {
      final leaveTypes = await LeaveRequestService.getLeaveTypes();
      setState(() => _leaveTypes = leaveTypes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách loại nghỉ phép: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
        _calculateTotalDays();
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày bắt đầu trước'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!,
      firstDate: _startDate!,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
        _calculateTotalDays();
      });
    }
  }

  void _calculateTotalDays() {
    if (_startDate == null || _endDate == null) {
      setState(() => _totalDays = 0);
      return;
    }

    final days = _endDate!.difference(_startDate!).inDays + 1;
    double totalDays = days.toDouble();

    // Nếu chỉ có 1 ngày và start/end session khác nhau
    if (days == 1 && _startSession != _endSession) {
      totalDays = 1.0;
    }
    // Nếu có nhiều ngày, trừ đi 0.5 cho ngày đầu và cuối nếu không phải full day
    else if (days > 1) {
      if (_startSession != Session.full) totalDays -= 0.5;
      if (_endSession != Session.full) totalDays -= 0.5;
    }

    setState(() => _totalDays = totalDays);
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLeaveType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn loại nghỉ phép'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày bắt đầu và kết thúc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dto = CreateLeaveRequestDto(
        leaveTypeId: _selectedLeaveType!.id,
        startDate: _startDate!,
        endDate: _endDate!,
        startSession: _startSession,
        endSession: _endSession,
        totalDays: _totalDays,
        reason: _reasonController.text.trim(),
      );

      await LeaveRequestService.createLeaveRequest(dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo đơn nghỉ phép thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo đơn nghỉ phép: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSessionSelector(
    String label,
    Session currentSession,
    Function(Session) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: Session.values.map((session) {
            return Expanded(
              child: RadioListTile<Session>(
                title: Text(
                  session.displayName,
                  style: const TextStyle(fontSize: 14),
                ),
                value: session,
                groupValue: currentSession,
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                    _calculateTotalDays();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo đơn nghỉ phép'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading && _leaveTypes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Leave Type Selection
                      const Text(
                        'Loại nghỉ phép *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<LeaveType>(
                        value: _selectedLeaveType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Chọn loại nghỉ phép',
                        ),
                        items: _leaveTypes.map((leaveType) {
                          return DropdownMenuItem<LeaveType>(
                            value: leaveType,
                            child: Text(leaveType.leaveTypeName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedLeaveType = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Vui lòng chọn loại nghỉ phép';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Date Selection
                      const Text(
                        'Thời gian nghỉ phép *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ngày bắt đầu'),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _selectStartDate,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today),
                                        const SizedBox(width: 8),
                                        Text(
                                          _startDate != null
                                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                              : 'Chọn ngày',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ngày kết thúc'),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _selectEndDate,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today),
                                        const SizedBox(width: 8),
                                        Text(
                                          _endDate != null
                                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                              : 'Chọn ngày',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Session Selection
                      _buildSessionSelector(
                        'Buổi bắt đầu',
                        _startSession,
                        (session) => setState(() => _startSession = session),
                      ),
                      const SizedBox(height: 16),
                      _buildSessionSelector(
                        'Buổi kết thúc',
                        _endSession,
                        (session) => setState(() => _endSession = session),
                      ),
                      const SizedBox(height: 24),

                      // Total Days Display
                      if (_totalDays > 0)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tổng số ngày nghỉ: $_totalDays ngày',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Reason
                      const Text(
                        'Lý do nghỉ phép *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Nhập lý do nghỉ phép...',
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập lý do nghỉ phép';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Tạo đơn nghỉ phép',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
