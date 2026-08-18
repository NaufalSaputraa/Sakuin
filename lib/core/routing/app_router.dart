import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/home/presentation/widgets/main_scaffold.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/chat/presentation/ai_chat_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/wallets/presentation/wallets_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String analytics = '/analytics';
  static const String chat = '/chat';
  static const String onboarding = '/onboarding';
  static const String settings = '/settings';
  static const String categories = '/categories';
  static const String wallets = '/wallets';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final isDone = prefs.getBool(AppConstants.hasCompletedOnboardingKey) ?? false;

    final isOnboarding = state.uri.path == AppRoutes.onboarding;

    if (!isDone && !isOnboarding) {
      return AppRoutes.onboarding;
    }

    if (isDone && isOnboarding) {
      return AppRoutes.home;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.categories,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: AppRoutes.wallets,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WalletsScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.analytics,
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: AppRoutes.chat,
          builder: (context, state) => const AiChatScreen(),
        ),
      ],
    ),
  ],
);
