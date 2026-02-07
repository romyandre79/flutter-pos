import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_offline/core/theme/app_theme.dart';
import 'package:flutter_pos_offline/logic/cubits/pos/pos_cubit.dart';
import 'package:flutter_pos_offline/presentation/screens/pos/widgets/cart_panel.dart';
import 'package:flutter_pos_offline/presentation/screens/pos/widgets/service_catalog.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Transaction'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Row(
        children: [
          // Left Side: Service Catalog (65%)
          const Expanded(
            flex: 65,
            child: ServiceCatalog(),
          ),
          
          // Right Side: Cart Panel (35%)
          Expanded(
            flex: 35,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                   left: BorderSide(color: AppThemeColors.border),
                ),
              ),
              child: const CartPanel(),
            ),
          ),
        ],
      ),
    );
  }
}
