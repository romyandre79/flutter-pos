import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_offline/core/theme/app_theme.dart';
import 'package:flutter_pos_offline/logic/cubits/supplier/supplier_cubit.dart';
import 'package:flutter_pos_offline/logic/cubits/supplier/supplier_state.dart';
import 'package:flutter_pos_offline/presentation/screens/purchasing/supplier_form_screen.dart';
import 'package:flutter_pos_offline/logic/cubits/auth/auth_cubit.dart';
import 'package:flutter_pos_offline/logic/cubits/auth/auth_state.dart';
import 'package:flutter_pos_offline/data/models/user.dart';

class SupplierListScreen extends StatelessWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger load on build if not loaded
    context.read<SupplierCubit>().loadSuppliers();
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
              // Add Button
              if (isOwner)
                GestureDetector(
                  onTap: () {
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
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: AppRadius.smRadius,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
