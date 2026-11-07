import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/points/domain/point_rule.dart';
import 'package:rijiki/features/points/domain/point_rule_repository.dart';

class MockPointRuleRepository implements PointRuleRepository {
  MockPointRuleRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  static const Duration _writeLatency = Duration(milliseconds: 450);

  late final List<PointRule> _rules = [
    const PointRule(
      id: 'rule-1',
      source: PointRuleSource.orderCompleted,
      calculationType: PointCalculationType.fixed,
      pointsValue: 100,
    ),
    const PointRule(
      id: 'rule-2',
      source: PointRuleSource.giveRating,
      calculationType: PointCalculationType.fixed,
      pointsValue: 20,
    ),
  ];

  @override
  Future<List<PointRule>> fetchRules() {
    return scenario.resolve<List<PointRule>>(
      empty: const [],
      data: List.of(_rules),
    );
  }

  @override
  Future<PointRule> updateRule(String id, PointRuleInput input) async {
    await Future<void>.delayed(_writeLatency);
    if (scenario == MockScenario.error) throw const MockException();
    final index = _rules.indexWhere((r) => r.id == id);
    if (index == -1) throw const MockException('Aturan poin tidak ditemukan');
    final updated = _rules[index].copyWith(
      pointsValue: input.pointsValue,
      amountUnit: input.amountUnit,
    );
    _rules[index] = updated;
    return updated;
  }
}
