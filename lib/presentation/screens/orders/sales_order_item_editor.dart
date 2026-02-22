import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/core/theme/app_theme.dart';
import 'package:flutter_pos/core/utils/currency_formatter.dart';
import 'package:flutter_pos/data/models/order_item.dart';
import 'package:flutter_pos/data/models/product.dart';
import 'package:flutter_pos/data/models/unit.dart';
import 'package:flutter_pos/logic/cubits/unit/unit_cubit.dart';

class SalesOrderItemEditor extends StatefulWidget {
  final OrderItem? existingItem;
  final List<Product> products;

  const SalesOrderItemEditor({
    super.key,
    this.existingItem,
    required this.products,
  });

  @override
  State<SalesOrderItemEditor> createState() => _SalesOrderItemEditorState();
}

class _SalesOrderItemEditorState extends State<SalesOrderItemEditor> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _searchController = TextEditingController();
  
  Product? _selectedProduct;
  List<Product> _filteredProducts = [];
  bool _showSearchResults = false;
  String _selectedUnit = 'pcs';
  
  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _nameController.text = item.serviceName;
      _qtyController.text = item.quantity.toString();
      _priceController.text = item.pricePerUnit.toString();
      _selectedUnit = item.unit;
      
      if (item.productId != null) {
        try {
          _selectedProduct = widget.products.firstWhere((p) => p.id == item.productId);
          _searchController.text = _selectedProduct!.name;
        } catch (_) {
          _searchController.text = item.serviceName;
        }
      } else {
        _searchController.text = item.serviceName;
      }
    }
    
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = [];
        _showSearchResults = false;
        return;
      }

      _filteredProducts = widget.products
          .where((p) => 
               p.name.toLowerCase().contains(query) || 
               (p.barcode != null && p.barcode!.contains(query)))
          .take(5)
          .toList();
      
      _showSearchResults = _selectedProduct == null || _selectedProduct!.name.toLowerCase() != query;
      
      if (_selectedProduct == null) {
         _nameController.text = _searchController.text;
      }
    });
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedProduct = product;
      _searchController.text = product.name;
      _nameController.text = product.name;
      _priceController.text = product.price.toString();
      _selectedUnit = product.unit;
      _showSearchResults = false; 
    });
  }

  void _submit() {
    if (_nameController.text.isEmpty && _searchController.text.isNotEmpty) {
      _nameController.text = _searchController.text;
    }

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama item harus diisi')),
      );
      return;
    }
    
    final qty = double.tryParse(_qtyController.text) ?? 0;
    final price = int.tryParse(_priceController.text) ?? 0;
    
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    // Validate Stock
    if (_selectedProduct != null && _selectedProduct!.isGoods) {
      final currentStock = _selectedProduct!.stock ?? 0;
      if (qty > currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Stok ${_selectedProduct!.name} tidak mencukupi (Sisa: ${currentStock.toStringAsFixed(0)})'),
            backgroundColor: AppThemeColors.error,
          ),
        );
        return;
      }
    }

    final item = OrderItem(
      id: widget.existingItem?.id,
      orderId: widget.existingItem?.orderId ?? 0,
      productId: _selectedProduct?.id ?? widget.existingItem?.productId,
      serviceName: _nameController.text,
      quantity: qty,
      unit: _selectedUnit,
      pricePerUnit: price,
      subtotal: (qty * price).round(),
    );
    
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.existingItem != null ? 'Ubah Item' : 'Tambah Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search / Name
            Text('Cari Produk / Nama Item', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ketik nama produk atau scan barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear), 
                      onPressed: () {
                         setState(() {
                           _selectedProduct = null;
                           _searchController.clear();
                           _nameController.clear();
                           _priceController.clear();
                           _showSearchResults = false;
                         });
                      }
                    )
                  : null,
                border: const OutlineInputBorder(),
              ),
            ),
            
            // Search Results
            if (_showSearchResults && _filteredProducts.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filteredProducts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return ListTile(
                      title: Text(product.name, style: AppTypography.bodyMedium),
                      subtitle: Text(
                        '${CurrencyFormatter.format(product.price)} | Stok: ${product.stock ?? '-'} ${product.unit}',
                        style: AppTypography.bodySmall.copyWith(color: AppThemeColors.textSecondary),
                      ),
                      onTap: () => _selectProduct(product),
                    );
                  },
                ),
              ),
              
            const SizedBox(height: AppSpacing.lg),
            
            // Quantity & Unit Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jumlah', style: AppTypography.labelMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _qtyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: '0',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Satuan', style: AppTypography.labelMedium),
                      const SizedBox(height: 8),
                      BlocBuilder<UnitCubit, UnitState>(
                        builder: (context, state) {
                          List<Unit> units = [];
                          if (state is UnitLoaded) units = state.units;
                          
                          final isValid = units.any((u) => u.name == _selectedUnit);
                          
                          return DropdownButtonFormField<String>(
                            value: isValid ? _selectedUnit : null,
                            hint: Text(_selectedUnit),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: units.map((u) => DropdownMenuItem(
                              value: u.name,
                              child: Text(u.name),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedUnit = val);
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Price
            Text('Harga Satuan', style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
                helperText: 'Harga jual per unit',
              ),
            ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Simpan Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
