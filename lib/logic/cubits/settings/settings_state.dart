import 'package:equatable/equatable.dart';

class StoreInfo {
  final String name;
  final String address;
  final String phone;
  final String invoicePrefix;
  final String machineNumber;

  const StoreInfo({
    required this.name,
    required this.address,
    required this.phone,
    required this.invoicePrefix,
    required this.machineNumber,
  });

  StoreInfo copyWith({
    String? name,
    String? address,
    String? phone,
    String? invoicePrefix,
    String? machineNumber,
  }) {
    return StoreInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      machineNumber: machineNumber ?? this.machineNumber,
    );
  }
}

class PlantInfo {
  final String name;
  final String address;
  final String code;

  const PlantInfo({
    required this.name,
    required this.address,
    required this.code,
  });

  PlantInfo copyWith({
    String? name,
    String? address,
    String? code,
  }) {
    return PlantInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      code: code ?? this.code,
    );
  }
}

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final StoreInfo storeInfo;
  final PlantInfo? plantInfo;

  const SettingsLoaded({
    required this.storeInfo,
    this.plantInfo,
  });

  @override
  List<Object?> get props => [storeInfo, plantInfo];
}

class SettingsUpdating extends SettingsState {}

class SettingsUpdated extends SettingsState {
  final String message;
  final StoreInfo storeInfo;
  final PlantInfo? plantInfo;

  const SettingsUpdated({
    required this.message,
    required this.storeInfo,
    this.plantInfo,
  });

  @override
  List<Object?> get props => [message, storeInfo, plantInfo];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError({required this.message});

  @override
  List<Object?> get props => [message];
}
