import 'package:flutter/material.dart';
import '../../features/orders/data/models.dart';
import '../theme/app_theme.dart';
import '../utils/extensions.dart';
import 'status_badge.dart';

class OrderCard extends StatelessWidget {
  final DeliveryOrder order;
  final VoidCallback? onTap;
  final bool showActions;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.showActions = false,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber ?? order.assignmentNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.customerName ?? 'Customer',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(status: order.status, isCompact: true),
                      if (order.isHighPriority) ...[
                        const SizedBox(height: 4),
                        PriorityBadge(priority: order.priority),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Address
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.deliveryAddress ?? 'No address',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Footer Row
              Row(
                children: [
                  if (order.isCod) ...[
                    CodBadge(amount: order.codAmount, isCompact: true),
                    const SizedBox(width: 8),
                  ],
                  if (order.orderTotal != null)
                    Text(
                      order.orderTotal!.currency,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.createdAt.timeAgo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),

              // Actions
              if (showActions) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
