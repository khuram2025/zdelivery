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
    final amount =
        order.orderTotal ?? (order.codAmount > 0 ? order.codAmount : null);
    final address = order.displayDeliveryAddress;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_pin_circle_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName ?? 'Customer',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 13,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                order.customerMobile ?? 'No mobile',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(status: order.status, isCompact: true),
                      if (amount != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          amount.currency,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      if (order.isHighPriority) ...[
                        const SizedBox(height: 4),
                        PriorityBadge(priority: order.priority),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InfoLine(
                icon: Icons.confirmation_number_outlined,
                text: order.orderNumber ?? order.assignmentNumber,
                color: AppColors.textTertiary,
                maxLines: 1,
              ),
              const SizedBox(height: 6),
              _InfoLine(
                icon: order.hasDeliveryCoordinates
                    ? Icons.location_on_outlined
                    : Icons.location_searching_outlined,
                text: address,
                color: order.hasDeliveryAddress
                    ? AppColors.textSecondary
                    : AppColors.error,
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (order.isCod)
                    _OrderMetaChip(
                      icon: Icons.payments_outlined,
                      label: 'COD ${order.codAmount.currency}',
                      color: AppColors.warning,
                    ),
                  _OrderMetaChip(
                    icon: order.hasDeliveryCoordinates
                        ? Icons.gps_fixed
                        : Icons.map_outlined,
                    label: order.hasDeliveryCoordinates
                        ? 'GPS pinned'
                        : order.hasDeliveryAddress
                            ? 'Address only'
                            : 'Needs address',
                    color: order.hasDeliveryCoordinates
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  _OrderMetaChip(
                    icon: Icons.schedule_rounded,
                    label:
                        order.scheduledDeliveryTime?.formattedDateTime ?? '-',
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
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

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final int maxLines;

  const _InfoLine({
    required this.icon,
    required this.text,
    required this.color,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: AppColors.textTertiary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _OrderMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _OrderMetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
