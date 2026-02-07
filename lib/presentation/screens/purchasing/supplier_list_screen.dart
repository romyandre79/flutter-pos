import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_offline/core/theme/app_theme.dart';
import 'package:flutter_pos_offline/logic/cubits/supplier/supplier_cubit.dart';
import 'package:flutter_pos_offline/logic/cubits/supplier/supplier_state.dart';
import 'package:flutter_pos_offline/presentation/screens/purchasing/supplier_form_screen.dart';

class SupplierListScreen extends StatelessWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger load on build if not loaded
    context.read<SupplierCubit>().loadSuppliers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
          ),
        ],
      ),
      body: BlocBuilder<SupplierCubit, SupplierState>(
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
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
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
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
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
                    },
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
    );
  }
}
