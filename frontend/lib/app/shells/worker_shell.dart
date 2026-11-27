import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/app/router/route_paths.dart';

class WorkerShell extends StatelessWidget {
  const WorkerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: _WorkerBottomBar(
        currentBranch: navigationShell.currentIndex,
        onBranchSelected: (branch) {
          navigationShell.goBranch(
            branch,
            initialLocation: branch == navigationShell.currentIndex,
          );
        },
        onAddOrder: () {
          context.push(RoutePaths.workerOfflineOrder);
        },
      ),
    );
  }
}

class _WorkerTabItem {
  const _WorkerTabItem(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _WorkerBottomBar extends StatelessWidget {
  const _WorkerBottomBar({
    required this.currentBranch,
    required this.onBranchSelected,
    required this.onAddOrder,
  });

  final int currentBranch;
  final ValueChanged<int> onBranchSelected;
  final VoidCallback onAddOrder;

  static const double _barHeight = 64;
  static const double _buttonRise = 26;
  static const double _indicatorWidth = 28;
  static const double _indicatorHeight = 3;
  static const int _actionSlot = 2;

  static const List<_WorkerTabItem> _slots = [
    _WorkerTabItem(
      'Beranda',
      Icons.space_dashboard_outlined,
      Icons.space_dashboard_rounded,
    ),
    _WorkerTabItem(
      'Pesan',
      Icons.receipt_long_outlined,
      Icons.receipt_long_rounded,
    ),
    _WorkerTabItem('Buat Pesanan', Icons.add_rounded, Icons.add_rounded),
    _WorkerTabItem(
      'Manajemen',
      Icons.grid_view_outlined,
      Icons.grid_view_rounded,
    ),
    _WorkerTabItem(
      'Profil',
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];

  static int _branchOfSlot(int slot) => slot > _actionSlot ? slot - 1 : slot;

  static int _slotOfBranch(int branch) =>
      branch >= _actionSlot ? branch + 1 : branch;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final currentSlot = _slotOfBranch(currentBranch);

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = constraints.maxWidth / _slots.length;

          return SizedBox(
            height: _barHeight + _buttonRise + bottomInset,
            child: Stack(
              children: [
                // Latar navbar.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _barHeight + bottomInset,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(
                        top: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                ),

                // Indikator menu yang sedang aktif.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 340),
                  curve: Curves.easeOutCubic,
                  top: _buttonRise,
                  left:
                      currentSlot * slotWidth +
                      (slotWidth - _indicatorWidth) / 2,
                  width: _indicatorWidth,
                  height: _indicatorHeight,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(_indicatorHeight),
                      ),
                    ),
                  ),
                ),

                // Lima slot navbar.
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: Row(
                      children: [
                        for (var slot = 0; slot < _slots.length; slot++)
                          Expanded(
                            child: slot == _actionSlot
                                ? _AddOrderButton(
                                    label: _slots[slot].label,
                                    icon: _slots[slot].activeIcon,
                                    onTap: onAddOrder,
                                  )
                                : _WorkerTabButton(
                                    item: _slots[slot],
                                    selected: slot == currentSlot,
                                    onTap: () =>
                                        onBranchSelected(_branchOfSlot(slot)),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WorkerTabButton extends StatelessWidget {
  const _WorkerTabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _WorkerTabItem item;
  final bool selected;
  final VoidCallback onTap;

  static const Duration _duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryDark : AppColors.onSurfaceVariant;

    final labelStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
      color: color,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: _WorkerBottomBar._barHeight,
        width: double.infinity,
        child: InkWell(
          onTap: () {
            if (!selected) {
              HapticFeedback.selectionClick();
            }
            onTap();
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSlide(
                offset: Offset(0, selected ? -0.14 : 0),
                duration: _duration,
                curve: Curves.easeOutBack,
                child: AnimatedScale(
                  scale: selected ? 1.14 : 1,
                  duration: _duration,
                  curve: Curves.easeOutBack,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      selected ? item.activeIcon : item.icon,
                      key: ValueKey(selected),
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: labelStyle,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddOrderButton extends StatefulWidget {
  const _AddOrderButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_AddOrderButton> createState() => _AddOrderButtonState();
}

class _AddOrderButtonState extends State<_AddOrderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: _pressed ? 0.92 : 1,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: Material(
                color: AppColors.rijikiOrange,
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.surface, width: 4),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onHighlightChanged: (value) {
                    setState(() => _pressed = value);
                  },
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onTap();
                  },
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      widget.icon,
                      size: 30,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
