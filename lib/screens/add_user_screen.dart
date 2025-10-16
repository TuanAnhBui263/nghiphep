import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _workYearsController = TextEditingController();

  UserRole _selectedRole = UserRole.employee;
  String? _selectedManagerId;
  bool _isLoading = false;

  final List<String> _departments = [
    'IT',
    'Nhân sự',
    'Kế toán',
    'Marketing',
    'Kinh doanh',
    'Sản xuất',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _workYearsController.dispose();
    super.dispose();
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final workYears = int.parse(_workYearsController.text);
      final annualLeaveDays = User.calculateAnnualLeaveDays(workYears);

      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: _usernameController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        department: _departmentController.text,
        role: _selectedRole,
        workYears: workYears,
        annualLeaveDays: annualLeaveDays,
        remainingLeaveDays: annualLeaveDays,
        managerId: _selectedManagerId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await authProvider.createUser(newUser);

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
                  controller: _usernameController,
                  label: 'Tên đăng nhập',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên đăng nhập';
                    }
                    if (value.length < 3) {
                      return 'Tên đăng nhập phải có ít nhất 3 ký tự';
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
                _buildDropdownField<String>(
                  label: 'Phòng ban',
                  value:
                      _departmentController.text.isEmpty
                          ? null
                          : _departmentController.text,
                  items: _departments,
                  onChanged: (value) {
                    setState(() {
                      _departmentController.text = value!;
                    });
                  },
                  itemBuilder: (dept) => Text(dept),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng chọn phòng ban';
                    }
                    return null;
                  },
                ),
                _buildDropdownField(
                  label: 'Vai trò',
                  value: _selectedRole,
                  items: UserRole.values,
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                  itemBuilder: (role) {
                    String label;
                    switch (role) {
                      case UserRole.employee:
                        label = 'Nhân viên';
                        break;
                      case UserRole.teamLeader:
                        label = 'Trưởng phòng';
                        break;
                      case UserRole.deputyLeader:
                        label = 'Phó phòng';
                        break;
                      case UserRole.admin:
                        label = 'Admin';
                        break;
                    }
                    return Text(label);
                  },
                ),
                _buildTextField(
                  controller: _workYearsController,
                  label: 'Số năm công tác',
                  icon: Icons.work,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số năm công tác';
                    }
                    final years = int.tryParse(value);
                    if (years == null || years < 0) {
                      return 'Số năm công tác phải là số dương';
                    }
                    return null;
                  },
                ),
                _buildManagerDropdown(),
              ]),
              const SizedBox(height: 24),

              // Nút thêm
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
                          ? const CircularProgressIndicator(color: Colors.white)
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
      elevation: 4,
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
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required Widget Function(T) itemBuilder,
    String? Function(T?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        items:
            items.map((item) {
              return DropdownMenuItem(value: item, child: itemBuilder(item));
            }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildManagerDropdown() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final managers =
            authProvider
                .getAllUsers()
                .where(
                  (user) =>
                      user.role == UserRole.teamLeader ||
                      user.role == UserRole.deputyLeader,
                )
                .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<String>(
            value: _selectedManagerId,
            decoration: InputDecoration(
              labelText: 'Người quản lý trực tiếp',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Không có')),
              ...managers.map((manager) {
                return DropdownMenuItem(
                  value: manager.id,
                  child: Text(manager.fullName),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedManagerId = value;
              });
            },
          ),
        );
      },
    );
  }
}
