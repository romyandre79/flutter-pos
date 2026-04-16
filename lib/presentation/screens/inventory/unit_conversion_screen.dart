import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_pos/core/theme/app_theme.dart';
import 'package:kreatif_pos/data/models/product.dart';
import 'package:kreatif_pos/data/models/product_unit.dart';
import 'package:kreatif_pos/data/repositories/product_repository.dart';
import 'package:kreatif_pos/logic/cubits/product/product_cubit.dart';
import 'package:kreatif_pos/logic/cubits/product/product_state.dart';

class UnitConversionScreen extends StatefulWidget {
  const UnitConversionScreen({super.key});

  @override
  State<UnitConversionScreen> createState() => _UnitConversionScreenState();
}

class _UnitConversionScreenState extends State<UnitConversionScreen> {
  Product? _selectedProduct;
  ProductUnit? _fromUnit;
  ProductUnit? _toUnit;
  final TextEditingController _qtyController = TextEditingController(text: '1');
  bool _isProcessing = false;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _processConversion() async {
    if (_selectedProduct == null || _fromUnit == null || _toUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk and satuan dengan benar'), backgroundColor: Colors.red),
      );
      return;
    }

    final qty = double.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_fromUnit!.stock < qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok asal tidak mencukupi'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Calculate multiplier relative to base or simple cross-unit conversion
      // For simplicity, we use the logic from ProductRepository if units are chained
      // Here we assume simple manual conversion based on user input
      
      double multiplier = 1.0;
      // If converting FROM parent TO child
      if (_toUnit!.parentUnitId == _fromUnit!.id) {
        multiplier = _toUnit!.multiplier;
      } else {
        // Fallback for non-direct chain: ask user or detect etc.
        // In klinik logic we used direct multiplier if chained.
        // Let's keep it simple: user must select correct chain.
        multiplier = _toUnit!.multiplier; 
      }

      await context.read<ProductRepository>().convertUnit(
        productId: _selectedProduct!.id!,
        fromUnitId: _fromUnit!.id!,
        toUnitId: _toUnit!.id!,
        fromQty: qty,
        multiplier: multiplier,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konversi berhasil'), backgroundColor: Colors.green),
        );
        context.read<ProductCubit>().loadProducts();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konversi Stok', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppThemeColors.headerGradient)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) return const Center(child: CircularProgressIndicator());
          if (state is ProductLoaded) {
            final goods = state.products.where((p) => p.isGoods && p.units.length > 1).toList();
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Produk', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Product>(
                    value: _selectedProduct,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Pilih Produk'),
                    items: goods.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    onChanged: (p) {
                      setState(() {
                        _selectedProduct = p;
                        _fromUnit = null;
                        _toUnit = null;
                      });
                    },
                  ),
                  if (_selectedProduct != null) ...[
                    const SizedBox(height: 24),
                    const Text('Dari Satuan', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ProductUnit>(
                      value: _fromUnit,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _selectedProduct!.units.map((u) => DropdownMenuItem(value: u, child: Text('${u.unitName} (Stok: ${u.stock})'))).toList(),
                      onChanged: (u) => setState(() => _fromUnit = u),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ke Satuan', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ProductUnit>(
                      value: _toUnit,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: _selectedProduct!.units.where((u) => u.id != _fromUnit?.id).map((u) => DropdownMenuItem(value: u, child: Text(u.unitName))).toList(),
                      onChanged: (u) => setState(() => _toUnit = u),
                    ),
                    const SizedBox(height: 16),
                    const Text('Jumlah Dikonversi', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        suffixText: _fromUnit?.unitName ?? '',
                      ),
                    ),
                    if (_fromUnit != null && _toUnit != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          'Hasil: ${double.tryParse(_qtyController.text) ?? 0} ${_fromUnit!.unitName} akan menjadi ${(double.tryParse(_qtyController.text) ?? 0) * _toUnit!.multiplier} ${_toUnit!.unitName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processConversion,
                        style: ElevatedButton.styleFrom(backgroundColor: AppThemeColors.primary),
                        child: _isProcessing 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text('PROSES KONVERSI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          return const Center(child: Text('Gagal memuat produk'));
        },
      ),
    );
  }
}
