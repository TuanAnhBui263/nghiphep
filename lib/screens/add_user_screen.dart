import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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

  String _selectedRole = 'Employee';
  String _selectedDepartment = 'Phòng Hành Chính';
  bool _isLoading = false;

  final List<String> _departments = [
    'Phòng Hành Chính',
    'Phòng Kế Toán',
    'Ban Giám Đốc - Trưởng Thuế TP.HCM',
    'Ban Giám Đốc - Phó Trưởng Thuế TP.HCM',
  ];

  final List<String> _roles = ['Employee', 'Manager', 'Admin'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final userData = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'fullName': _fullNameController.text,
        'phoneNumber': _phoneController.text,
        'role': _selectedRole,
        'department': _selectedDepartment,
        'isActive': true,
      };

      await authProvider.createUser(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm người dùng thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm người dùng: ${e.toString()}'),
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
        title: const Text('Thêm người dùng'),
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

              // Thông tin công việc
              _buildSectionCard('Thông tin công việc', [
                _buildDropdownField(
                  value: _selectedRole,
                  label: 'Vai trò',
                  icon: Icons.work,
                  items:
                      _roles.map((role) {
                        String displayName;
                        switch (role) {
                          case 'Employee':
                            displayName = 'Nhân viên';
                            break;
                          case 'Manager':
                            displayName = 'Quản lý';
                            break;
                          case 'Admin':
                            displayName = 'Admin';
                            break;
                          default:
                            displayName = role;
                        }
                        return DropdownMenuItem(
                          value: role,
                          child: Text(displayName),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
                _buildDropdownField(
                  value: _selectedDepartment,
                  label: 'Phòng ban',
                  icon: Icons.business,
                  items:
                      _departments.map((dept) {
                        return DropdownMenuItem(value: dept, child: Text(dept));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value!;
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
                  child:
                      _isLoading
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

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
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
}
