import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/core/utils/currency_formatter.dart';
import 'package:flutter_pos/core/utils/date_formatter.dart';
import 'package:flutter_pos/logic/cubits/purchase_order/purchase_order_cubit.dart';
import 'package:flutter_pos/logic/cubits/purchase_order/purchase_order_state.dart';
import 'package:flutter_pos/logic/cubits/supplier/supplier_cubit.dart';
import 'package:flutter_pos/presentation/screens/purchasing/purchase_order_create_screen.dart';
import 'package:flutter_pos/logic/cubits/auth/auth_cubit.dart';
import 'package:flutter_pos/logic/cubits/auth/auth_state.dart';
import 'package:flutter_pos/data/models/user.dart';
import 'package:flutter_pos/logic/cubits/product/product_cubit.dart';
import 'package:flutter_pos/data/repositories/product_repository.dart';

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
            // ProductCubit is likely available in MainScreen context, or we create a new one.
            // Since ProductRepository is available, we can create a new ProductCubit
            // or pass the existing one if we can find it. 
            // MainScreen doesn't seem to expose ProductCubit globally (only inside tabs).
            // So we create a new one or use BlocProvider.value if we are in scope.
            // Dashboard has OrderCubit. POS has PosCubit. Settings has UserCubit.
            // ProductListScreen has ProductCubit.
            // So here we validly create a new one using the repository.
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
            'Pesan Baru',
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
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final po = state.purchaseOrders[index];
                return Card(
                  child: ExpansionTile(
                    leading: Icon(
                      po.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                      color: po.isSynced ? Colors.green : Colors.grey,
                    ),
                    title: Text('${po.supplier?.name}'),
                    subtitle: Text('${DateFormatter.formatDate(po.orderDate)} - ${po.status.toUpperCase()}'),
                    trailing: Text(
                      CurrencyFormatter.format(po.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                       if (po.status == 'pending')
                         Padding(
                           padding: const EdgeInsets.all(8.0),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.end,
                             children: [
                               if (context.read<AuthCubit>().state is AuthAuthenticated && (context.read<AuthCubit>().state as AuthAuthenticated).user.role == UserRole.owner)
                                 TextButton(
                                   onPressed: () {
                                     showDialog(
                                       context: context,
                                       builder: (ctx) => AlertDialog(
                                         title: const Text('Hapus Pembelian?'),
                                         content: const Text('Are you sure you want to delete this order?'),
                                         actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                context.read<PurchaseOrderCubit>().deletePurchaseOrder(po.id!);
                                              },
                                              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                            ),
                                         ],
                                       ),
                                     );
                                   },
                                   child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                 ),
                               const SizedBox(width: 8),
                               OutlinedButton(
                                 onPressed: () {
                                    context.read<PurchaseOrderCubit>().updateStatus(po.id!, 'received'); // Simple status update for now
                                 },
                                 child: const Text('Terima Barang'),
                               ),
                             ],
                           ),
                         ),
                    ],
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
