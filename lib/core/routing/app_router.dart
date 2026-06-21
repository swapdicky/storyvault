import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/recording/presentation/screens/record_screen.dart';
import '../../features/timeline/presentation/screens/timeline_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.splashRoute,
    redirect: (context, state) {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final isSplashScreen = state.matchedLocation == AppConstants.splashRoute;
      final isLoginScreen = state.matchedLocation == AppConstants.loginRoute;
      
      // If on splash screen, let it handle the redirect
      if (isSplashScreen) return null;
      
      // If not authenticated and not on login screen, redirect to login
      if (!isAuthenticated && !isLoginScreen) {
        return AppConstants.loginRoute;
      }
      
      // If authenticated and on login screen, redirect to home
      if (isAuthenticated && isLoginScreen) {
        return AppConstants.homeRoute;
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.splashRoute,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.loginRoute,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.homeRoute,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppConstants.recordRoute,
        name: 'record',
        builder: (context, state) => const RecordScreen(),
      ),
      GoRoute(
        path: AppConstants.timelineRoute,
        name: 'timeline',
        builder: (context, state) => const TimelineScreen(),
      ),
      GoRoute(
        path: AppConstants.profileRoute,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
