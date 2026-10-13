import 'package:rijiki/core/enums/expense_type.dart';
import 'package:rijiki/features/finance/domain/finance_repository.dart';
import 'package:rijiki/features/finance/domain/finance_summary.dart';
import 'package:rijiki/features/finance/domain/financial_transaction.dart';
import 'package:rijiki/features/finance/domain/transaction_filter.dart';
import 'package:rijiki/features/home/owner/domain/dashboard_repository.dart';
import 'package:rijiki/features/home/owner/domain/dashboard_summary.dart';

class MockFinanceRepository implements FinanceRepository {
  MockFinanceRepository({required DashboardRepository dashboard})
    : _dashboard = dashboard;

  static const Duration _latency = Duration(milliseconds: 350);

  final DashboardRepository _dashboard;
  late final List<FinancialTransaction> _transactions = _seed();

  @override
  Future<FinanceSummary> fetchSummary(FinancePeriod period) async {
    final base = await _dashboard.fetchSummary(_toDashboard(period));

    return FinanceSummary(
      period: period,
      income: base.income,
      expense: base.expense,
      previousIncome: base.previousIncome,
      series: [
        for (final point in base.series)
          FinancePoint(label: point.label, amount: point.amount),
      ],
      expenseByType: _splitExpense(base.expense),
    );
  }

