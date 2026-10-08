import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/role_redirect.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/app/shells/customer_shell.dart';
import 'package:rijiki/app/shells/customer_tab_placeholder.dart';
import 'package:rijiki/app/shells/role_home_placeholder.dart';
import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/features/auth/presentation/pages/login_page.dart';
import 'package:rijiki/features/auth/presentation/pages/register_page.dart';
import 'package:rijiki/features/auth/presentation/pages/splash_page.dart';
import 'package:rijiki/features/auth/presentation/pages/verify_email_page.dart';
import 'package:rijiki/features/home/presentation/customer/home_page.dart';
import 'package:rijiki/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:rijiki/features/order/presentation/customer/order_create_page.dart';
import 'package:rijiki/features/order/presentation/customer/order_detail_page.dart';
import 'package:rijiki/features/order/presentation/customer/order_list_page.dart';
import 'package:rijiki/features/order/presentation/customer/order_summary_page.dart';
import 'package:rijiki/features/order/presentation/customer/order_tracking_page.dart';
import 'package:rijiki/features/payment/presentation/customer/payment_result_page.dart';
import 'package:rijiki/features/payment/presentation/customer/qris_payment_page.dart';
import 'package:rijiki/features/profile/presentation/customer/profile_page.dart';
import 'package:rijiki/features/scan/presentation/customer/scan_analyzing_page.dart';
import 'package:rijiki/features/scan/presentation/customer/scan_page.dart';
import 'package:rijiki/features/scan/presentation/customer/scan_result_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AppUser?>(sessionProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refresh,
    redirect: (context, state) => RoleRedirect.guard(
      user: ref.read(sessionProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RoutePaths.verifyEmail,
        redirect: (context, state) =>
            (state.uri.queryParameters['email'] ?? '').isEmpty
            ? RoutePaths.register
            : null,
        builder: (context, state) =>
            VerifyEmailPage(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            CustomerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.customerHome,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.customerOrders,
                builder: (context, state) => const OrderListPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => OrderCreatePage(
                      initialServiceId: state.uri.queryParameters['serviceId'],
                    ),
                    routes: [
                      GoRoute(
                        path: 'summary',
                        builder: (context, state) => const OrderSummaryPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) => OrderDetailPage(
                      orderId: state.pathParameters['orderId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'tracking',
                        builder: (context, state) => OrderTrackingPage(
                          orderId: state.pathParameters['orderId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'pay',
                        builder: (context, state) => QrisPaymentPage(
                          orderId: state.pathParameters['orderId']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'result',
                            builder: (context, state) => PaymentResultPage(
                              orderId: state.pathParameters['orderId']!,
                              status:
                                  state.uri.queryParameters['status'] ??
                                  'failed',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.customerEvents,
                builder: (context, state) => const CustomerTabPlaceholder(
                  title: 'Event',
                  icon: Icons.local_activity_rounded,
                  description:
                      'Promo, event, dan poin kamu akan tampil di sini.',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.customerProfile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.customerScan,
        builder: (context, state) => const ScanPage(),
      ),
      GoRoute(
        path: RoutePaths.customerScanAnalyzing,
        builder: (context, state) => const ScanAnalyzingPage(),
      ),
      GoRoute(
        path: RoutePaths.customerScanResult,
        builder: (context, state) => const ScanResultPage(),
      ),

      GoRoute(
        path: RoutePaths.workerHome,
        builder: (context, state) => const RoleHomePlaceholder(title: 'Worker'),
      ),
      GoRoute(
        path: RoutePaths.ownerHome,
        builder: (context, state) => const RoleHomePlaceholder(title: 'Owner'),
      ),
    ],
  );
});
