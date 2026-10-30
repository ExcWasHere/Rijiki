import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/role_redirect.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/app/shells/customer_shell.dart';
import 'package:rijiki/app/shells/owner_shell.dart';
import 'package:rijiki/app/shells/worker_shell.dart';
import 'package:rijiki/features/home/worker/presentation/dashboard/worker_dashboard_page.dart';
import 'package:rijiki/features/home/worker/presentation/dashboard/worker_delivery_run_page.dart';
import 'package:rijiki/features/home/worker/presentation/dashboard/worker_order_detail_page.dart';
import 'package:rijiki/features/home/worker/presentation/dashboard/worker_orders_page.dart';
import 'package:rijiki/features/home/worker/presentation/management/worker_management_hub_page.dart';
import 'package:rijiki/features/home/worker/presentation/dashboard/worker_offline_order_page.dart';
import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/features/access_control/presentation/owner/worker_permission_page.dart';
import 'package:rijiki/features/auth/presentation/pages/login_page.dart';
import 'package:rijiki/features/auth/presentation/pages/register_page.dart';
import 'package:rijiki/features/auth/presentation/pages/splash_page.dart';
import 'package:rijiki/features/auth/presentation/pages/verify_email_page.dart';
import 'package:rijiki/features/cms/presentation/owner/cms_hub_page.dart';
import 'package:rijiki/features/cms/presentation/owner/event_form_page.dart';
import 'package:rijiki/features/cms/presentation/owner/event_manage_page.dart';
import 'package:rijiki/features/cms/presentation/owner/merchandise_form_page.dart';
import 'package:rijiki/features/cms/presentation/owner/merchandise_manage_page.dart';
import 'package:rijiki/features/cms/presentation/owner/promo_form_page.dart';
import 'package:rijiki/features/cms/presentation/owner/promo_manage_page.dart';
import 'package:rijiki/features/cms/presentation/owner/service_form_page.dart';
import 'package:rijiki/features/cms/presentation/owner/service_manage_page.dart';
import 'package:rijiki/features/event/presentation/event_page.dart';
import 'package:rijiki/features/finance/presentation/pages/expense_ai_input_page.dart';
import 'package:rijiki/features/finance/presentation/pages/expense_draft_review_page.dart';
import 'package:rijiki/features/finance/presentation/pages/finance_page.dart';
import 'package:rijiki/features/finance/presentation/pages/income_form_page.dart';
import 'package:rijiki/features/finance/presentation/pages/transaction_list_page.dart';
import 'package:rijiki/features/home/owner/presentation/management/dashboard_page.dart';
import 'package:rijiki/features/home/owner/presentation/management/repeat_customer_page.dart';
import 'package:rijiki/features/home/customer/home_page.dart';
import 'package:rijiki/features/home/owner/presentation/management/presentation/pages/management_hub_page.dart';
import 'package:rijiki/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:rijiki/features/order/presentation/customer/delivery_map_page.dart';
import 'package:rijiki/features/order/presentation/customer/order_create_page.dart';
import 'package:rijiki/features/order/presentation/customer/order_detail_page.dart';
import 'package:rijiki/features/order/presentation/customer/order_list_page.dart';
import 'package:rijiki/features/order/presentation/customer/order_summary_page.dart';
import 'package:rijiki/features/order/presentation/customer/order_tracking_page.dart';
import 'package:rijiki/features/order/presentation/customer/receipt_page.dart';
import 'package:rijiki/features/payment/presentation/customer/payment_result_page.dart';
import 'package:rijiki/features/payment/presentation/customer/qris_payment_page.dart';
import 'package:rijiki/features/profile/presentation/customer/profile_page.dart';
import 'package:rijiki/features/profile/presentation/owner/owner_profile_page.dart';
import 'package:rijiki/features/profile/presentation/shared/account_security_page.dart';
import 'package:rijiki/features/profile/presentation/shared/change_email_page.dart';
import 'package:rijiki/features/profile/presentation/shared/change_password_page.dart';
import 'package:rijiki/features/profile/presentation/shared/edit_profile_page.dart';
import 'package:rijiki/features/profile/presentation/worker/worker_profile_page.dart';
import 'package:rijiki/features/scan/presentation/customer/scan_analyzing_page.dart';
import 'package:rijiki/features/scan/presentation/customer/scan_page.dart';
import 'package:rijiki/features/scan/presentation/customer/scan_result_page.dart';
import 'package:rijiki/features/landing/presentation/pages/landing_page.dart';
import 'package:rijiki/features/worker_management/domain/kpi.dart';
import 'package:rijiki/features/worker_management/presentation/owner/kpi_assessment_page.dart';
import 'package:rijiki/features/worker_management/presentation/owner/kpi_overview_page.dart';
import 'package:rijiki/features/worker_management/presentation/owner/worker_detail_page.dart';
import 'package:rijiki/features/worker_management/presentation/owner/worker_form_page.dart';
import 'package:rijiki/features/worker_management/presentation/owner/worker_list_page.dart';

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
        path: RoutePaths.landing,
        builder: (context, state) => const LandingPage(),
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
      GoRoute(
        path: RoutePaths.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
            GoRoute(
        path: RoutePaths.accountSecurity,
        builder: (context, state) => const AccountSecurityPage(),
        routes: [
          GoRoute(
            path: 'password',
            builder: (context, state) => const ChangePasswordPage(),
          ),
          GoRoute(
            path: 'email',
            builder: (context, state) => const ChangeEmailPage(),
          ),
        ],
      ),

      // Cust
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
                        path: 'receipt',
                        builder: (context, state) => ReceiptPage(
                          orderId: state.pathParameters['orderId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'map',
                        builder: (context, state) => DeliveryMapPage(
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
                builder: (context, state) => const EventPage(),
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

      // Worker
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            WorkerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.workerHome,
                builder: (context, state) => const WorkerDashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.workerOrders,
                builder: (context, state) => const WorkerOrdersPage(),
                routes: [
                  GoRoute(
                    path: 'offline/new',
                    builder: (context, state) => const WorkerOfflineOrderPage(),
                  ),

                  GoRoute(
                    path: 'delivery',
                    builder: (context, state) => const WorkerDeliveryRunPage(),
                  ),

                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) => WorkerOrderDetailPage(
                      orderId: state.pathParameters['orderId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.workerManagement,
                builder: (context, state) => const WorkerManagementHubPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.workerProfile,
                builder: (context, state) => const WorkerProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // Owner
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            OwnerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ownerHome,
                builder: (context, state) => const DashboardPage(),
                routes: [
                  GoRoute(
                    path: 'repeat-customers',
                    builder: (context, state) => const RepeatCustomerPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ownerOrders,
                builder: (context, state) => const WorkerOrdersPage(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    builder: (context, state) => WorkerOrderDetailPage(
                      orderId: state.pathParameters['orderId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.ownerManagement,
                builder: (context, state) => const ManagementHubPage(),
                routes: [
                  GoRoute(
                    path: 'finance',
                    builder: (context, state) => const FinancePage(),
                    routes: [
                      GoRoute(
                        path: 'transactions',
                        builder: (context, state) =>
                            const TransactionListPage(),
                      ),
                      GoRoute(
                        path: 'expenses/ai',
                        builder: (context, state) => const ExpenseAiInputPage(),
                        routes: [
                          GoRoute(
                            path: 'review',
                            builder: (context, state) =>
                                const ExpenseDraftReviewPage(),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'income/new',
                        builder: (context, state) => const IncomeFormPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'repeat-customers',
                    builder: (context, state) => const RepeatCustomerPage(),
                  ),
                  GoRoute(
                    path: 'workers',
                    builder: (context, state) => const WorkerListPage(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (context, state) => const WorkerFormPage(),
                      ),
                      GoRoute(
                        path: 'kpi',
                        builder: (context, state) => const KpiOverviewPage(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => WorkerDetailPage(
                          workerId: state.pathParameters['id']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'edit',
                            builder: (context, state) => WorkerFormPage(
                              workerId: state.pathParameters['id']!,
                            ),
                          ),
                          GoRoute(
                            path: 'kpi',
                            builder: (context, state) {
                              final now = KpiPeriod.current();
                              final month =
                                  int.tryParse(
                                    state.uri.queryParameters['month'] ?? '',
                                  ) ??
                                  now.month;
                              final year =
                                  int.tryParse(
                                    state.uri.queryParameters['year'] ?? '',
                                  ) ??
                                  now.year;
                              return KpiAssessmentPage(
                                workerId: state.pathParameters['id']!,
                                period: KpiPeriod(
                                  month.clamp(1, 12).toInt(),
                                  year,
                                ),
                              );
                            },
                          ),
                          GoRoute(
                            path: 'access',
                            builder: (context, state) => WorkerPermissionPage(
                              workerId: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'cms',
                    builder: (context, state) => const CmsHubPage(),
                    routes: [
                      GoRoute(
                        path: 'services',
                        builder: (context, state) => const ServiceManagePage(),
                        routes: [
                          GoRoute(
                            path: 'new',
                            builder: (context, state) =>
                                const ServiceFormPage(),
                          ),
                          GoRoute(
                            path: ':id/edit',
                            builder: (context, state) => ServiceFormPage(
                              serviceId: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'events',
                        builder: (context, state) => const EventManagePage(),
                        routes: [
                          GoRoute(
                            path: 'new',
                            builder: (context, state) => const EventFormPage(),
                          ),
                          GoRoute(
                            path: ':id/edit',
                            builder: (context, state) => EventFormPage(
                              eventId: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'promos',
                        builder: (context, state) => const PromoManagePage(),
                        routes: [
                          GoRoute(
                            path: 'new',
                            builder: (context, state) => const PromoFormPage(),
                          ),
                          GoRoute(
                            path: ':id/edit',
                            builder: (context, state) => PromoFormPage(
                              promoId: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'merchandise',
                        builder: (context, state) =>
                            const MerchandiseManagePage(),
                        routes: [
                          GoRoute(
                            path: 'new',
                            builder: (context, state) =>
                                const MerchandiseFormPage(),
                          ),
                          GoRoute(
                            path: ':id/edit',
                            builder: (context, state) => MerchandiseFormPage(
                              merchandiseId: state.pathParameters['id']!,
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
                path: RoutePaths.ownerProfile,
                builder: (context, state) => const OwnerProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});