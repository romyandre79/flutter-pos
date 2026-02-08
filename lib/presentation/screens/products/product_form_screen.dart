import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_pos_offline/core/theme/app_theme.dart';
import 'package:flutter_pos_offline/data/models/product.dart';
import 'package:flutter_pos_offline/logic/cubits/product/product_cubit.dart';
import 'package:flutter_pos_offline/logic/cubits/auth/auth_cubit.dart';
import 'package:flutter_pos_offline/logic/cubits/auth/auth_state.dart';
import 'package:flutter_pos_offline/data/models/user.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _costController;
  late TextEditingController _stockController;
  late TextEditingController _durationController;
  late TextEditingController _descriptionController;
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  ProductType _selectedType = ProductType.service;
  String _selectedUnit = 'pcs';

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name);
    _priceController = TextEditingController(text: product?.price.toString());
    _costController = TextEditingController(text: product?.cost.toString() ?? '0');
    _stockController = TextEditingController(text: product?.stock?.toString() ?? '0');
    _durationController = TextEditingController(text: product?.durationDays?.toString() ?? '3');
    _descriptionController = TextEditingController(text: product?.description);

    if (product != null) {
      _selectedType = product.type;
      _selectedUnit = product.unit;
      if (product.imageUrl != null) {
        _imageFile = File(product.imageUrl!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
  }

  Future<String?> _saveImage() async {
    if (_imageFile == null) return null;
    
    // If it's already an existing saved image (checked by path containing app doc dir), just return path
    // tailored for simple check: 
    // real implementation: copy to app directory
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(_imageFile!.path);
      final savedImage = await _imageFile!.copy('${appDir.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      return _imageFile?.path;
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final price = int.parse(_priceController.text);
      final cost = int.parse(_costController.text);
      final description = _descriptionController.text;
      
      final imagePath = await _saveImage();
      
      final product = Product(
        id: widget.product?.id,
        name: name,
        description: description.isEmpty ? null : description,
        price: price,
        cost: cost,
        unit: _selectedUnit,
        type: _selectedType,
        // Optional fields based on type
        stock: _selectedType == ProductType.goods 
            ? int.tryParse(_stockController.text) ?? 0 
            : null,
        durationDays: _selectedType == ProductType.service 
            ? int.tryParse(_durationController.text) ?? 1 
            : null,
        imageUrl: imagePath ?? widget.product?.imageUrl,
      );

      if (widget.product == null) {
        context.read<ProductCubit>().addProduct(product);
      } else {
        context.read<ProductCubit>().updateProduct(product);
      }

      Navigator.pop(context);
    }
  }

  void _deleteProduct() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hapus Item?'),
          content: const Text('Apakah Anda yakin ingin menghapus item ini? Tindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                if (widget.product?.id != null) {
                   context.read<ProductCubit>().deleteProduct(widget.product!.id!);
                   Navigator.pop(context); // Close screen
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Tambah Item' : 'Edit Item',
          style: AppTypography.headlineMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppThemeColors.headerGradient,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.product != null && context.read<AuthCubit>().state is AuthAuthenticated && (context.read<AuthCubit>().state as AuthAuthenticated).user.role == UserRole.owner)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteProduct,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: AppRadius.lgRadius,
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      border: Border.all(color: AppThemeColors.border),
                    ),
                    child: _imageFile == null
                        ? const Icon(Icons.add_a_photo, size: 40, color: AppThemeColors.textSecondary)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Type Selector
              Text('Tipe Item', style: AppTypography.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeRadio(ProductType.service),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildTypeRadio(ProductType.goods),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Item',
                  hintText: 'Contoh: Cuci Kering atau Sabun',
                  prefixIcon: Icon(
                    _selectedType == ProductType.service ? Icons.category_outlined : Icons.inventory_2_outlined,
                    color: AppThemeColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                    borderSide: BorderSide(color: AppThemeColors.border),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama item tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Unit
              TextFormField(
                initialValue: _selectedUnit,
                decoration: InputDecoration(
                  labelText: 'Satuan',
                  hintText: 'kg, pcs, pack',
                  prefixIcon: const Icon(Icons.straighten, color: AppThemeColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                    borderSide: BorderSide(color: AppThemeColors.border),
                  ),
                ),
                onChanged: (val) => _selectedUnit = val,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Satuan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Price & Cost Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Harga Jual',
                        prefixText: 'Rp ',
                        prefixIcon: const Icon(Icons.sell_outlined, color: AppThemeColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.mdRadius,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harga tidak boleh kosong';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Harga harus berupa angka';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Modal (Opsional)',
                        prefixText: 'Rp ',
                        prefixIcon: const Icon(Icons.attach_money, color: AppThemeColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.mdRadius,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Conditional Fields
              if (_selectedType == ProductType.service) ...[
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Estimasi Pengerjaan (Hari)',
                    prefixIcon: const Icon(Icons.schedule, color: AppThemeColors.primary),
                    suffixText: 'Hari',
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdRadius,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Estimasi tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Harus berupa angka';
                    }
                    return null;
                  },
                ),
              ],
              
              if (_selectedType == ProductType.goods) ...[
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Stok Awal',
                    prefixIcon: const Icon(Icons.inventory, color: AppThemeColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdRadius,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Stok tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Harus berupa angka';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: AppSpacing.lg),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Deskripsi (Opsional)',
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.description_outlined, color: AppThemeColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.mdRadius,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdRadius,
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Simpan',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeRadio(ProductType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppThemeColors.primary : Colors.white,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(
            color: isSelected ? AppThemeColors.primary : AppThemeColors.border,
          ),
        ),
        child: Center(
          child: Text(
            type.displayName,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected ? Colors.white : AppThemeColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
