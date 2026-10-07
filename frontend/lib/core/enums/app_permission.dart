enum AppPermission {
  manageOrdersAll('manage_orders_all'),
  manageCmsServices('manage_cms_services'),
  manageCmsEvents('manage_cms_events'),
  manageCmsPromos('manage_cms_promos'),
  manageCmsMerchandise('manage_cms_merchandise'),
  manageTestimonials('manage_testimonials'),
  manageFinance('manage_finance'),
  manageWorkers('manage_workers'),
  managePoints('manage_points'),
  viewAnalytics('view_analytics');

  const AppPermission(this.value);

  final String value;
  static AppPermission? tryParse(String value) {
    for (final permission in AppPermission.values) {
      if (permission.value == value) return permission;
    }
    return null;
  }
}
