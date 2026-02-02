import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

extension StringExtension on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }
}

extension DateTimeExtension on DateTime {
  String get formatted => DateFormat('MMM d, yyyy').format(this);
  String get formattedTime => DateFormat('h:mm a').format(this);
  String get formattedDateTime => DateFormat('MMM d, yyyy h:mm a').format(this);
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

extension DoubleExtension on double {
  String get currency => NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0).format(this);
  String get currencyWithDecimals => NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2).format(this);
}

extension DeliveryStatusExtension on String {
  Color get statusColor {
    switch (this) {
      case DeliveryStatus.pending:
      case DeliveryStatus.assigned:
        return AppColors.warning;
      case DeliveryStatus.accepted:
      case DeliveryStatus.pickedUp:
        return AppColors.info;
      case DeliveryStatus.inTransit:
      case DeliveryStatus.outForDelivery:
        return AppColors.primaryLight;
      case DeliveryStatus.arrived:
        return AppColors.secondary;
      case DeliveryStatus.delivered:
        return AppColors.success;
      case DeliveryStatus.failed:
      case DeliveryStatus.cancelled:
        return AppColors.error;
      case DeliveryStatus.returned:
        return AppColors.textTertiary;
      default:
        return AppColors.textSecondary;
    }
  }

  String get statusDisplayName {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.assigned:
        return 'Assigned';
      case DeliveryStatus.accepted:
        return 'Accepted';
      case DeliveryStatus.rejected:
        return 'Rejected';
      case DeliveryStatus.pickedUp:
        return 'Picked Up';
      case DeliveryStatus.inTransit:
        return 'In Transit';
      case DeliveryStatus.outForDelivery:
        return 'Out for Delivery';
      case DeliveryStatus.arrived:
        return 'Arrived';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.failed:
        return 'Failed';
      case DeliveryStatus.returned:
        return 'Returned';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
      default:
        return this;
    }
  }

  IconData get statusIcon {
    switch (this) {
      case DeliveryStatus.pending:
      case DeliveryStatus.assigned:
        return Icons.access_time_rounded;
      case DeliveryStatus.accepted:
        return Icons.check_circle_outline_rounded;
      case DeliveryStatus.pickedUp:
        return Icons.inventory_2_outlined;
      case DeliveryStatus.inTransit:
      case DeliveryStatus.outForDelivery:
        return Icons.local_shipping_outlined;
      case DeliveryStatus.arrived:
        return Icons.location_on_outlined;
      case DeliveryStatus.delivered:
        return Icons.task_alt_rounded;
      case DeliveryStatus.failed:
        return Icons.cancel_outlined;
      case DeliveryStatus.returned:
        return Icons.assignment_return_outlined;
      case DeliveryStatus.cancelled:
        return Icons.block_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

extension AgentStatusExtension on String {
  Color get agentStatusColor {
    switch (this) {
      case AgentStatus.available:
        return AppColors.available;
      case AgentStatus.busy:
        return AppColors.busy;
      case AgentStatus.offline:
        return AppColors.offline;
      case AgentStatus.onBreak:
        return AppColors.onBreak;
      default:
        return AppColors.textSecondary;
    }
  }

  String get agentStatusDisplayName {
    switch (this) {
      case AgentStatus.available:
        return 'Available';
      case AgentStatus.busy:
        return 'Busy';
      case AgentStatus.offline:
        return 'Offline';
      case AgentStatus.onBreak:
        return 'On Break';
      default:
        return this;
    }
  }
}
