import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        debugPrint('DashboardScreen: User roles: ${user.roles}');

        // Hiển thị dashboard theo vai trò
        if (user.roles.contains('Admin')) {
          debugPrint('DashboardScreen: Routing to AdminDashboard');
          return const AdminDashboard();
        } else if (user.roles.contains('Manager')) {
          debugPrint('DashboardScreen: Routing to ManagerDashboard');
          return const ManagerDashboard();
        } else {
          debugPrint('DashboardScreen: Routing to EmployeeDashboard');
          return const EmployeeDashboard();
        }
      },
    );
  }
}
