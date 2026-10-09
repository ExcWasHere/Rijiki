import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';


class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}


class _EventPageState extends State<EventPage> {
  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Event',
    'Promo',
    'Merch',
  ];

  final List<_EventItem> _items = [
  const _EventItem(
    type: 'Promo',
    title: 'Diskon 20% Deep Clean',
    description: 'Khusus order pertama kamu bulan ini.',
    date: 'Sampai 22 Okt 2026',
    icon: Icons.local_offer_outlined,
  ),
  const _EventItem(
    type: 'Event',
    title: 'Sneaker Care Day',
    description: 'Belajar cara merawat sepatu dengan benar bersama Rijiki.',
    date: '09.00 - 16.00 WIB',
    icon: Icons.event_outlined,
  ),
  const _EventItem(
    type: 'Event',
    title: 'Rijiki x Komunitas Sepatu Malang',
    description: 'Cuci bareng dan ngobrol soal cara merawat sneakers.',
    date: '25 Okt 2026',
    icon: Icons.groups_outlined,
  ),
  const _EventItem(
    type: 'Promo',
    title: 'Promo Antar-Jemput',
    description: 'Nikmati layanan antar-jemput untuk area tertentu.',
    date: 'Sampai 30 Okt 2026',
    icon: Icons.local_shipping_outlined,
  ),
];

  final List<_MerchItem> _merchItems = [
  const _MerchItem(
    title: 'Keychain',
    subtitle: 'Sneaker',
    points: 150,
    icon: Icons.key_outlined,
    imageUrl: 'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=400',
  ),
  const _MerchItem(
    title: 'Stiker Set',
    subtitle: '3 pcs',
    points: 100,
    icon: Icons.sticky_note_2_outlined,
    imageUrl: 'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=400',
  ),
  const _MerchItem(
    title: 'Tote Bag',
    subtitle: 'Rijiki Style',
    points: 250,
    icon: Icons.shopping_bag_outlined,
    imageUrl: 'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=400',
  ),
];
  List<_EventItem> get _filteredEvents {
    if (_selectedFilter == 'Semua') {
      return _items;
    }

    return _items
        .where((item) => item.type == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final showEvents =
        _selectedFilter == 'Semua' ||
        _selectedFilter == 'Event' ||
        _selectedFilter == 'Promo';

    final showMerch =
        _selectedFilter == 'Semua' ||
        _selectedFilter == 'Merch';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: 32,
          ),
          children: [
            const _EventHeader(),

            const SizedBox(height: AppSpacing.md),

            const _PointCard(
              points: 320,
            ),

            const SizedBox(height: AppSpacing.lg),

            _FilterList(
              filters: _filters,
              selectedFilter: _selectedFilter,
              onSelected: (value) {
                setState(() {
                  _selectedFilter = value;
                });
              },
            ),

            if (showEvents) ...[
              const SizedBox(height: AppSpacing.xl),

              const _SectionTitle(
                title: 'Promo & event',
              ),

              const SizedBox(height: AppSpacing.sm),

              if (_filteredEvents.isEmpty)
                const _EmptyState(
                  message: 'Belum ada promo atau event.',
                )
              else
                ..._filteredEvents.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.sm,
                    ),
                    child: _PromoEventCard(
                      item: item,
                    ),
                  ),
                ),
            ],

            if (showMerch) ...[
              const SizedBox(height: AppSpacing.md),

              const _SectionTitle(
                title: 'Merch',
              ),

              const SizedBox(height: AppSpacing.sm),

              SizedBox(
                height: 245,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _merchItems.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    return _MerchCard(
                      item: _merchItems[index],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventHeader extends StatelessWidget {
  const _EventHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            Navigator.of(context).maybePop();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
        ),

        const SizedBox(width: 4),

        Expanded(
          child: Text(
            'Event & Promo',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
          ),
        ),
      ],
    );
  }
}


class _PointCard extends StatelessWidget {
  const _PointCard({
    
    required this.points,
  });

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AppColors.onSurfaceVariant.withOpacity(0.40),
        width: 1,
      ),
    ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC83D).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 27,
              color: Color(0xFFFFB800),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$points Point',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Kumpulkan point dari tiap transaksi untuk mendapatkan hadiah yang menarik.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
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

class _FilterList extends StatelessWidget {
  const _FilterList({
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(
              right: AppSpacing.xs,
            ),
            child: GestureDetector(
              onTap: () {
                onSelected(filter);
              },
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant
                            .withOpacity(0.25),
                  ),
                ),
                child: Text(
                  filter,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
    );
  }
}


class _PromoEventCard extends StatelessWidget {
  const _PromoEventCard({
    required this.item,
  });

  final _EventItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isPromo = item.type == 'Promo';

    final accentColor = isPromo
        ? AppColors.rijikiOrange
        : AppColors.primary;

    final cardColor = Color.lerp(
      AppColors.surface,
      accentColor,
      0.06,
    )!;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // UI prototype dulu.
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.onSurfaceVariant.withOpacity(0.40),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.type,
                  style: textTheme.labelSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: accentColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _MerchCard extends StatelessWidget {
  const _MerchCard({
    required this.item,
  });

  final _MerchItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AppColors.onSurfaceVariant.withOpacity(0.40),
        width: 1,
      ),
    ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: double.infinity,
              height: 110,
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.primary.withOpacity(0.07),
                    alignment: Alignment.center,
                    child: Icon(
                      item.icon,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
          ),

          const SizedBox(height: 3),

          Text(
            item.subtitle,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),

          const Spacer(),

          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 17,
                color: Color(0xFFFFB800),
              ),

              const SizedBox(width: 4),

              Text(
                '${item.points} points',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
              ),

              const Spacer(),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.rijikiOrange
                      .withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(9),
                ),
                child: Text(
                  'Tukar',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                        color: AppColors.rijikiOrange,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.onSurfaceVariant
              .withOpacity(0.20),
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _EventItem {
  const _EventItem({
    required this.type,
    required this.title,
    required this.description,
    required this.date,
    required this.icon,
  });

  final String type;
  final String title;
  final String description;
  final String date;
  final IconData icon;
}

class _MerchItem {
  const _MerchItem({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.icon,
    required this.imageUrl,
  });

  final String title;
  final String subtitle;
  final int points;
  final IconData icon;
  final String imageUrl;
}