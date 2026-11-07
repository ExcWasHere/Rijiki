import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/rupiah_input_formatter.dart';
import 'package:rijiki/features/cms/presentation/controllers/point_rules_controller.dart';
import 'package:rijiki/features/cms/presentation/utils/point_format.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_state_card.dart';
import 'package:rijiki/features/points/domain/point_rule.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class PointRulePage extends ConsumerWidget {
  const PointRulePage({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    PointRule rule,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final input = await showModalBottomSheet<PointRuleInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (_) => _RuleEditSheet(rule: rule),
    );
    if (input == null) return;

    final ok = await ref
        .read(pointRulesManageProvider.notifier)
        .save(rule: rule, input: input);
    final message = ok
        ? 'Aturan poin disimpan. Berlaku untuk transaksi berikutnya.'
        : (ref.read(pointRulesManageProvider).errorMessage ??
              'Gagal menyimpan.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pointRulesProvider);
    final rules = async.value;
    final manage = ref.watch(pointRulesManageProvider);
    final textTheme = Theme.of(context).textTheme;

    Widget body;
    if (rules != null) {
      body = rules.isEmpty
          ? CmsStateCard(
              child: EmptyState(
                icon: Icons.stars_rounded,
                title: 'Belum ada aturan poin',
                message:
                    'Aturan awal dibuat lewat database. Hubungi developer '
                    'bila daftar ini kosong.',
              ),
            )
          : Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Material(
                color: AppColors.surface,
                child: Column(
                  children: [
                    for (var i = 0; i < rules.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: AppSpacing.md,
                          endIndent: AppSpacing.md,
                          color: AppColors.outline.withValues(alpha: 0.2),
                        ),
                      _RuleTile(
                        rule: rules[i],
                        busy: manage.busyId == rules[i].id,
                        onTap: () => _edit(context, ref, rules[i]),
                      ),
                    ],
                  ],
                ),
              ),
            );
    } else if (async.hasError) {
      body = CmsStateCard(
        child: ErrorState(
          message: 'Gagal memuat aturan poin.',
          onRetry: () => ref.invalidate(pointRulesProvider),
        ),
      );
    } else {
      body = const LoadingSkeleton(height: 200, radius: AppSpacing.radiusLg);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Poin')),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () async {
          ref.invalidate(pointRulesProvider);
          try {
            await ref.read(pointRulesProvider.future);
          } catch (_) {}
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Text(
              'Atur berapa poin yang didapat customer. Perubahan berlaku '
              'untuk transaksi berikutnya; poin yang sudah masuk tidak berubah.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            body,
          ],
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.rule,
    required this.busy,
    required this.onTap,
  });

  final PointRule rule;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: busy ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.rijikiOrange.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.stars_rounded,
                color: AppColors.rijikiOrange,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.source.title, style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    rule.isActive
                        ? rule.source.hint
                        : 'Nonaktif. ${rule.source.hint}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPointRuleValue(rule),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RuleEditSheet extends StatefulWidget {
  const _RuleEditSheet({required this.rule});

  final PointRule rule;

  @override
  State<_RuleEditSheet> createState() => _RuleEditSheetState();
}

class _RuleEditSheetState extends State<_RuleEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _points;
  late final TextEditingController _unit;

  bool get _perAmount =>
      widget.rule.calculationType == PointCalculationType.perAmount;

  @override
  void initState() {
    super.initState();
    _points = TextEditingController(text: widget.rule.pointsValue.toString());
    _unit = TextEditingController(
      text: widget.rule.amountUnit == null
          ? ''
          : rupiahInputText(widget.rule.amountUnit!.toDouble()),
    );
  }

  @override
  void dispose() {
    _points.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      PointRuleInput(
        pointsValue: int.parse(_points.text.trim()),
        amountUnit: _perAmount ? parseRupiahInput(_unit.text).round() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.rule.source.title, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              widget.rule.source.hint,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _points,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                labelText: 'Jumlah poin',
                suffixText: 'poin',
                helperText: _perAmount
                    ? 'Poin yang didapat untuk setiap kelipatan nominal.'
                    : 'Isi 0 bila aksi ini tidak memberi poin.',
              ),
              validator: (value) {
                final n = int.tryParse((value ?? '').trim());
                if (n == null) return 'Isi jumlah poin.';
                if (n > 100000) return 'Maksimal 100.000 poin.';
                return null;
              },
            ),
            if (_perAmount) ...[
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _unit,
                keyboardType: TextInputType.number,
                inputFormatters: const [RupiahInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Setiap kelipatan',
                  prefixText: 'Rp ',
                ),
                validator: (value) => parseRupiahInput((value ?? '').trim()) <= 0
                    ? 'Nominal harus lebih dari 0.'
                    : null,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
