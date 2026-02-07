import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final int? id;
  final int orderId;
  final int? serviceId; // Deprecated, kept for backward compatibility
  final int? productId; // New field
  final String serviceName; // Kept as name snapshot
  final double quantity;
  final String unit;
  final int pricePerUnit;
  final int subtotal;

  const OrderItem({
    this.id,
    required this.orderId,
    this.serviceId,
    this.productId,
    required this.serviceName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'service_id': serviceId,
      'product_id': productId,
      'service_name': serviceName,
      'quantity': quantity,
      'unit': unit,
      'price_per_unit': pricePerUnit,
      'subtotal': subtotal,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int?,
      orderId: map['order_id'] as int,
      serviceId: map['service_id'] as int?,
      productId: map['product_id'] as int?,
      serviceName: map['service_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      pricePerUnit: map['price_per_unit'] as int,
      subtotal: map['subtotal'] as int,
    );
  }

  OrderItem copyWith({
    int? id,
    int? orderId,
    int? serviceId,
    int? productId,
    String? serviceName,
    double? quantity,
    String? unit,
    int? pricePerUnit,
    int? subtotal,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      serviceId: serviceId ?? this.serviceId,
      productId: productId ?? this.productId,
      serviceName: serviceName ?? this.serviceName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  // Helper: Calculate subtotal from quantity and price
  static int calculateSubtotal(double quantity, int pricePerUnit) {
    return (quantity * pricePerUnit).round();
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        serviceId,
        productId,
        serviceName,
        quantity,
        unit,
        pricePerUnit,
        subtotal,
      ];
}
