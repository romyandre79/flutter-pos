import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos_offline/data/models/product.dart';
import 'package:flutter_pos_offline/data/repositories/product_repository.dart';
import 'package:flutter_pos_offline/logic/cubits/product/product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _productRepository;
  List<Product> _products = [];

  ProductCubit(this._productRepository) : super(ProductInitial());
  
  List<Product> get products => _products;

  Future<void> loadProducts({ProductType? type, bool activeOnly = true}) async {
    emit(ProductLoading());
    try {
      _products = await _productRepository.getProducts(type: type, activeOnly: activeOnly);
      emit(ProductLoaded(_products));
    } catch (e) {
      emit(ProductError('Gagal memuat data: ${e.toString()}'));
    }
  }

  Future<void> addProduct(Product product) async {
    emit(ProductLoading());
    try {
      await _productRepository.addProduct(product);
      await loadProducts(); // Reload
      emit(ProductLoaded(_products)); // Emit loaded first to show list
      emit(const ProductOperationSuccess('Berhasil menambahkan item'));
      emit(ProductLoaded(_products)); // Re-emit loaded state
    } catch (e) {
      emit(ProductError('Gagal menambahkan item: ${e.toString()}'));
      emit(ProductLoaded(_products)); // Return to loaded state on error
    }
  }

  Future<void> updateProduct(Product product) async {
    emit(ProductLoading());
    try {
      await _productRepository.updateProduct(product);
      await loadProducts();
      emit(ProductLoaded(_products));
      emit(const ProductOperationSuccess('Berhasil memperbarui item'));
      emit(ProductLoaded(_products));
    } catch (e) {
      emit(ProductError('Gagal memperbarui item: ${e.toString()}'));
      emit(ProductLoaded(_products));
    }
  }

  Future<void> deleteProduct(int id) async {
    emit(ProductLoading());
    try {
      await _productRepository.deleteProduct(id);
      await loadProducts();
      emit(ProductLoaded(_products));
      emit(const ProductOperationSuccess('Berhasil menghapus item'));
      emit(ProductLoaded(_products));
    } catch (e) {
      emit(ProductError('Gagal menghapus item: ${e.toString()}'));
      emit(ProductLoaded(_products));
    }
  }
}
