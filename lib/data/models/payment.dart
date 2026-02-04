import 'package:equatable/equatable.dart';

enum PaymentMethod { cash, transfer, qris }

extension PaymentMethodExtension on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.transfer:
        return 'transfer';
      case PaymentMethod.qris:
        return 'qris';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.transfer:
        return 'Transfer';
      case PaymentMethod.qris:
        return 'QRIS';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'transfer':
        return PaymentMethod.transfer;
      case 'qris':
        return PaymentMethod.qris;
      default:
        return PaymentMethod.cash;
    }
  }
}

class Payment extends Equatable {
  final int? id;
  final int orderId;
  final int amount;
  final int change; // Kembalian
  final DateTime paymentDate;
  final PaymentMethod paymentMethod;
  final String? notes;
  final int? receivedBy;
  final DateTime? createdAt;

  const Payment({
    this.id,
    required this.orderId,
    required this.amount,
    this.change = 0,
    required this.paymentDate,
    required this.paymentMethod,
    this.notes,
    this.receivedBy,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'change': change,
      'payment_date': paymentDate.toIso8601String(),
      'payment_method': paymentMethod.value,
      'notes': notes,
      'received_by': receivedBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      orderId: map['order_id'] as int,
      amount: map['amount'] as int,
      change: (map['change'] as int?) ?? 0,
      paymentDate: DateTime.parse(map['payment_date'] as String),
      paymentMethod:
          PaymentMethodExtension.fromString(map['payment_method'] as String),
      notes: map['notes'] as String?,
      receivedBy: map['received_by'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Payment copyWith({
    int? id,
    int? orderId,
    int? amount,
    int? change,
    DateTime? paymentDate,
    PaymentMethod? paymentMethod,
    String? notes,
    int? receivedBy,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      change: change ?? this.change,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      receivedBy: receivedBy ?? this.receivedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        amount,
        change,
        paymentDate,
        paymentMethod,
        notes,
        receivedBy,
        createdAt,
      ];
}
