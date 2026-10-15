import 'package:rijiki/core/enums/expense_type.dart';
import 'package:rijiki/features/finance/domain/expense_draft_item.dart';

abstract final class MockExpenseParser {
  static const String failTrigger = 'tes gagal';

  static bool shouldFail(String text) =>
      text.toLowerCase().contains(failTrigger);

  static final RegExp _splitter = RegExp(
    r'\s*(?:[,;\n]|\bdan\b|\bsama\b|\.(?=\s|$))\s*',
    caseSensitive: false,
  );
  static final RegExp _kemarin = RegExp(r'\bkemarin\b', caseSensitive: false);
  static final RegExp _vendorCapital = RegExp(
    r'\b(?:[Dd]i|[Dd]ari)\s+((?:[A-Z][\w-]*)(?:\s+[A-Z][\w-]*)*)',
  );
  static final RegExp _vendorLower = RegExp(
    r'\b(?:di|dari)\s+((?:toko|warung|bengkel|apotek|pasar|minimarket|supermarket|kios)\s+\w+)',
    caseSensitive: false,
  );
  static final RegExp _quantity = RegExp(
    r'\b(\d+(?:[.,]\d+)?)\s*(botol|pcs|biji|buah|unit|kg|liter|pack|lusin|set|rim|roll|lembar|bungkus|sachet|galon|kaleng|pasang|meter)\b',
    caseSensitive: false,
  );
  static final RegExp _leadingFiller = RegExp(
    r'^\s*(?:beli(?:in)?|bayar(?:in)?|belanja|keluar(?:in)?|buat|untuk|tadi)\b\s*',
    caseSensitive: false,
  );
  static final RegExp _noiseWords = RegExp(
    r'\b(?:rp|seharga|harga|total|sebesar|sekitar|per|satuan)\b\.?',
    caseSensitive: false,
  );

  static final RegExp _service = RegExp(
    r'\b(servis|service|perbaikan|reparasi|tukang|jasa|bengkel|montir|ongkir|ojek)\b',
    caseSensitive: false,
  );
  static final RegExp _other = RegExp(
    r'\b(listrik|token|sewa|gaji|upah|pdam|air|wifi|internet|bensin|bbm|parkir|pulsa|pajak|konsumsi|makan|minum|kebersihan)\b',
    caseSensitive: false,
  );
  static final RegExp _equipment = RegExp(
    r'\b(sikat|rak|mesin|alat|ember|timba|gunting|kuas|hairdryer|baskom|sapu|kipas|lampu|meja|kursi|cutter|tang|obeng)\b',
    caseSensitive: false,
  );
  static final RegExp _material = RegExp(
    r'\b(sabun|sampo|shampoo|pembersih|pewangi|parfum|deterjen|detergen|kain|lap|microfiber|lem|cat|semir|spons|tali|insole|cairan|plastik|tisu|pelindung|spray|cleaner|foam|busa|karet)\b',
    caseSensitive: false,
  );

  static List<ExpenseDraftItem> receiptSample(DateTime date) => [
    ExpenseDraftItem(
      id: 'ai-nota-1',
      expenseType: ExpenseType.material,
      itemName: 'Shampoo sepatu 1 L',
      amount: 90000,
      quantity: 2,
      unit: 'botol',
      vendorName: 'Toko Maju',
      transactionDate: date,
      confidence: 0.93,
    ),
    ExpenseDraftItem(
      id: 'ai-nota-2',
      expenseType: ExpenseType.equipment,
      itemName: 'Sikat sepatu',
      amount: 30000,
      quantity: 3,
      unit: 'pcs',
      vendorName: 'Toko Maju',
      transactionDate: date,
      confidence: 0.9,
    ),
    ExpenseDraftItem(
      id: 'ai-nota-3',
      expenseType: ExpenseType.other,
      itemName: 'Barang tidak terbaca',
      amount: 25000,
      vendorName: 'Toko Maju',
      transactionDate: date,
      confidence: 0.35,
      needsReview: true,
    ),
  ];

