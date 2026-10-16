import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';

extension ScanNavigation on BuildContext {
  void closeScan() {
    if (canPop()) {
      pop();
    } else {
      go(RoutePaths.customerHome);
    }
  }
}
