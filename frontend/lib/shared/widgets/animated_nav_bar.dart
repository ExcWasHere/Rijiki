import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rijiki/core/theme/app_colors.dart';

class NavBarItem {
  const NavBarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Bottom navbar dengan efek gabungan: indikator geser di sisi atas dan ikon
/// yang naik + membesar saat dipilih. Gayanya sama dengan navbar customer,
/// tetapi tanpa tombol tengah sehingga semua slot setara.
class AnimatedNavBar extends StatelessWidget {
  const AnimatedNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<NavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const double barHeight = 64;
  static const double _indicatorWidth = 28;
  static const double _indicatorHeight = 3;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: AppColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = constraints.maxWidth / items.length;

          return SizedBox(
            height: barHeight + bottomInset,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 340),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  left:
                      currentIndex * slotWidth +
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
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _NavTab(
                              item: items[i],
                              selected: i == currentIndex,
                              onTap: () => onSelected(i),
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

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavBarItem item;
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
        height: AnimatedNavBar.barHeight,
        width: double.infinity,
        child: InkWell(
          onTap: () {
            if (!selected) HapticFeedback.selectionClick();
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
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
