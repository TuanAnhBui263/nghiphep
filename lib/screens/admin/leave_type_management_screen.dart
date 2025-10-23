import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/leave_request_dto.dart';
import '../../services/leave_request_service.dart';

class LeaveTypeManagementScreen extends StatefulWidget {
  const LeaveTypeManagementScreen({super.key});

  @override
  State<LeaveTypeManagementScreen> createState() =>
      _LeaveTypeManagementScreenState();
}

class _LeaveTypeManagementScreenState extends State<LeaveTypeManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _requiresAttachment = false;
  bool _deductsFromBalance = true;
  bool _isActive = true;

  List<LeaveType> _leaveTypes = [];
  LeaveType? _editingLeaveType;

  @override
  void initState() {
    super.initState();
    _loadLeaveTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
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

  void _showAddLeaveTypeDialog() {
    _editingLeaveType = null;
    _nameController.clear();
    _codeController.clear();
    _descriptionController.clear();
    _requiresAttachment = false;
    _deductsFromBalance = true;
    _isActive = true;

    showDialog(context: context, builder: (context) => _buildLeaveTypeDialog());
  }

  void _showEditLeaveTypeDialog(LeaveType leaveType) {
    _editingLeaveType = leaveType;
    _nameController.text = leaveType.leaveTypeName;
    _codeController.text = leaveType.leaveTypeCode;
    _descriptionController.text = '';
    _requiresAttachment = false;
    _deductsFromBalance = true;
    _isActive = true;

    showDialog(context: context, builder: (context) => _buildLeaveTypeDialog());
  }

  Widget _buildLeaveTypeDialog() {
    return AlertDialog(
      title: Text(
        _editingLeaveType == null
            ? 'Thêm loại nghỉ phép'
            : 'Sửa loại nghỉ phép',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên loại nghỉ phép *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên loại nghỉ phép';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã loại nghỉ phép *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mã loại nghỉ phép';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Yêu cầu đính kèm'),
                subtitle: const Text('Cần đính kèm giấy tờ khi nghỉ'),
                value: _requiresAttachment,
                onChanged: (value) {
                  setState(() => _requiresAttachment = value ?? false);
                },
              ),
              CheckboxListTile(
                title: const Text('Trừ vào số ngày phép'),
                subtitle: const Text(
                  'Loại nghỉ này sẽ trừ vào số ngày phép năm',
                ),
                value: _deductsFromBalance,
                onChanged: (value) {
                  setState(() => _deductsFromBalance = value ?? true);
                },
              ),
              CheckboxListTile(
                title: const Text('Đang hoạt động'),
                subtitle: const Text('Loại nghỉ phép này có thể sử dụng'),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value ?? true);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(onPressed: _saveLeaveType, child: const Text('Lưu')),
      ],
    );
  }

  Future<void> _saveLeaveType() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final leaveTypeData = {
        'leaveTypeName': _nameController.text,
        'leaveTypeCode': _codeController.text,
        'description': _descriptionController.text,
        'requiresAttachment': _requiresAttachment,
        'deductsFromBalance': _deductsFromBalance,
        'isActive': _isActive,
      };

      bool success;
      if (_editingLeaveType == null) {
        success = await authProvider.createLeaveType(leaveTypeData);
      } else {
        success = await authProvider.updateLeaveType(
          _editingLeaveType!.id,
          leaveTypeData,
        );
      }

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _editingLeaveType == null
                    ? 'Thêm loại nghỉ phép thành công!'
                    : 'Cập nhật loại nghỉ phép thành công!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadLeaveTypes();
        }
      } else {
        throw Exception('Không thể lưu loại nghỉ phép');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý loại nghỉ phép'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _loadLeaveTypes,
                  child:
                      _leaveTypes.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_available,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có loại nghỉ phép nào',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nhấn nút + để thêm loại nghỉ phép đầu tiên',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _leaveTypes.length,
                            itemBuilder: (context, index) {
                              final leaveType = _leaveTypes[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.event_available,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    leaveType.leaveTypeName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'Mã: ${leaveType.leaveTypeCode}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditLeaveTypeDialog(leaveType);
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
                                                Text('Sửa'),
                                              ],
                                            ),
                                          ),
                                        ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLeaveTypeDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm loại nghỉ'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
