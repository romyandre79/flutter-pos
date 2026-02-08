import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_offline/data/models/purchase_order.dart';
import 'package:flutter_pos_offline/data/repositories/purchase_order_repository.dart';
import 'package:flutter_pos_offline/logic/cubits/purchase_order/purchase_order_state.dart';

class PurchaseOrderCubit extends Cubit<PurchaseOrderState> {
  final PurchaseOrderRepository _repository;

  PurchaseOrderCubit({required PurchaseOrderRepository repository})
      : _repository = repository,
        super(PoInitial());

  Future<void> loadPurchaseOrders() async {
    try {
      emit(PoLoading());
      final pos = await _repository.getAllPurchaseOrders();
      emit(PoLoaded(pos));
    } catch (e) {
      emit(PoError('Failed to load purchase orders: ${e.toString()}'));
    }
  }

  Future<void> createPurchaseOrder(PurchaseOrder po) async {
    try {
      emit(PoLoading());
      await _repository.createPurchaseOrder(po);
      emit(const PoOperationSuccess('Pembelian created successfully'));
      loadPurchaseOrders();
    } catch (e) {
      emit(PoError('Failed to create purchase order: ${e.toString()}'));
    }
  }

  Future<void> updateStatus(int id, String status) async {
    try {
      emit(PoLoading());
      await _repository.updatePurchaseOrderStatus(id, status);
      emit(const PoOperationSuccess('Status updated successfully'));
      loadPurchaseOrders();
    } catch (e) {
      emit(PoError('Failed to update status: ${e.toString()}'));
    }
  }

  Future<void> deletePurchaseOrder(int id) async {
    try {
      emit(PoLoading());
      await _repository.deletePurchaseOrder(id);
      emit(const PoOperationSuccess('Pembelian deleted successfully'));
      loadPurchaseOrders();
    } catch (e) {
      emit(PoError('Failed to delete purchase order: ${e.toString()}'));
    }
  }
}
