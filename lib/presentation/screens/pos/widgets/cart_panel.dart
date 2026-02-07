import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_offline/core/theme/app_theme.dart';
import 'package:flutter_pos_offline/core/utils/currency_formatter.dart';
import 'package:flutter_pos_offline/data/models/order_item.dart';
import 'package:flutter_pos_offline/data/models/payment.dart';
import 'package:flutter_pos_offline/logic/cubits/order/order_cubit.dart';
import 'package:flutter_pos_offline/logic/cubits/order/order_state.dart';
import 'package:flutter_pos_offline/logic/cubits/pos/pos_cubit.dart';
import 'package:flutter_pos_offline/logic/cubits/pos/pos_state.dart';
import 'package:flutter_pos_offline/presentation/widgets/payment_dialog.dart';

class CartPanel extends StatelessWidget {
  const CartPanel({super.key});

  void _handleCharge(BuildContext context, int totalAmount) {
    // Capture the cubit from the current context
    final posCubit = context.read<PosCubit>();
    
    showDialog(
      context: context,
      builder: (ctx) => PaymentDialog(
        totalAmount: totalAmount,
        onConfirm: (paidAmount, paymentMethod) {
          // Use the captured cubit
          _processCheckout(context, posCubit, paidAmount, paymentMethod);
        },
      ),
    );
  }

  void _processCheckout(
    BuildContext context,
    PosCubit posCubit,
    int paidAmount,
    PaymentMethod paymentMethod,
  ) {
    final posState = posCubit.state;
    if (posState is! PosLoaded) return;

    final cartItems = posState.cartItems;
    if (cartItems.isEmpty) return;

    // Convert CartItems to OrderItems
    final orderItems = cartItems.map((item) {
      return OrderItem(
        orderId: 0, // Placeholder
        productId: item.product.id,
        serviceName: item.product.name, // Using serviceName for product name compatibility
        quantity: item.quantity.toDouble(),
        unit: item.product.unit,
        pricePerUnit: item.product.price,
        subtotal: item.subtotal,
      );
    }).toList();

    context.read<OrderCubit>().createOrder(
      customerName: 'Walk-in Customer', // Default for POS
      items: orderItems,
      dueDate: DateTime.now(), // Completed immediately
      initialPayment: paidAmount,
      paymentMethod: paymentMethod,
      createdBy: 1, // TODO: Get from AuthCubit
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderCubit, OrderState>(
      listener: (context, state) {
        if (state is OrderCreated) {
          context.read<PosCubit>().clearCart();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order ${state.order.invoiceNo} berhasil dibuat'),
              backgroundColor: AppThemeColors.success,
            ),
          );
        } else if (state is OrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppThemeColors.error,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            left: BorderSide(color: AppThemeColors.border),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppThemeColors.border),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Order',
                    style: AppTypography.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppThemeColors.error),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear Cart?'),
                          content: const Text('Are you sure you want to remove all items?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<PosCubit>().clearCart();
                                Navigator.pop(ctx);
                              },
                              child: const Text('Clear', style: TextStyle(color: AppThemeColors.error)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Cart Items List
            Expanded(
              child: BlocBuilder<PosCubit, PosState>(
                builder: (context, state) {
                  if (state is PosLoaded) {
                    if (state.cartItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              size: 48,
                              color: AppThemeColors.disabled,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Cart is Empty',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppThemeColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: state.cartItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = state.cartItems[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quantity Controls
                              Column(
                                children: [
                                  InkWell(
                                    onTap: () => context.read<PosCubit>().addToCart(item.product),
                                    child: const Icon(Icons.add_circle, color: AppThemeColors.primary, size: 20),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Text('${item.quantity}', style: AppTypography.labelLarge),
                                  ),
                                  InkWell(
                                    onTap: () => context.read<PosCubit>().removeFromCart(item),
                                    child: const Icon(Icons.remove_circle, color: AppThemeColors.error, size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(width: AppSpacing.md),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, style: AppTypography.bodyMedium),
                                    Text(
                                      '@ ${CurrencyFormatter.format(item.product.price)}',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              // Subtotal
                              Text(
                                CurrencyFormatter.format(item.subtotal),
                                style: AppTypography.labelLarge,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),

            // Footer (Total & Checkout)
            BlocBuilder<PosCubit, PosState>(
              builder: (context, state) {
                int total = 0;
                if (state is PosLoaded) {
                   total = state.totalAmount;
                }

                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: AppTypography.titleMedium),
                          Text(
                            CurrencyFormatter.format(total),
                            style: AppTypography.titleLarge.copyWith(color: AppThemeColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          ),
                          onPressed: total > 0 
                            ? () => _handleCharge(context, total)
                            : null,
                          child: Text(
                             total > 0 ? 'Charge ${CurrencyFormatter.format(total)}' : 'Charge',
                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
