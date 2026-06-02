import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'api_client.dart';
import 'api_config.dart';

class ProductService {
  final ApiClient _client = ApiClient();

  // ── Public products (no auth required) ───────────────────────────────────

  /// Fetches paginated products. Returns all items from the first page
  /// unless [page] is specified.
  ///
  /// API response: { products: [...], totalProducts, totalPages, currentPage }
  Future<List<Product>> getProducts({
    int page = 1,
    String? category,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{'page': page.toString()};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['name'] = search; // backend param is 'name', not 'search'
      }

      final response = await _client.get(
        ApiConfig.products,
        requiresAuth: false,
        queryParams: queryParams,
      );

      final rawList = _extractProductList(response);
      if (rawList is! List) return [];

      final products = <Product>[];
      for (final item in rawList) {
        try {
          final json = Map<String, dynamic>.from(item as Map);
          final product = Product.fromJson(json);
          if (product.stock > 0) products.add(product);
        } catch (e) {
          debugPrint(
            '[ProductService] Failed to parse product ${_productLabel(item)}: $e',
          );
        }
      }
      return products;
    } on ApiException catch (e) {
      throw Exception('Gagal memuat produk: ${e.message}');
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }

  /// Fetches a single product by ID.
  ///
  /// API response: { success, data: { ...product fields } }
  Future<Product?> getProductDetails(int id) async {
    try {
      final response = await _client.get(
        '${ApiConfig.products}/$id',
        requiresAuth: false,
      );

      final data = response['data'];
      if (data == null) return null;
      return Product.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      throw Exception('Gagal memuat detail produk: ${e.message}');
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }

  List<dynamic>? _extractProductList(Map<String, dynamic> response) {
    final products = response['products'];
    if (products is List) return products;

    final data = response['data'];
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;

    return null;
  }

  String _productLabel(dynamic item) {
    if (item is! Map) return '(unknown item)';
    final id = item['id']?.toString() ?? 'unknown';
    final name = item['name']?.toString() ?? item['title']?.toString() ?? '-';
    return 'id=$id name=$name';
  }

  // ── Seller product operations (auth required) ─────────────────────────────

  /// Creates a new product for the authenticated seller.
  /// [data] must include: name, price, stock_quantity, description, category, condition.
  /// Optionally provide an [imageFile] for the product image.
  Future<Product?> createProduct(Map<String, String> data,
      {File? imageFile}) async {
    try {
      final response = await _client.postMultipart(
        ApiConfig.products,
        data,
        imageFile: imageFile,
      );

      // On success: { success, data: { ...product } }
      final productData = response['data'];
      if (productData == null) return null;
      return Product.fromJson(productData as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception('Gagal membuat produk: ${e.message}');
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }

  /// Updates a seller product. Uses multipart so product images can be replaced.
  Future<Product?> updateProduct(int id, Map<String, String> data,
      {File? imageFile}) async {
    try {
      final response = await _client.postMultipart(
        '${ApiConfig.products}/$id?_method=PATCH',
        data,
        imageFile: imageFile,
      );

      final productData = response['data'];
      if (productData == null) return null;
      return Product.fromJson(productData as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw Exception('Gagal memperbarui produk: ${e.message}');
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }

  /// Deletes a product by ID (seller must own it, or be admin).
  Future<bool> deleteProduct(int id) async {
    try {
      await _client.delete('${ApiConfig.products}/$id');
      return true;
    } on ApiException catch (e) {
      throw Exception('Gagal menghapus produk: ${e.message}');
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }
}
