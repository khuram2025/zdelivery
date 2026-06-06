import 'dart:convert';

enum DeliveryNotificationType {
  newOrder,
  missingLocation,
  codCollection,
  creditOrder,
  staleOrder,
  system,
}

class DeliveryNotification {
  final String id;
  final DeliveryNotificationType type;
  final String title;
  final String body;
  final String? route;
  final int? orderId;
  final String? orderNumber;
  final DateTime createdAt;
  final bool isRead;
  final bool isImportant;

  const DeliveryNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.route,
    this.orderId,
    this.orderNumber,
    required this.createdAt,
    this.isRead = false,
    this.isImportant = false,
  });

  DeliveryNotification copyWith({
    bool? isRead,
  }) {
    return DeliveryNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      route: route,
      orderId: orderId,
      orderNumber: orderNumber,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      isImportant: isImportant,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'route': route,
      'order_id': orderId,
      'order_number': orderNumber,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'is_important': isImportant,
    };
  }

  factory DeliveryNotification.fromJson(Map<String, dynamic> json) {
    return DeliveryNotification(
      id: json['id']?.toString() ?? '',
      type: DeliveryNotificationType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => DeliveryNotificationType.system,
      ),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      route: json['route']?.toString(),
      orderId: int.tryParse(json['order_id']?.toString() ?? ''),
      orderNumber: json['order_number']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] == true,
      isImportant: json['is_important'] == true,
    );
  }

  static List<DeliveryNotification> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) =>
            DeliveryNotification.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  static String encodeList(List<DeliveryNotification> notifications) {
    return jsonEncode(notifications.map((item) => item.toJson()).toList());
  }
}
