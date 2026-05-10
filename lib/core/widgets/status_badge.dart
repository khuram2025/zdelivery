import 'package:flutter/material.dart';
import '../utils/extensions.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool showIcon;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = status.statusColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              status.statusIcon,
              size: isCompact ? 12 : 14,
              color: color,
            ),
            SizedBox(width: isCompact ? 4 : 6),
          ],
          Text(
            status.statusDisplayName,
            style: TextStyle(
              color: color,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class PriorityBadge extends StatelessWidget {
  final int priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    if (priority < 2) return const SizedBox.shrink();

    final isExpress = priority >= 3;
    final color = isExpress ? Colors.red : Colors.orange;
    final text = isExpress ? 'EXPRESS' : 'HIGH';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class CodBadge extends StatelessWidget {
  final double amount;
  final bool isCompact;

  const CodBadge({
    super.key,
    required this.amount,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.payments_outlined,
            size: isCompact ? 12 : 14,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'COD',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
