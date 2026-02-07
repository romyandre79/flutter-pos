import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_offline/core/theme/app_theme.dart';
import 'package:flutter_pos_offline/core/utils/currency_formatter.dart';
import 'package:flutter_pos_offline/core/utils/date_formatter.dart';
import 'package:flutter_pos_offline/data/models/purchase_order.dart';
import 'package:flutter_pos_offline/data/models/purchase_order_item.dart';
import 'package:flutter_pos_offline/data/models/supplier.dart';
import 'package:flutter_pos_offline/logic/cubits/purchase_order/purchase_order_cubit.dart';
import 'package:flutter_pos_offline/logic/cubits/purchase_order/purchase_order_state.dart';
import 'package:flutter_pos_offline/logic/cubits/supplier/supplier_cubit.dart';
import 'package:flutter_pos_offline/logic/cubits/supplier/supplier_state.dart';

class PurchaseOrderCreateScreen extends StatefulWidget {
  const PurchaseOrderCreateScreen({super.key});

  @override
  State<PurchaseOrderCreateScreen> createState() => _PurchaseOrderCreateScreenState();
}

class _PurchaseOrderCreateScreenState extends State<PurchaseOrderCreateScreen> {
  Supplier? _selectedSupplier;
  final List<PurchaseOrderItem> _items = [];
  final TextEditingController _notesController = TextEditingController();
  DateTime _expectedDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    // Load suppliers
    context.read<SupplierCubit>().loadSuppliers();
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (ctx) => _AddItemDialog(
        onConfirm: (item) {
          setState(() {
            _items.add(item);
          });
        },
      ),
    );
  }

  void _editItem(int index) {
    showDialog(
      context: context,
      builder: (ctx) => _AddItemDialog(
        existingItem: _items[index],
        onConfirm: (item) {
          setState(() {
            _items[index] = item;
          });
        },
      ),
    );
  }

  void _submit() {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    final totalAmount = _items.fold(0, (sum, item) => sum + item.subtotal);

    final po = PurchaseOrder(
      supplierId: _selectedSupplier!.id!,
      orderDate: DateTime.now(),
      expectedDate: _expectedDate,
      status: 'pending',
      totalAmount: totalAmount,
      notes: _notesController.text,
      items: _items,
    );

    context.read<PurchaseOrderCubit>().createPurchaseOrder(po);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              bool isSupplierSelected = _selectedSupplier != null;
               if (!isSupplierSelected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a supplier first')),
                  );
                  return;
              }
              _addItem();
            },
          ),
        ],
      ),
      body: BlocListener<PurchaseOrderCubit, PurchaseOrderState>(
        listener: (context, state) {
          if (state is PoOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            Navigator.pop(context);
          } else if (state is PoError) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: Column(
          children: [
            // Header Form
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: Colors.white,
              child: Column(
                children: [
                   // Supplier Dropdown
                   BlocBuilder<SupplierCubit, SupplierState>(
                     builder: (context, state) {
                       if (state is SupplierLoaded) {
                         return DropdownButtonFormField<Supplier>(
                           value: _selectedSupplier,
                           decoration: const InputDecoration(labelText: 'Supplier'),
                           items: state.suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                           onChanged: (val) => setState(() => _selectedSupplier = val),
                         );
                       }
                       return const LinearProgressIndicator(); // Loading suppliers
                     },
                   ),
                   const SizedBox(height: AppSpacing.sm),
                   // Expected Date
                   ListTile(
                     title: const Text('Expected Date'),
                     subtitle: Text(DateFormatter.formatDate(_expectedDate)),
                     trailing: const Icon(Icons.calendar_today),
                     contentPadding: EdgeInsets.zero,
                     onTap: () async {
                       final date = await showDatePicker(
                         context: context,
                         initialDate: _expectedDate,
                         firstDate: DateTime.now(),
                         lastDate: DateTime.now().add(const Duration(days: 365)),
                       );
                       if (date != null) setState(() => _expectedDate = date);
                     },
                   ),
                ],
              ),
            ),
            const Divider(),
            
            // Items List
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('No items added'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          title: Text(item.itemName),
                          subtitle: Text('${item.quantity} x ${CurrencyFormatter.format(item.cost)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(CurrencyFormatter.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editItem(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setState(() => _items.removeAt(index)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        CurrencyFormatter.format(_items.fold(0, (sum, i) => sum + i.subtotal)),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppThemeColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Create Purchase Order'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  final PurchaseOrderItem? existingItem;
  final Function(PurchaseOrderItem) onConfirm;

  const _AddItemDialog({this.existingItem, required this.onConfirm});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _costController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      _nameController.text = widget.existingItem!.itemName;
      _qtyController.text = widget.existingItem!.quantity.toString();
      _costController.text = widget.existingItem!.cost.toString();
    }
  }

  void _submit() {
    if (_nameController.text.isEmpty || _qtyController.text.isEmpty || _costController.text.isEmpty) return;
    
    final qty = int.tryParse(_qtyController.text) ?? 0;
    final cost = int.tryParse(_costController.text) ?? 0;
    
    if (qty <= 0 || cost <= 0) return;

    final item = PurchaseOrderItem(
      id: widget.existingItem?.id,
      itemName: _nameController.text,
      quantity: qty,
      cost: cost,
      subtotal: qty * cost,
    );
    
    widget.onConfirm(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      title: Text(widget.existingItem != null ? 'Edit Item' : 'Add Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
                filled: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _qtyController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
                filled: true,
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _costController,
              decoration: const InputDecoration(
                labelText: 'Cost per Unit',
                border: OutlineInputBorder(),
                filled: true,
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
          child: Text(widget.existingItem != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
