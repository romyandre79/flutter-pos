import 'package:equatable/equatable.dart';
import 'package:flutter_pos/data/models/purchase_order.dart';

abstract class PurchaseOrderState extends Equatable {
  const PurchaseOrderState();

  @override
  List<Object?> get props => [];
}

class PoInitial extends PurchaseOrderState {}

class PoLoading extends PurchaseOrderState {}

class PoLoaded extends PurchaseOrderState {
  final List<PurchaseOrder> purchaseOrders;

  const PoLoaded(this.purchaseOrders);

  @override
  List<Object?> get props => [purchaseOrders];
}

class PoError extends PurchaseOrderState {
  final String message;

  const PoError(this.message);

  @override
  List<Object?> get props => [message];
}

class PoOperationSuccess extends PurchaseOrderState {
  final String message;

  const PoOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
