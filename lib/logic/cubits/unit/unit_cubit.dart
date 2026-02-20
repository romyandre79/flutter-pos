import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_pos/data/models/unit.dart';
import 'package:flutter_pos/data/repositories/unit_repository.dart';

// States
abstract class UnitState extends Equatable {
  const UnitState();

  @override
  List<Object> get props => [];
}

class UnitInitial extends UnitState {}

class UnitLoading extends UnitState {}

class UnitLoaded extends UnitState {
  final List<Unit> units;

  const UnitLoaded(this.units);

  @override
  List<Object> get props => [units];
}

class UnitError extends UnitState {
  final String message;

  const UnitError(this.message);

  @override
  List<Object> get props => [message];
}

class UnitOperationSuccess extends UnitState {
  final String message;

  const UnitOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

// Cubit
class UnitCubit extends Cubit<UnitState> {
  final UnitRepository _repository;

  UnitCubit(this._repository) : super(UnitInitial());

  Future<void> loadUnits() async {
    emit(UnitLoading());
    try {
      final units = await _repository.getUnits();
      emit(UnitLoaded(units));
    } catch (e) {
      emit(UnitError('Gagal memuat unit: $e'));
    }
  }

  Future<void> addUnit(String name) async {
    try {
      final unit = Unit(name: name);
      await _repository.addUnit(unit);
      emit(const UnitOperationSuccess('Unit berhasil ditambahkan'));
      loadUnits();
    } catch (e) {
      emit(UnitError('Gagal menambah unit: $e'));
      // Reload to show current state
      loadUnits();
    }
  }

  Future<void> updateUnit(Unit unit) async {
    try {
      await _repository.updateUnit(unit);
      emit(const UnitOperationSuccess('Unit berhasil diperbarui'));
      loadUnits();
    } catch (e) {
      emit(UnitError('Gagal memperbarui unit: $e'));
      loadUnits();
    }
  }

  Future<void> deleteUnit(int id) async {
    try {
      await _repository.deleteUnit(id);
      emit(const UnitOperationSuccess('Unit berhasil dihapus'));
      loadUnits();
    } catch (e) {
      emit(UnitError('Gagal menghapus unit: $e'));
      loadUnits();
    }
  }
}
