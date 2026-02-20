import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/data/repositories/supplier_repository.dart';
import 'package:flutter_pos/logic/cubits/supplier/supplier_cubit.dart';
import 'package:flutter_pos/logic/cubits/supplier/supplier_state.dart';
import 'package:flutter_pos/presentation/screens/purchasing/supplier_form_screen.dart';
import 'package:flutter_pos/logic/cubits/auth/auth_cubit.dart';
import 'package:flutter_pos/logic/cubits/auth/auth_state.dart';
import 'package:flutter_pos/data/models/user.dart';
import 'package:flutter_pos/core/services/import_service.dart';
import 'package:flutter_pos/core/services/export_service.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final ImportService _importService = ImportService();
  final ExportService _exportService = ExportService();

  @override
  void initState() {
    super.initState();
    context.read<SupplierCubit>().loadSuppliers();
  }

  Future<void> _downloadTemplate() async {
    try {
       final path = await _exportService.downloadSupplierTemplate();
       if (path != null) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Template disimpan di: $path'), backgroundColor: Colors.green),
           );
         }
       }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal download template: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importSuppliers() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final suppliers = await _importService.parseSuppliersFromExcel(file);
        
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi Import'),
            content: Text('Akan mengimport ${suppliers.length} supplier. Lanjutkan?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Add all suppliers
                  final repo = context.read<SupplierRepository>();
                  int count = 0;
                  for (final supplier in suppliers) {
                    await repo.addSupplier(supplier);
                    count++;
                  }
                  
                  if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Berhasil mengimport $count supplier'), backgroundColor: Colors.green),
                     );
                     context.read<SupplierCubit>().loadSuppliers();
                  }
                },
                child: const Text('Import'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal import: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final isOwner = authState is AuthAuthenticated && authState.user.role == UserRole.owner;

    return Scaffold(
      backgroundColor: AppThemeColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(context, isOwner),

          // Content
          Expanded(
            child: BlocBuilder<SupplierCubit, SupplierState>(
              builder: (context, state) {
                if (state is SupplierLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SupplierLoaded) {
                  if (state.suppliers.isEmpty) {
                    return const Center(child: Text('No suppliers found'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.suppliers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final supplier = state.suppliers[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppThemeColors.primarySurface,
                            child: Text(supplier.name[0].toUpperCase()),
                          ),
                          title: Text(supplier.name, style: AppTypography.titleMedium),
                          subtitle: Text(supplier.contactPerson ?? supplier.phone ?? 'No contact info'),
                          trailing: isOwner ? const Icon(Icons.chevron_right) : null,
                          onTap: isOwner
                              ? () {
                                  final cubit = context.read<SupplierCubit>();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: cubit,
                                        child: SupplierFormScreen(supplier: supplier),
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      );
                    },
                  );
                } else if (state is SupplierError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context, isOwner),
    );
  }

  Widget _buildHeader(BuildContext context, bool isOwner) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppThemeColors.headerGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Title
              Expanded(
                child: Text(
                  'Suppliers',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Menu Actions
              if (isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                     switch (value) {
                       case 'template':
                         _downloadTemplate();
                         break;
                       case 'import':
                         _importSuppliers();
                         break;
                     }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'template',
                      child: Row(
                        children: [
                           Icon(Icons.download, color: Colors.blue),
                           SizedBox(width: 8),
                           Text('Download Template Excel'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                           Icon(Icons.upload_file, color: Colors.green),
                           SizedBox(width: 8),
                           Text('Import dari Excel'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, bool isOwner) {
    if (!isOwner) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: AppThemeColors.primaryGradient,
        borderRadius: AppRadius.fullRadius,
        boxShadow: AppShadows.purple,
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          final cubit = context.read<SupplierCubit>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: const SupplierFormScreen(),
              ),
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Tambah Supplier',
          style: AppTypography.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
