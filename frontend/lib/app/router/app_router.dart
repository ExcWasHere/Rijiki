import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/role_redirect.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/app/shells/customer_shell.dart';
import 'package:rijiki/app/shells/owner_shell.dart';
import 'package:rijiki/app/shells/worker_shell.dart';
import 'package:rijiki/features/worker_dashboard/presentation/pages/worker_dashboard_page.dart';
import 'package:rijiki/features/order/presentation/pages/worker/worker_delivery_run_page.dart';
import 'package:rijiki/features/order/presentation/pages/worker/worker_order_detail_page.dart';
import 'package:rijiki/features/order/presentation/pages/worker/worker_orders_page.dart';
import 'package:rijiki/features/management/presentation/pages/worker_management_hub_page.dart';
import 'package:rijiki/features/order/presentation/pages/worker/worker_offline_order_page.dart';
import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/features/access_control/presentation/pages/owner/worker_permission_page.dart';
import 'package:rijiki/features/auth/presentation/pages/login_page.dart';
import 'package:rijiki/features/auth/presentation/pages/register_page.dart';
import 'package:rijiki/features/auth/presentation/pages/splash_page.dart';
import 'package:rijiki/features/auth/presentation/pages/verify_email_page.dart';
import 'package:rijiki/features/chat/presentation/pages/order_chat_page.dart';
import 'package:rijiki/features/management/presentation/pages/cms_hub_page.dart';
import 'package:rijiki/features/event/presentation/pages/owner/event_form_page.dart';
import 'package:rijiki/features/event/presentation/pages/owner/event_manage_page.dart';
import 'package:rijiki/features/merchandise/presentation/pages/owner/merchandise_form_page.dart';
import 'package:rijiki/features/merchandise/presentation/pages/owner/merchandise_manage_page.dart';
import 'package:rijiki/features/points/presentation/pages/owner/point_rule_page.dart';
import 'package:rijiki/features/event/presentation/pages/owner/promo_form_page.dart';
import 'package:rijiki/features/event/presentation/pages/owner/promo_manage_page.dart';
import 'package:rijiki/features/service/presentation/pages/owner/service_form_page.dart';
import 'package:rijiki/features/service/presentation/pages/owner/service_manage_page.dart';
import 'package:rijiki/features/rating/presentation/pages/owner/testimonial_manage_page.dart';
import 'package:rijiki/features/event/presentation/pages/customer/event_page.dart';
import 'package:rijiki/features/finance/presentation/pages/owner/expense_ai_input_page.dart';
import 'package:rijiki/features/finance/presentation/pages/owner/expense_draft_review_page.dart';
import 'package:rijiki/features/finance/presentation/pages/owner/finance_page.dart';
import 'package:rijiki/features/finance/presentation/pages/owner/income_form_page.dart';
import 'package:rijiki/features/finance/presentation/pages/owner/transaction_list_page.dart';
import 'package:rijiki/features/service/presentation/pages/customer/service_list_page.dart';
import 'package:rijiki/features/owner_dashboard/presentation/pages/dashboard_page.dart';
import 'package:rijiki/features/owner_dashboard/presentation/pages/repeat_customer_page.dart';
import 'package:rijiki/features/home/presentation/pages/home_page.dart';
import 'package:rijiki/features/management/presentation/pages/management_hub_page.dart';
import 'package:rijiki/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:rijiki/features/order/presentation/pages/customer/delivery_map_page.dart';
import 'package:rijiki/features/order/presentation/pages/customer/order_create_page.dart';
import 'package:rijiki/features/order/presentation/pages/customer/order_detail_page.dart';
import 'package:rijiki/features/order/presentation/pages/customer/order_list_page.dart';
import 'package:rijiki/features/order/presentation/pages/customer/order_summary_page.dart';
import 'package:rijiki/features/order/presentation/pages/customer/order_tracking_page.dart';
import 'package:rijiki/features/order/presentation/pages/customer/receipt_page.dart';
import 'package:rijiki/features/payment/presentation/pages/customer/payment_result_page.dart';
import 'package:rijiki/features/payment/presentation/pages/customer/qris_payment_page.dart';
import 'package:rijiki/features/points/presentation/pages/owner/point_adjust_page.dart';
import 'package:rijiki/features/points/presentation/pages/owner/points_hub_page.dart';
import 'package:rijiki/features/points/presentation/pages/owner/redemption_manage_page.dart';
import 'package:rijiki/features/help/presentation/pages/help_center_page.dart';
import 'package:rijiki/features/help/presentation/pages/terms_page.dart';
import 'package:rijiki/features/notifications/presentation/pages/notifications_page.dart';
import 'package:rijiki/features/profile/presentation/pages/customer/my_ratings_page.dart';
import 'package:rijiki/features/profile/presentation/pages/customer/my_shoes_page.dart';
import 'package:rijiki/features/profile/presentation/pages/customer/profile_page.dart';
import 'package:rijiki/features/profile/presentation/pages/owner/owner_profile_page.dart';
import 'package:rijiki/features/profile/presentation/pages/shared/account_security_page.dart';
import 'package:rijiki/features/profile/presentation/pages/shared/change_email_page.dart';
import 'package:rijiki/features/profile/presentation/pages/shared/change_password_page.dart';
import 'package:rijiki/features/profile/presentation/pages/shared/edit_profile_page.dart';
import 'package:rijiki/features/profile/presentation/pages/worker/worker_profile_page.dart';
import 'package:rijiki/features/rating/presentation/pages/customer/rating_page.dart';
import 'package:rijiki/features/scan/presentation/pages/customer/scan_analyzing_page.dart';
import 'package:rijiki/features/scan/presentation/pages/customer/scan_page.dart';
import 'package:rijiki/features/scan/presentation/pages/customer/scan_result_page.dart';
import 'package:rijiki/features/landing/presentation/pages/landing_page.dart';
import 'package:rijiki/features/worker_management/domain/kpi.dart';
import 'package:rijiki/features/worker_management/presentation/pages/owner/kpi_assessment_page.dart';
import 'package:rijiki/features/worker_management/presentation/pages/owner/kpi_overview_page.dart';
import 'package:rijiki/features/worker_management/presentation/pages/owner/worker_detail_page.dart';
import 'package:rijiki/features/worker_management/presentation/pages/owner/worker_form_page.dart';
import 'package:rijiki/features/worker_management/presentation/pages/owner/worker_list_page.dart';
import 'package:rijiki/features/payment/presentation/pages/worker/worker_qris_payment_page.dart';
import 'package:rijiki/features/points/presentation/pages/customer/point_history_page.dart';

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
        path: RoutePaths.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: RoutePaths.myShoes,
        builder: (context, state) => const MyShoesPage(),
      ),
      GoRoute(
        path: RoutePaths.myRatings,
        builder: (context, state) => const MyRatingsPage(),
      ),
      GoRoute(
        path: RoutePaths.helpCenter,
        builder: (context, state) => const HelpCenterPage(),
      ),
      GoRoute(
        path: RoutePaths.terms,
        builder: (context, state) => const TermsPage(),
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

      GoRoute(
        path: RoutePaths.ownerWorkers,
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
            builder: (context, state) =>
                WorkerDetailPage(workerId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    WorkerFormPage(workerId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'kpi',
                builder: (context, state) {
                  final now = KpiPeriod.current();
                  final month =
                      int.tryParse(state.uri.queryParameters['month'] ?? '') ??
                      now.month;
                  final year =
                      int.tryParse(state.uri.queryParameters['year'] ?? '') ??
                      now.year;
                  return KpiAssessmentPage(
                    workerId: state.pathParameters['id']!,
                    period: KpiPeriod(month.clamp(1, 12).toInt(), year),
                  );
                },
              ),
              GoRoute(
                path: 'access',
                builder: (context, state) =>
                    WorkerPermissionPage(workerId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.managementRepeatCustomers,
        builder: (context, state) => const RepeatCustomerPage(),
      ),
      GoRoute(
        path: RoutePaths.managementPoints,
        builder: (context, state) => const PointsHubPage(),
        routes: [
          GoRoute(
            path: 'redemptions',
            builder: (context, state) => const RedemptionManagePage(),
          ),
          GoRoute(
            path: 'adjust',
            builder: (context, state) => const PointAdjustPage(),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.ownerCms,
        builder: (context, state) => const CmsHubPage(),
        routes: [
          GoRoute(
            path: 'services',
            builder: (context, state) => const ServiceManagePage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ServiceFormPage(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) =>
                    ServiceFormPage(serviceId: state.pathParameters['id']!),
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
                builder: (context, state) =>
                    EventFormPage(eventId: state.pathParameters['id']!),
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
                builder: (context, state) =>
                    PromoFormPage(promoId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: 'merchandise',
            builder: (context, state) => const MerchandiseManagePage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const MerchandiseFormPage(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) => MerchandiseFormPage(
                  merchandiseId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'points',
            builder: (context, state) => const PointRulePage(),
          ),
          GoRoute(
            path: 'testimonials',
            builder: (context, state) => const TestimonialManagePage(),
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
                routes: [
                  GoRoute(
                    path: 'services',
                    builder: (context, state) => const ServiceListPage(),
                  ),
                ],
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
                        path: 'rating',
                        builder: (context, state) => RatingPage(
                          orderId: state.pathParameters['orderId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'chat',
                        builder: (context, state) => OrderChatPage(
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
                routes: [
                  GoRoute(
                    path: 'points',
                    builder: (context, state) => const PointHistoryPage(),
                  ),
                ],
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
                    routes: [
                      GoRoute(
                        path: 'pay',
                        builder: (context, state) => WorkerQrisPaymentPage(
                          orderId: state.pathParameters['orderId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'chat',
                        builder: (context, state) => OrderChatPage(
                          orderId: state.pathParameters['orderId']!,
                        ),
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
                    routes: [
                      GoRoute(
                        path: 'pay',
                        builder: (context, state) => WorkerQrisPaymentPage(
                          orderId: state.pathParameters['orderId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'chat',
                        builder: (context, state) => OrderChatPage(
                          orderId: state.pathParameters['orderId']!,
                        ),
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
