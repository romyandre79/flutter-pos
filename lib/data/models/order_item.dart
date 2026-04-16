import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final int? id;
  final int orderId;
  final int? serviceId;
  final int? productId;
  final int? unitId; // New field
  final String serviceName;
  final double quantity;
  final String unit;
  final int pricePerUnit;
  final int discount;
  final int subtotal;

  const OrderItem({
    this.id,
    required this.orderId,
    this.serviceId,
    this.productId,
    this.unitId,
    required this.serviceName,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    this.discount = 0,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'service_id': serviceId,
      'product_id': productId,
      'unit_id': unitId,
      'service_name': serviceName,
      'quantity': quantity,
      'unit': unit,
      'price_per_unit': pricePerUnit,
      'discount': discount,
      'subtotal': subtotal,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int?,
      orderId: map['order_id'] as int,
      serviceId: map['service_id'] as int?,
      productId: map['product_id'] as int?,
      unitId: map['unit_id'] as int?,
      serviceName: map['service_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      pricePerUnit: map['price_per_unit'] as int,
      discount: (map['discount'] as int?) ?? 0,
      subtotal: map['subtotal'] as int,
    );
  }

  OrderItem copyWith({
    int? id,
    int? orderId,
    int? serviceId,
    int? productId,
    int? unitId,
    String? serviceName,
    double? quantity,
    String? unit,
    int? pricePerUnit,
    int? discount,
    int? subtotal,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      serviceId: serviceId ?? this.serviceId,
      productId: productId ?? this.productId,
      unitId: unitId ?? this.unitId,
      serviceName: serviceName ?? this.serviceName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      discount: discount ?? this.discount,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  static int calculateSubtotal(double quantity, int pricePerUnit) {
    return (quantity * pricePerUnit).round();
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        serviceId,
        productId,
        unitId,
        serviceName,
        quantity,
        unit,
        pricePerUnit,
        discount,
        subtotal,
      ];
}
