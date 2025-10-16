import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import 'employee/employee_dashboard.dart';
import 'manager/manager_dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authProvider.isLoggedIn) {
          return const LoginScreen();
        }

        final user = authProvider.currentUser!;

        // Hiển thị dashboard theo vai trò
        switch (user.role) {
          case UserRole.employee:
            return const EmployeeDashboard();
          case UserRole.teamLeader:
          case UserRole.deputyLeader:
            return const ManagerDashboard();
          case UserRole.admin:
            return const AdminDashboard();
        }
      },
    );
  }
}
