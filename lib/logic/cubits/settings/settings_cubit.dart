import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/constants/app_constants.dart';
import 'package:flutter_pos/data/repositories/settings_repository.dart';
import 'package:flutter_pos/logic/cubits/settings/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepository(),
        super(SettingsInitial());

  StoreInfo? _currentInfo;
  StoreInfo? get currentInfo => _currentInfo;

  PlantInfo? _currentPlantInfo;
  PlantInfo? get currentPlantInfo => _currentPlantInfo;

  Future<void> loadSettings() async {
    emit(SettingsLoading());

    try {
      final settings = await _repository.getAllSettings();

      final storeInfo = StoreInfo(
        name: settings[AppConstants.keyStoreName] ??
            AppConstants.defaultStoreName,
        address: settings[AppConstants.keyStoreAddress] ??
            AppConstants.defaultStoreAddress,
        phone: settings[AppConstants.keyStorePhone] ??
            AppConstants.defaultStorePhone,
        invoicePrefix: settings[AppConstants.keyInvoicePrefix] ??
            AppConstants.defaultInvoicePrefix,
        machineNumber: settings[AppConstants.keyMachineNumber] ??
            AppConstants.defaultMachineNumber,
      );

      final plantInfo = PlantInfo(
        name: settings[AppConstants.keyPlantName] ?? '',
        address: settings[AppConstants.keyPlantAddress] ?? '',
        code: settings[AppConstants.keyPlantCode] ?? '',
      );

      _currentInfo = storeInfo;
      _currentPlantInfo = plantInfo;
      emit(SettingsLoaded(storeInfo: storeInfo, plantInfo: plantInfo));
    } catch (e) {
      emit(SettingsError(message: 'Gagal memuat pengaturan: ${e.toString()}'));
    }
  }

  // ... (existing store update methods) ...
  
  // Update Machine Number
  Future<void> updateMachineNumber(String number) async {
    if (number.trim().isEmpty) {
      emit(const SettingsError(message: 'Machine Number tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());
    try {
      await _repository.setSetting(AppConstants.keyMachineNumber, number.trim());
      
      final updatedInfo = _currentInfo!.copyWith(machineNumber: number.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Machine Number berhasil diperbarui',
        storeInfo: updatedInfo,
        plantInfo: _currentPlantInfo,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Gagal update machine number: ${e.toString()}'));
    }
  }

  Future<void> updatePlantName(String name) async {
    emit(SettingsUpdating());
    try {
      await _repository.setSetting(AppConstants.keyPlantName, name.trim());
      
      final updatedInfo = _currentPlantInfo!.copyWith(name: name.trim());
      _currentPlantInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Nama plant berhasil diperbarui',
        storeInfo: _currentInfo!,
        plantInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Gagal update plant name: ${e.toString()}'));
    }
  }

  Future<void> updatePlantAddress(String address) async {
    emit(SettingsUpdating());
    try {
      await _repository.setSetting(AppConstants.keyPlantAddress, address.trim());
      
      final updatedInfo = _currentPlantInfo!.copyWith(address: address.trim());
      _currentPlantInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Alamat plant berhasil diperbarui',
        storeInfo: _currentInfo!,
        plantInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Gagal update plant address: ${e.toString()}'));
    }
  }

  Future<void> updatePlantCode(String code) async {
    emit(SettingsUpdating());
    try {
      await _repository.setSetting(AppConstants.keyPlantCode, code.trim());
      
      final updatedInfo = _currentPlantInfo!.copyWith(code: code.trim());
      _currentPlantInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Kode plant berhasil diperbarui',
        storeInfo: _currentInfo!,
        plantInfo: updatedInfo,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Gagal update plant code: ${e.toString()}'));
    }
  }

  Future<void> updateStoreName(String name) async {
    if (name.trim().isEmpty) {
      emit(const SettingsError(message: 'Nama toko tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(AppConstants.keyStoreName, name.trim());

      final updatedInfo = _currentInfo!.copyWith(name: name.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Nama toko berhasil diperbarui',
        storeInfo: updatedInfo,
        plantInfo: _currentPlantInfo,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Gagal memperbarui nama: ${e.toString()}'));
    }
  }

  Future<void> updateStoreAddress(String address) async {
    if (address.trim().isEmpty) {
      emit(const SettingsError(message: 'Alamat tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(
          AppConstants.keyStoreAddress, address.trim());

      final updatedInfo = _currentInfo!.copyWith(address: address.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Alamat berhasil diperbarui',
        storeInfo: updatedInfo,
        plantInfo: _currentPlantInfo,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Gagal memperbarui alamat: ${e.toString()}'));
    }
  }

  Future<void> updateStorePhone(String phone) async {
    if (phone.trim().isEmpty) {
      emit(const SettingsError(message: 'Nomor HP tidak boleh kosong'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(AppConstants.keyStorePhone, phone.trim());

      final updatedInfo = _currentInfo!.copyWith(phone: phone.trim());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Nomor HP berhasil diperbarui',
        storeInfo: updatedInfo,
        plantInfo: _currentPlantInfo,
      ));
    } catch (e) {
      emit(
          SettingsError(message: 'Gagal memperbarui nomor HP: ${e.toString()}'));
    }
  }

  Future<void> updateInvoicePrefix(String prefix) async {
    if (prefix.trim().isEmpty) {
      emit(const SettingsError(message: 'Prefix invoice tidak boleh kosong'));
      return;
    }

    if (prefix.trim().length > 10) {
      emit(const SettingsError(message: 'Prefix invoice maksimal 10 karakter'));
      return;
    }

    emit(SettingsUpdating());

    try {
      await _repository.setSetting(
          AppConstants.keyInvoicePrefix, prefix.trim().toUpperCase());

      final updatedInfo =
          _currentInfo!.copyWith(invoicePrefix: prefix.trim().toUpperCase());
      _currentInfo = updatedInfo;

      emit(SettingsUpdated(
        message: 'Prefix invoice berhasil diperbarui',
        storeInfo: updatedInfo,
        plantInfo: _currentPlantInfo,
      ));
    } catch (e) {
      emit(SettingsError(
          message: 'Gagal memperbarui prefix invoice: ${e.toString()}'));
    }
  }
}
