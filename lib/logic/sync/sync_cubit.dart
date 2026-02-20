import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/services/sync_service.dart';
import 'package:flutter_pos/logic/sync/sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final SyncService _syncService;

  SyncCubit(this._syncService) : super(SyncInitial());

  Future<void> syncData() async {
    emit(const SyncLoading('Syncing data...'));
    try {
      emit(const SyncLoading('Uploading transactions...'));
      final uploadedCount = await _syncService.uploadOrders();
      
      emit(const SyncLoading('Downloading master data...'));
      await _syncService.downloadMasterData();
      
      emit(SyncSuccess('Sync completed. Uploaded: $uploadedCount orders.'));
    } catch (e) {
      emit(SyncFailure(e.toString()));
    }
  }

  Future<void> uploadTransactions() async {
    emit(const SyncLoading('Uploading transactions...'));
    try {
      final uploadedCount = await _syncService.uploadOrders();
      emit(SyncSuccess('Uploaded $uploadedCount transactions.'));
    } catch (e) {
      emit(SyncFailure(e.toString()));
    }
  }

  Future<void> downloadMasterData() async {
    emit(const SyncLoading('Downloading master data...'));
    try {
      await _syncService.downloadMasterData();
      emit(const SyncSuccess('Master data updated successfully.'));
    } catch (e) {
      emit(SyncFailure(e.toString()));
    }
  }
}
