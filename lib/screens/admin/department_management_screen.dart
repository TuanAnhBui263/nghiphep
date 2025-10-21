import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  State<DepartmentManagementScreen> createState() =>
      _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState
    extends State<DepartmentManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _departments = [];
  Map<String, dynamic>? _editingDepartment;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final departments = await authProvider.getDepartments();
      setState(() => _departments = departments);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách phòng ban: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddDepartmentDialog() {
    _editingDepartment = null;
    _nameController.clear();
    _codeController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (context) => _buildDepartmentDialog(),
    );
  }

  void _showEditDepartmentDialog(Map<String, dynamic> department) {
    _editingDepartment = department;
    _nameController.text = department['departmentName'] ?? '';
    _codeController.text = department['departmentCode'] ?? '';
    _descriptionController.text = department['description'] ?? '';

    showDialog(
      context: context,
      builder: (context) => _buildDepartmentDialog(),
    );
  }

  Widget _buildDepartmentDialog() {
    return AlertDialog(
      title: Text(
        _editingDepartment == null ? 'Thêm phòng ban' : 'Sửa phòng ban',
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
                  labelText: 'Tên phòng ban *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên phòng ban';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã phòng ban *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mã phòng ban';
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(onPressed: _saveDepartment, child: const Text('Lưu')),
      ],
    );
  }

  Future<void> _saveDepartment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final departmentData = {
        'departmentName': _nameController.text,
        'departmentCode': _codeController.text,
        'description': _descriptionController.text,
      };

      bool success;
      if (_editingDepartment == null) {
        success = await authProvider.createDepartment(departmentData);
      } else {
        success = await authProvider.updateDepartment(
          _editingDepartment!['id'],
          departmentData,
        );
      }

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _editingDepartment == null
                    ? 'Thêm phòng ban thành công!'
                    : 'Cập nhật phòng ban thành công!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadDepartments();
        }
      } else {
        throw Exception('Không thể lưu phòng ban');
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
        title: const Text('Quản lý phòng ban'),
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
                  onRefresh: _loadDepartments,
                  child:
                      _departments.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.business,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có phòng ban nào',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nhấn nút + để thêm phòng ban đầu tiên',
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
                            itemCount: _departments.length,
                            itemBuilder: (context, index) {
                              final department = _departments[index];
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        department['departmentCode']
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            'D',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    department['departmentName'] ??
                                        'Không có tên',
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
                                        'Mã: ${department['departmentCode'] ?? 'N/A'}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (department['description'] != null &&
                                          department['description']
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          department['description'],
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditDepartmentDialog(department);
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
        onPressed: _showAddDepartmentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm phòng ban'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
