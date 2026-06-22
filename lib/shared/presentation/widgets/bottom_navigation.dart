import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';

final currentRouteProvider = Provider<String>((ref) {
  return AppConstants.homeRoute;
});

class BottomNavigation extends ConsumerWidget {
  const BottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = ref.watch(currentRouteProvider);
    final location = GoRouterState.of(context).uri.path;

    return NavigationBar(
      selectedIndex: _getSelectedIndex(location),
      onDestinationSelected: (index) {
        _onDestinationSelected(context, index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.mic),
          label: 'Record',
        ),
        NavigationDestination(
          icon: Icon(Icons.timeline),
          label: 'Timeline',
        ),
        NavigationDestination(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  int _getSelectedIndex(String location) {
    switch (location) {
      case AppConstants.homeRoute:
        return 0;
      case AppConstants.recordRoute:
        return 1;
      case AppConstants.timelineRoute:
        return 2;
      case AppConstants.profileRoute:
        return 3;
      default:
        return 0;
    }
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppConstants.homeRoute);
        break;
      case 1:
        context.go(AppConstants.recordRoute);
        break;
      case 2:
        context.go(AppConstants.timelineRoute);
        break;
      case 3:
        context.go(AppConstants.profileRoute);
        break;
    }
  }
}
