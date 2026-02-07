class PurchaseOrderItem {
  final int? id;
  final int? purchaseOrderId; // Nullable during creation
  final String itemName;
  final int quantity;
  final int cost; // Price per unit
  final int subtotal;
  final DateTime? createdAt;

  PurchaseOrderItem({
    this.id,
    this.purchaseOrderId,
    required this.itemName,
    required this.quantity,
    required this.cost,
    required this.subtotal,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_order_id': purchaseOrderId,
      'item_name': itemName,
      'quantity': quantity,
      'cost': cost,
      'subtotal': subtotal,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      id: map['id'] as int?,
      purchaseOrderId: map['purchase_order_id'] as int?,
      itemName: map['item_name'] as String,
      quantity: map['quantity'] as int,
      cost: map['cost'] as int,
      subtotal: map['subtotal'] as int,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  PurchaseOrderItem copyWith({
    int? id,
    int? purchaseOrderId,
    String? itemName,
    int? quantity,
    int? cost,
    int? subtotal,
    DateTime? createdAt,
  }) {
    return PurchaseOrderItem(
      id: id ?? this.id,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      cost: cost ?? this.cost,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
