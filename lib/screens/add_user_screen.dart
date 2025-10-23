import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/user_registration.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _joinDateController = TextEditingController();

  int? _selectedDepartmentId;
  int? _selectedPositionTypeId;
  List<int> _selectedRoleIds = [];
  bool _isLoading = false;
  bool _isLoadingData = true;

  List<Department> _departments = [];
  List<PositionType> _positionTypes = [];
  List<Role> _roles = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _joinDateController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load departments
      final departments = await ApiService.getDepartmentsForDropdown();
      
      // Load position types
      final positionTypes = await ApiService.getPositionTypes();
      
      // Load roles
      final roles = await ApiService.getRoles();

      if (mounted) {
        setState(() {
          _departments = departments.map((d) => Department.fromJson(d)).toList();
          _positionTypes = positionTypes.map((p) => PositionType.fromJson(p)).toList();
          _roles = roles.map((r) => Role.fromJson(r)).toList();
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: _loadInitialData,
            ),
          ),
        );
      }
    }
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate selections
    if (_selectedDepartmentId == null) {
      _showErrorSnackBar('Vui lòng chọn phòng ban');
      return;
    }

    if (_selectedPositionTypeId == null) {
      _showErrorSnackBar('Vui lòng chọn chức vụ');
      return;
    }

    if (_selectedRoleIds.isEmpty) {
      _showErrorSnackBar('Vui lòng chọn ít nhất một vai trò');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = UserRegistrationRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: _dateOfBirthController.text,
        joinDate: _joinDateController.text,
        departmentId: _selectedDepartmentId!,
        positionTypeId: _selectedPositionTypeId!,
        roleIds: _selectedRoleIds,
      );

      await ApiService.createUser(userData.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Thêm người dùng thành công'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(true); // Return success result
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Lỗi khi thêm người dùng';
        
        // Parse specific error messages
        if (e.toString().contains('email')) {
          errorMessage = 'Email đã tồn tại hoặc không hợp lệ';
        } else if (e.toString().contains('phone')) {
          errorMessage = 'Số điện thoại đã tồn tại';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Lỗi kết nối mạng. Vui lòng thử lại';
        }
        
        _showErrorSnackBar('$errorMessage: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm người dùng'),
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
          : _departments.isEmpty || _positionTypes.isEmpty || _roles.isEmpty
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
                        onPressed: _loadInitialData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin cơ bản
                    _buildSectionCard('Thông tin cơ bản', [
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Mật khẩu',
                        icon: Icons.lock,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          if (value.length < 6) {
                            return 'Mật khẩu phải có ít nhất 6 ký tự';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Họ và tên',
                        icon: Icons.badge,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập họ và tên';
                          }
                          return null;
                        },
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Thông tin liên hệ
                    _buildSectionCard('Thông tin liên hệ', [
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Số điện thoại',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
                            return 'Số điện thoại không hợp lệ';
                          }
                          return null;
                        },
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Thông tin cá nhân
                    _buildSectionCard('Thông tin cá nhân', [
                      _buildDateField(
                        controller: _dateOfBirthController,
                        label: 'Ngày sinh',
                        icon: Icons.cake,
                        onTap: () => _selectDate(_dateOfBirthController),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn ngày sinh';
                          }
                          return null;
                        },
                      ),
                      _buildDateField(
                        controller: _joinDateController,
                        label: 'Ngày vào làm',
                        icon: Icons.work,
                        onTap: () => _selectDate(_joinDateController),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn ngày vào làm';
                          }
                          return null;
                        },
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Thông tin công việc
                    _buildSectionCard('Thông tin công việc', [
                      _buildDropdownField<int>(
                        value: _selectedDepartmentId,
                        label: 'Phòng ban',
                        icon: Icons.business,
                        items: _departments.map((dept) {
                          return DropdownMenuItem<int>(
                            value: dept.id,
                            child: Text(dept.departmentName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartmentId = value;
                          });
                        },
                      ),
                      _buildDropdownField<int>(
                        value: _selectedPositionTypeId,
                        label: 'Chức vụ',
                        icon: Icons.work,
                        items: _positionTypes.map((position) {
                          return DropdownMenuItem<int>(
                            value: position.id,
                            child: Text(position.positionName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPositionTypeId = value;
                          });
                        },
                      ),
                      _buildMultiSelectField(
                        label: 'Vai trò',
                        icon: Icons.admin_panel_settings,
                        selectedItems: _selectedRoleIds,
                        allItems: _roles,
                        onChanged: (selectedIds) {
                          setState(() {
                            _selectedRoleIds = selectedIds;
                          });
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Nút thêm người dùng
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addUser,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Thêm người dùng',
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

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildMultiSelectField({
    required String label,
    required IconData icon,
    required List<int> selectedItems,
    required List<Role> allItems,
    required void Function(List<int>) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showMultiSelectDialog(allItems, selectedItems, onChanged),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[50],
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            selectedItems.isEmpty
                ? 'Chọn vai trò'
                : selectedItems
                    .map((id) => allItems.firstWhere((role) => role.id == id).roleName)
                    .join(', '),
            style: TextStyle(
              color: selectedItems.isEmpty ? Colors.grey[600] : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().split('T')[0];
    }
  }

  Future<void> _showMultiSelectDialog(
    List<Role> allItems,
    List<int> selectedItems,
    void Function(List<int>) onChanged,
  ) async {
    final List<int> tempSelected = List.from(selectedItems);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Chọn vai trò'),
              content: SingleChildScrollView(
                child: Column(
                  children: allItems.map((role) {
                    return CheckboxListTile(
                      title: Text(role.roleName),
                      value: tempSelected.contains(role.id),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            tempSelected.add(role.id);
                          } else {
                            tempSelected.remove(role.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    onChanged(tempSelected);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
