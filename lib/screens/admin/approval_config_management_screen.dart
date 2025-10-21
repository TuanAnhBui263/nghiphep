import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ApprovalConfigManagementScreen extends StatefulWidget {
  const ApprovalConfigManagementScreen({super.key});

  @override
  State<ApprovalConfigManagementScreen> createState() =>
      _ApprovalConfigManagementScreenState();
}

class _ApprovalConfigManagementScreenState
    extends State<ApprovalConfigManagementScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  List<Map<String, dynamic>> _approvalConfigs = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _approvalLevels = [];

  Map<String, dynamic>? _editingConfig;
  int? _selectedDepartmentId;
  int? _selectedApprovalLevelId;
  int? _selectedApproverPositionTypeId;
  int? _selectedSpecificApproverId;
  int _orderIndex = 1;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final futures = await Future.wait([
        authProvider.getApprovalConfigs(),
        authProvider.getDepartments(),
        // Note: We'll need to add getApprovalLevels method to AuthProvider
        // For now, we'll use mock data
        Future.value([
          {'id': 1, 'levelName': 'Cấp 1 - Trưởng/Phó Phòng', 'levelOrder': 1},
          {'id': 2, 'levelName': 'Cấp 2 - Lãnh đạo', 'levelOrder': 2},
        ]),
      ]);

      setState(() {
        _approvalConfigs = futures[0];
        _departments = futures[1];
        _approvalLevels = futures[2];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddConfigDialog() {
    _editingConfig = null;
    _selectedDepartmentId = null;
    _selectedApprovalLevelId = null;
    _selectedApproverPositionTypeId = null;
    _selectedSpecificApproverId = null;
    _orderIndex = 1;
    _isActive = true;

    showDialog(context: context, builder: (context) => _buildConfigDialog());
  }

  void _showEditConfigDialog(Map<String, dynamic> config) {
    _editingConfig = config;
    _selectedDepartmentId = config['departmentId'];
    _selectedApprovalLevelId = config['approvalLevelId'];
    _selectedApproverPositionTypeId = config['approverPositionTypeId'];
    _selectedSpecificApproverId = config['specificApproverId'];
    _orderIndex = config['orderIndex'] ?? 1;
    _isActive = config['isActive'] ?? true;

    showDialog(context: context, builder: (context) => _buildConfigDialog());
  }

  Widget _buildConfigDialog() {
    return AlertDialog(
      title: Text(
        _editingConfig == null ? 'Thêm cấu hình duyệt' : 'Sửa cấu hình duyệt',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedDepartmentId,
                decoration: const InputDecoration(
                  labelText: 'Phòng ban *',
                  border: OutlineInputBorder(),
                ),
                items:
                    _departments.map((dept) {
                      return DropdownMenuItem<int>(
                        value: dept['id'],
                        child: Text(dept['departmentName'] ?? 'Không có tên'),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() => _selectedDepartmentId = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn phòng ban';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedApprovalLevelId,
                decoration: const InputDecoration(
                  labelText: 'Cấp duyệt *',
                  border: OutlineInputBorder(),
                ),
                items:
                    _approvalLevels.map((level) {
                      return DropdownMenuItem<int>(
                        value: level['id'],
                        child: Text(level['levelName'] ?? 'Không có tên'),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() => _selectedApprovalLevelId = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn cấp duyệt';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _orderIndex.toString(),
                decoration: const InputDecoration(
                  labelText: 'Thứ tự duyệt *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _orderIndex = int.tryParse(value) ?? 1;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập thứ tự duyệt';
                  }
                  final order = int.tryParse(value);
                  if (order == null || order < 1) {
                    return 'Thứ tự duyệt phải là số nguyên dương';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Đang hoạt động'),
                subtitle: const Text('Cấu hình duyệt này có thể sử dụng'),
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
        ElevatedButton(onPressed: _saveConfig, child: const Text('Lưu')),
      ],
    );
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final configData = {
        'departmentId': _selectedDepartmentId,
        'approvalLevelId': _selectedApprovalLevelId,
        'approverPositionTypeId': _selectedApproverPositionTypeId,
        'specificApproverId': _selectedSpecificApproverId,
        'orderIndex': _orderIndex,
        'isActive': _isActive,
      };

      bool success;
      if (_editingConfig == null) {
        success = await authProvider.createApprovalConfig(configData);
      } else {
        success = await authProvider.updateApprovalConfig(
          _editingConfig!['id'],
          configData,
        );
      }

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _editingConfig == null
                    ? 'Thêm cấu hình duyệt thành công!'
                    : 'Cập nhật cấu hình duyệt thành công!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        }
      } else {
        throw Exception('Không thể lưu cấu hình duyệt');
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

  String _getDepartmentName(int? departmentId) {
    if (departmentId == null) return 'N/A';
    final dept = _departments.firstWhere(
      (d) => d['id'] == departmentId,
      orElse: () => {'departmentName': 'Không tìm thấy'},
    );
    return dept['departmentName'] ?? 'N/A';
  }

  String _getApprovalLevelName(int? levelId) {
    if (levelId == null) return 'N/A';
    final level = _approvalLevels.firstWhere(
      (l) => l['id'] == levelId,
      orElse: () => {'levelName': 'Không tìm thấy'},
    );
    return level['levelName'] ?? 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình quy trình duyệt'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                child:
                    _approvalConfigs.isEmpty
                        ? const Center(
                          child: Text(
                            'Chưa có cấu hình duyệt nào',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _approvalConfigs.length,
                          itemBuilder: (context, index) {
                            final config = _approvalConfigs[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      config['isActive'] == true
                                          ? Colors.blue
                                          : Colors.grey,
                                  child: Text(
                                    '${config['orderIndex'] ?? '?'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  _getApprovalLevelName(
                                    config['approvalLevelId'],
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Phòng ban: ${_getDepartmentName(config['departmentId'])}',
                                    ),
                                    Text(
                                      'Thứ tự: ${config['orderIndex'] ?? 'N/A'}',
                                    ),
                                    const SizedBox(height: 4),
                                    if (config['isActive'] == false)
                                      Chip(
                                        label: const Text('Không hoạt động'),
                                        backgroundColor: Colors.red[100],
                                        labelStyle: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditConfigDialog(config);
                                    }
                                  },
                                  itemBuilder:
                                      (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddConfigDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