  @override
  Future<List<FinancialTransaction>> fetchTransactions(
    TransactionFilter filter,
  ) async {
    await Future<void>.delayed(_latency);

    final result = _transactions.where((t) {
      switch (filter.type) {
        case TransactionTypeFilter.all:
          break;
        case TransactionTypeFilter.income:
          if (!t.isIncome) return false;
        case TransactionTypeFilter.expense:
          if (!t.isExpense) return false;
          if (filter.expenseType != null &&
              t.expenseType != filter.expenseType) {
            return false;
          }
      }
      if (filter.hasRange) {
        final day = _dateOnly(t.transactionDate);
        if (day.isBefore(_dateOnly(filter.start!))) return false;
        if (day.isAfter(_dateOnly(filter.end!))) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return result;
  }

  DashboardPeriod _toDashboard(FinancePeriod period) => switch (period) {
    FinancePeriod.today => DashboardPeriod.today,
    FinancePeriod.week => DashboardPeriod.week,
    FinancePeriod.month => DashboardPeriod.month,
  };

  Map<ExpenseType, double> _splitExpense(double total) {
    final material = (total * 0.46).roundToDouble();
    final equipment = (total * 0.14).roundToDouble();
    final service = (total * 0.12).roundToDouble();
    final other = total - material - equipment - service;

    return {
      ExpenseType.material: material,
      ExpenseType.equipment: equipment,
      ExpenseType.externalService: service,
      ExpenseType.other: other,
    };
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static List<FinancialTransaction> _seed() {
    final now = DateTime.now();

    DateTime at(int daysAgo, int hour, [int minute = 0]) =>
        DateTime(now.year, now.month, now.day - daysAgo, hour, minute);

    FinancialTransaction income(
      String id,
      int daysAgo,
      int hour,
      String orderNo,
      String customer,
      double amount,
    ) {
      return FinancialTransaction(
        id: id,
        type: TransactionType.income,
        category: 'order_payment',
        itemName: 'Pembayaran order $orderNo',
        description: customer,
        relatedOrderId: 'order-$orderNo',
        amount: amount,
        transactionDate: at(daysAgo, hour, 15),
      );
    }

    FinancialTransaction expense(
      String id,
      int daysAgo,
      int hour,
      ExpenseType type,
      String item,
      double amount, {
      String? vendor,
      double? quantity,
      String? unit,
      InputSource source = InputSource.manual,
      bool receipt = false,
      String? description,
    }) {
      return FinancialTransaction(
        id: id,
        type: TransactionType.expense,
        expenseType: type,
        itemName: item,
        quantity: quantity,
        unit: unit,
        vendorName: vendor,
        description: description,
        amount: amount,
        inputSource: source,
        receiptImageUrl: receipt ? 'receipts/$id.jpg' : null,
        transactionDate: at(daysAgo, hour, 40),
      );
    }

    return [
      income('trx-001', 0, 14, 'RJK-1013-006', 'Dewi Lestari', 120000),
      income('trx-002', 0, 10, 'RJK-1013-005', 'Rizky Maulana', 65000),
      income('trx-003', 1, 16, 'RJK-1012-004', 'Bagas Pratama', 75000),
      expense(
        'trx-004',
        1,
        11,
        ExpenseType.material,
        'Shampoo sepatu 1 L',
        90000,
        vendor: 'Toko Maju',
        quantity: 2,
        unit: 'botol',
        source: InputSource.ai,
        receipt: true,
      ),
      income('trx-005', 2, 15, 'RJK-1011-003', 'Salsa Nuraini', 210000),
      expense(
        'trx-006',
        2,
        9,
        ExpenseType.other,
        'Token listrik',
        150000,
        description: 'Listrik outlet',
      ),
      income('trx-007', 3, 13, 'RJK-1010-002', 'Anisa Putri', 140000),
      expense(
        'trx-008',
        3,
        10,
        ExpenseType.equipment,
        'Sikat sepatu',
        30000,
        vendor: 'Toko Maju',
        quantity: 3,
        unit: 'pcs',
        source: InputSource.ai,
        receipt: true,
      ),
      income('trx-009', 4, 17, 'RJK-1009-009', 'Fajar Nugroho', 95000),
      income('trx-010', 5, 12, 'RJK-1008-007', 'Citra Maharani', 110000),
      expense(
        'trx-011',
        5,
        14,
        ExpenseType.externalService,
        'Servis mesin pengering',
        250000,
        vendor: 'Bengkel Jaya',
      ),
      income('trx-012', 7, 16, 'RJK-1006-004', 'Yoga Saputra', 65000),
      expense(
        'trx-013',
        7,
        9,
        ExpenseType.material,
        'Pewangi sepatu',
        60000,
        vendor: 'Toko Maju',
        quantity: 4,
        unit: 'botol',
      ),
      income('trx-014', 8, 11, 'RJK-1005-002', 'Dewi Lestari', 180000),
      income('trx-015', 10, 15, 'RJK-1003-008', 'Rizky Maulana', 130000),
      expense(
        'trx-016',
        10,
        8,
        ExpenseType.other,
        'Sewa tempat',
        1200000,
        description: 'Sewa bulanan',
      ),
      income('trx-017', 12, 14, 'RJK-0931-005', 'Bagas Pratama', 85000),
      expense(
        'trx-018',
        12,
        10,
        ExpenseType.equipment,
        'Rak pengering',
        350000,
        vendor: 'Toko Mebel Sentosa',
        quantity: 1,
        unit: 'unit',
        source: InputSource.ai,
        receipt: true,
      ),
      income('trx-019', 15, 13, 'RJK-0928-003', 'Salsa Nuraini', 160000),
      expense(
        'trx-020',
        15,
        9,
        ExpenseType.material,
        'Kain lap microfiber',
        75000,
        vendor: 'Toko Maju',
        quantity: 10,
        unit: 'pcs',
      ),
      income('trx-021', 18, 16, 'RJK-0925-006', 'Anisa Putri', 120000),
      expense(
        'trx-022',
        18,
        11,
        ExpenseType.externalService,
        'Jasa perbaikan sol',
        120000,
        vendor: 'Pak Joko',
      ),
      income('trx-023', 21, 12, 'RJK-0922-002', 'Citra Maharani', 205000),
      expense(
        'trx-024',
        21,
        8,
        ExpenseType.other,
        'Gaji worker',
        1500000,
        description: 'Gaji bulanan',
      ),
      income('trx-025', 25, 15, 'RJK-0918-004', 'Fajar Nugroho', 90000),
      expense(
        'trx-026',
        25,
        10,
        ExpenseType.material,
        'Sabun cuci',
        66000,
        vendor: 'Toko Maju',
        quantity: 3,
        unit: 'botol',
      ),
      income('trx-027', 30, 14, 'RJK-0913-001', 'Yoga Saputra', 75000),
      expense(
        'trx-028',
        30,
        9,
        ExpenseType.other,
        'BBM kurir',
        50000,
        description: 'Bensin motor antar-jemput',
      ),
    ];
  }
}
