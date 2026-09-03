import 'package:flutter/material.dart';
import 'package:appmobilegmao/theme/app_theme.dart';
import 'package:appmobilegmao/widgets/loading_indicator.dart';
import 'package:appmobilegmao/widgets/empty_state.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

typedef ItemBuilder = Widget Function(int index);

class EquipmentList extends StatelessWidget {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final List items;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onLoadMore;
  final Widget Function(dynamic item) itemBuilder;

  const EquipmentList({
    super.key,
    required this.isLoading,
    this.isLoadingMore = false,
    this.hasMore = false,
    required this.items,
    this.onRefresh,
    this.onLoadMore,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (isLoading && items.isEmpty) return const LoadingIndicator();

    if (items.isEmpty) {
      return EmptyState(
        title: '📦 Aucun équipement',
        message: 'Aucun équipement n\'a été trouvé.',
        icon: Icons.inventory_2_outlined,
        onRetry: onRefresh,
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, __) => SizedBox(height: spacing.small),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: isLoadingMore
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: onLoadMore,
                      icon: const Icon(Icons.add),
                      label: const Text("Charger plus d'équipements"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
            ),
          );
        }

        return itemBuilder(items[index]);
      },
    );
  }
}
