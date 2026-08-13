import 'package:flutter/material.dart';
import 'package:appmobilegmao/widgets/loading_indicator.dart';
import 'package:appmobilegmao/widgets/empty_state.dart';
import 'package:appmobilegmao/theme/responsive_spacing.dart';

typedef ItemBuilder = Widget Function(int index);

class EquipmentList extends StatelessWidget {
  final bool isLoading;
  final List items;
  final Future<void> Function()? onRefresh;
  final Widget Function(dynamic item) itemBuilder;

  const EquipmentList({
    super.key,
    required this.isLoading,
    required this.items,
    this.onRefresh,
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

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) => Padding(
        padding: spacing.custom(bottom: 10),
        child: itemBuilder(items[index]),
      ),
    );
  }
}
