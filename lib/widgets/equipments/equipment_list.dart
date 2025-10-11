import 'package:flutter/material.dart';
import 'package:appmobilegmao/widgets/loading_indicator.dart';
import 'package:appmobilegmao/widgets/empty_state.dart';

typedef ItemBuilder = Widget Function(int index);

class EquipmentList extends StatelessWidget {
  final bool isLoading;
  final List items;
  final Future<void> Function() onRefresh;
  final Widget Function(dynamic item) itemBuilder;

  const EquipmentList({
    super.key,
    required this.isLoading,
    required this.items,
    required this.onRefresh,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const LoadingIndicator();
    return RefreshIndicator(
      onRefresh: onRefresh,
      child:
          items.isEmpty
              ? EmptyState(
                title: '📦 Aucun équipement',
                message: 'Aucun équipement n\'a été trouvé.',
                icon: Icons.inventory_2_outlined,
                onRetry: onRefresh,
              )
              : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                itemBuilder:
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: itemBuilder(items[index]),
                    ),
              ),
    );
  }
}
