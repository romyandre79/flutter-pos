import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/core/utils/currency_formatter.dart';
import 'package:flutter_pos/core/utils/date_formatter.dart';
import 'package:flutter_pos/logic/cubits/purchase_order/purchase_order_cubit.dart';
import 'package:flutter_pos/logic/cubits/purchase_order/purchase_order_state.dart';
import 'package:flutter_pos/logic/cubits/supplier/supplier_cubit.dart';
import 'package:flutter_pos/presentation/screens/purchasing/purchase_order_create_screen.dart';
import 'package:flutter_pos/presentation/screens/purchasing/purchase_order_detail_screen.dart';
import 'package:flutter_pos/logic/cubits/product/product_cubit.dart';
import 'package:flutter_pos/data/repositories/product_repository.dart';
import 'package:flutter_pos/data/repositories/purchase_order_repository.dart';

class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  State<PurchaseOrderListScreen> createState() => _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PurchaseOrderCubit>().loadPurchaseOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Pembelian'),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppThemeColors.primaryGradient,
          borderRadius: AppRadius.fullRadius,
          boxShadow: AppShadows.purple,
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            final poCubit = context.read<PurchaseOrderCubit>();
            final supplierCubit = context.read<SupplierCubit>();
            final productRepo = context.read<ProductRepository>();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: poCubit),
                    BlocProvider.value(value: supplierCubit),
                    BlocProvider(
                      create: (_) => ProductCubit(productRepo)..loadProducts(),
                    ),
                  ],
                  child: const PurchaseOrderCreateScreen(),
                ),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Pembelian Baru',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: BlocBuilder<PurchaseOrderCubit, PurchaseOrderState>(
        builder: (context, state) {
          if (state is PoLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PoLoaded) {
            if (state.purchaseOrders.isEmpty) {
              return const Center(child: Text('Tidak ada data Pembelian'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.purchaseOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final po = state.purchaseOrders[index];
                return Card(
                  child: ListTile(
                    onTap: () async {
                      // Fetch full PO with items
                      final repo = context.read<PurchaseOrderRepository>();
                      final fullPo = await repo.getPurchaseOrderById(po.id!);
                      if (fullPo != null && context.mounted) {
                        final poCubit = context.read<PurchaseOrderCubit>();
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: poCubit,
                              child: PurchaseOrderDetailScreen(order: fullPo),
                            ),
                          ),
                        );
                        // Reload list after returning from detail (status may have changed)
                        if (context.mounted) {
                          context.read<PurchaseOrderCubit>().loadPurchaseOrders();
                        }
                      }
                    },
                    title: Text('${po.supplier?.name ?? "Unknown"}'),
                    subtitle: Text('${DateFormatter.formatDate(po.orderDate)} - ${po.statusDisplay}'),
                    trailing: Text(
                      CurrencyFormatter.format(po.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            );
          }
          
          if (state is PoError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

