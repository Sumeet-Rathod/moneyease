import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/notifications/notifications_provider.dart';

class AppNavShell extends ConsumerWidget {
  final Widget child;

  const AppNavShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final notifState = ref.watch(notificationsProvider);
    final user = authState.user;
    final role = user?.role ?? 'customer';

    final String location = GoRouterState.of(context).matchedLocation;

    if (role == 'executive' || role == 'admin') {
      return _buildStaffShell(context, ref, role, location, notifState.unreadCount);
    }
    return _buildCustomerShell(context, ref, location, notifState.unreadCount);
  }

  Widget _buildCustomerShell(BuildContext context, WidgetRef ref, String location, int unreadCount) {
    int currentIndex = 0;
    if (location.startsWith('/goals/visualizer')) {
      currentIndex = 1;
    } else if (location.startsWith('/goals')) {
      currentIndex = 0;
    } else if (location.startsWith('/doubts')) {
      currentIndex = 2;
    } else if (location.startsWith('/risk')) {
      currentIndex = 3;
    } else if (location.startsWith('/profile') || location.startsWith('/notifications')) {
      currentIndex = 4;
    }

    final isWide = MediaQuery.of(context).size.width >= 768;

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.savings_outlined),
        selectedIcon: Icon(Icons.savings),
        label: "Goals",
      ),
      const NavigationDestination(
        icon: Icon(Icons.auto_graph_outlined),
        selectedIcon: Icon(Icons.auto_graph),
        label: "Visualizer",
      ),
      const NavigationDestination(
        icon: Icon(Icons.psychology_outlined),
        selectedIcon: Icon(Icons.psychology),
        label: "Doubts",
      ),
      const NavigationDestination(
        icon: Icon(Icons.speed_outlined),
        selectedIcon: Icon(Icons.speed),
        label: "Risk",
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: unreadCount > 0,
          label: Text('$unreadCount'),
          child: const Icon(Icons.person_outline),
        ),
        selectedIcon: Badge(
          isLabelVisible: unreadCount > 0,
          label: Text('$unreadCount'),
          child: const Icon(Icons.person),
        ),
        label: "Profile",
      ),
    ];

    void onDestinationSelected(int idx) {
      switch (idx) {
        case 0:
          context.go('/goals');
          break;
        case 1:
          context.go('/goals/visualizer');
          break;
        case 2:
          context.go('/doubts');
          break;
        case 3:
          context.go('/risk');
          break;
        case 4:
          context.go('/profile');
          break;
      }
    }

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: AppTheme.primaryTeal),
              selectedLabelTextStyle: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Icon(Icons.account_balance, color: AppTheme.primaryTeal, size: 32),
              ),
              destinations: destinations.map((d) {
                return NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                );
              }).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );
  }

  Widget _buildStaffShell(BuildContext context, WidgetRef ref, String role, String location, int unreadCount) {
    int currentIndex = 0;
    if (location.startsWith('/admin')) {
      currentIndex = 1;
    } else if (location.startsWith('/notifications')) {
      currentIndex = role == 'admin' ? 2 : 1;
    } else if (location.startsWith('/profile')) {
      currentIndex = role == 'admin' ? 3 : 2;
    } else if (location.startsWith('/exec')) {
      currentIndex = 0;
    }

    final isWide = MediaQuery.of(context).size.width >= 768;

    final List<NavigationDestination> destinations = [
      const NavigationDestination(
        icon: Icon(Icons.table_chart_outlined),
        selectedIcon: Icon(Icons.table_chart),
        label: "Leads",
      ),
      if (role == 'admin')
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: "Admin Portal",
        ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: unreadCount > 0,
          label: Text('$unreadCount'),
          child: const Icon(Icons.notifications_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: unreadCount > 0,
          label: Text('$unreadCount'),
          child: const Icon(Icons.notifications),
        ),
        label: "Alerts",
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: "Profile",
      ),
    ];

    void onDestinationSelected(int idx) {
      if (role == 'admin') {
        switch (idx) {
          case 0:
            context.go('/exec');
            break;
          case 1:
            context.go('/admin');
            break;
          case 2:
            context.go('/notifications');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      } else {
        switch (idx) {
          case 0:
            context.go('/exec');
            break;
          case 1:
            context.go('/notifications');
            break;
          case 2:
            context.go('/profile');
            break;
        }
      }
    }

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: AppTheme.primaryTeal),
              selectedLabelTextStyle: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Icon(Icons.business_center, color: AppTheme.primaryTeal, size: 32),
              ),
              destinations: destinations.map((d) {
                return NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                );
              }).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}
