import 'package:rijiki/features/points/domain/point_rule.dart';

abstract interface class PointRuleRepository {
  Future<List<PointRule>> fetchRules();

  Future<PointRule> updateRule(String id, PointRuleInput input);
}