  static List<ExpenseDraftItem> parse(String text, DateTime date) {
    final globalVendor = _vendor(text)?.$1;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final items = <ExpenseDraftItem>[];

    var index = 0;
    for (final clause in text.split(_splitter)) {
      final trimmed = clause.trim();
      if (trimmed.isEmpty) continue;
      final item = _parseClause(trimmed, 'ai-$stamp-${index++}', date, globalVendor);
      if (item != null) items.add(item);
    }
    return items;
  }

  static ExpenseDraftItem? _parseClause(
    String raw,
    String id,
    DateTime date,
    String? globalVendor,
  ) {
    var text = raw;
    var itemDate = date;

    if (_kemarin.hasMatch(text)) {
      itemDate = date.subtract(const Duration(days: 1));
      text = text.replaceAll(_kemarin, ' ');
    }

    final vendorHit = _vendor(text);
    final vendor = vendorHit?.$1 ?? globalVendor;
    if (vendorHit != null) text = text.replaceFirst(vendorHit.$2, ' ');

    var amount = _amount(text);
    final quantityMatch = _quantity.firstMatch(text);
    double? quantity;
    String? unit;
    if (quantityMatch != null) {
      quantity = double.tryParse(quantityMatch.group(1)!.replaceAll(',', '.'));
      unit = quantityMatch.group(2)!.toLowerCase();
    }

    final perUnit = raw.contains('@') ||
        RegExp(r'\b(per|satuan)\b', caseSensitive: false).hasMatch(raw);
    if (amount != null && perUnit && quantity != null) {
      amount = (amount.$1 * quantity, amount.$2);
    }

    var name = text;
    if (amount != null) name = name.replaceFirst(amount.$2, ' ');
    if (quantityMatch != null) name = name.replaceFirst(quantityMatch.group(0)!, ' ');
    name = name.replaceAll(_noiseWords, ' ').replaceAll('@', ' ');
    name = name.replaceAll(RegExp(r'[^\p{L}\p{N}\s\-/&()]', unicode: true), ' ');
    var changed = true;
    while (changed) {
      final next = name.replaceFirst(_leadingFiller, '');
      changed = next != name;
      name = next;
    }
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (name.isEmpty && amount == null) return null;
    if (name.isEmpty) name = 'Pengeluaran';
    name = name[0].toUpperCase() + name.substring(1);

    final (type, known) = _classify(raw);
    final missingAmount = amount == null;

    return ExpenseDraftItem(
      id: id,
      expenseType: type,
      itemName: name,
      amount: amount?.$1 ?? 0,
      quantity: quantity,
      unit: unit,
      vendorName: vendor,
      transactionDate: itemDate,
      confidence: missingAmount ? 0.3 : (known ? 0.9 : 0.4),
      needsReview: !known || missingAmount,
    );
  }

  static (double, String)? _amount(String s) {
    final dotted = RegExp(r'\b\d{1,3}(?:\.\d{3})+\b').firstMatch(s);
    if (dotted != null) {
      final text = dotted.group(0)!;
      return (double.parse(text.replaceAll('.', '')), text);
    }
    final unit = RegExp(
      r'\b(\d+(?:[.,]\d+)?)\s*(rb|ribu|k|jt|juta)\b',
      caseSensitive: false,
    ).firstMatch(s);
    if (unit != null) {
      final number = double.parse(unit.group(1)!.replaceAll(',', '.'));
      final u = unit.group(2)!.toLowerCase();
      final mult = (u == 'jt' || u == 'juta') ? 1000000 : 1000;
      return (number * mult, unit.group(0)!);
    }
    final plain = RegExp(r'\b\d{4,}\b').firstMatch(s);
    if (plain != null) {
      final text = plain.group(0)!;
      return (double.parse(text), text);
    }
    return null;
  }

  static (String, String)? _vendor(String s) {
    final match = _vendorCapital.firstMatch(s) ?? _vendorLower.firstMatch(s);
    if (match == null) return null;
    final words = match
        .group(1)!
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
    return (words, match.group(0)!);
  }

  static (ExpenseType, bool) _classify(String text) {
    if (_service.hasMatch(text)) return (ExpenseType.externalService, true);
    if (_other.hasMatch(text)) return (ExpenseType.other, true);
    if (_equipment.hasMatch(text)) return (ExpenseType.equipment, true);
    if (_material.hasMatch(text)) return (ExpenseType.material, true);
    return (ExpenseType.other, false);
  }
}
