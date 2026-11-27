import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/points/domain/point_redemption.dart';

/// Koreksi saldo poin manual: cari customer, pilih tambah/kurangi, isi keterangan.
class PointAdjustPage extends ConsumerStatefulWidget {
  const PointAdjustPage({super.key});

  @override
  ConsumerState<PointAdjustPage> createState() => _PointAdjustPageState();
}

class _PointAdjustPageState extends ConsumerState<PointAdjustPage> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _pointsController = TextEditingController();
  final _noteController = TextEditingController();

  Timer? _debounce;
  List<PointCustomer> _results = const [];
  bool _searching = false;
  String? _searchError;
  PointCustomer? _selected;
  bool _isAdd = true;
  bool _submitting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _pointsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _results = const [];
        _searching = false;
        _searchError = null;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    try {
      final found = await ref
          .read(pointManagementRepositoryProvider)
          .searchCustomers(query);
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() {
        _results = found;
        _searching = false;
        _searchError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _searching = false;
        _searchError = e is Failure && e.message.trim().isNotEmpty
            ? e.message
            : 'Gagal mencari customer. Coba lagi ya.';
      });
    }
  }

  void _select(PointCustomer customer) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selected = customer;
      _results = const [];
      _searchController.clear();
    });
  }

  String _formatNumber(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  Future<void> _submit() async {
    final customer = _selected;
    if (customer == null || _submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = int.parse(_pointsController.text.trim());
    final signed = _isAdd ? amount : -amount;
    final note = _noteController.text.trim();
    final next = customer.balance + signed;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_isAdd ? 'Tambah poin?' : 'Kurangi poin?'),
        content: Text(
          '${_isAdd ? 'Tambah' : 'Kurangi'} ${_formatNumber(amount)} poin '
          'untuk ${customer.displayName}. Saldo berubah dari '
          '${_formatNumber(customer.balance)} menjadi ${_formatNumber(next)} poin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      final balance = await ref
          .read(pointManagementRepositoryProvider)
          .adjustPoints(
            customerId: customer.id,
            points: signed,
            description: note,
          );
      if (!mounted) return;
      setState(() {
        _selected = customer.copyWith(balance: balance);
        _submitting = false;
        _pointsController.clear();
        _noteController.clear();
      });
      _formKey.currentState?.reset();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Tersimpan. Saldo ${customer.displayName} sekarang '
              '${_formatNumber(balance)} poin.',
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e is Failure && e.message.trim().isNotEmpty
                  ? e.message
                  : 'Gagal menyimpan penyesuaian. Coba lagi ya.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    final selected = _selected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sesuaikan poin')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Text(
            'Dipakai untuk koreksi atau bonus manual. Setiap penyesuaian '
            'tercatat di riwayat poin customer.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (selected == null) ...[
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Cari customer',
                hintText: 'Nama, email, atau nomor HP',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_searchError != null)
              Text(
                _searchError!,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              )
            else if (!_searching &&
                _results.isEmpty &&
                _searchController.text.trim().length >= 2)
              Text('Customer tidak ditemukan.', style: muted),
            if (_results.isNotEmpty)
              Container(
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
                      for (var i = 0; i < _results.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: AppSpacing.md,
                            endIndent: AppSpacing.md,
                            color: AppColors.outline.withValues(alpha: 0.2),
                          ),
                        ListTile(
                          onTap: () => _select(_results[i]),
                          title: Text(_results[i].displayName),
                          subtitle: Text(
                            [
                              if ((_results[i].phone ?? '').isNotEmpty)
                                _results[i].phone!,
                              _results[i].email,
                            ].join('\n'),
                          ),
                          isThreeLine: (_results[i].phone ?? '').isNotEmpty,
                          trailing: Text(
                            '${_formatNumber(_results[i].balance)} poin',
                            style: textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ] else
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected.displayName,
                                style: textTheme.titleSmall,
                              ),
                              if ((selected.phone ?? '').isNotEmpty)
                                Text(selected.phone!, style: muted),
                              const SizedBox(height: 4),
                              Text(
                                'Saldo ${_formatNumber(selected.balance)} poin',
                                style: textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => setState(() => _selected = null),
                          child: const Text('Ganti'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.add_rounded),
                        label: Text('Tambah'),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.remove_rounded),
                        label: Text('Kurangi'),
                      ),
                    ],
                    selected: {_isAdd},
                    onSelectionChanged: _submitting
                        ? null
                        : (value) => setState(() => _isAdd = value.first),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _pointsController,
                    enabled: !_submitting,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Jumlah poin',
                      suffixText: 'poin',
                    ),
                    validator: (value) {
                      final n = int.tryParse((value ?? '').trim());
                      if (n == null || n <= 0) return 'Isi jumlah poin.';
                      if (n > 100000) return 'Maksimal 100.000 poin.';
                      if (!_isAdd && n > selected.balance) {
                        return 'Melebihi saldo '
                            '(${_formatNumber(selected.balance)} poin).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _noteController,
                    enabled: !_submitting,
                    maxLength: 200,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan',
                      helperText: 'Tampil di riwayat poin customer.',
                    ),
                    validator: (value) => (value ?? '').trim().length < 3
                        ? 'Isi keterangan, minimal 3 karakter.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan penyesuaian'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
