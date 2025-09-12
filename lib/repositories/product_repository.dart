import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import '../models/product_model.dart';
import 'dart:convert';

// Repository para el producto
/*class ProductRepository {
  static Future<ApiResponse<Product>> getProduct(String url) async {
    return await ApiService.request<Product>(
      url,
      fromJson: (json) => Product.fromJson(json),
      timeout: Duration(seconds: 30),
    );
  }
}*/
// Repository para el producto
class ProductRepository {
  static Future<ApiResponse<Product>> getProduct(String url) async {
    try {
      log('=== DEBUG ProductRepository.getProduct ===');
      log('URL solicitada: $url');

      final response = await ApiService.request<Product>(
        url,
        fromJson: (json) {
          try {
            log('=== JSON RECIBIDO EN REPOSITORY ===');
            log(jsonEncode(json));
            log('=== INICIANDO PARSING ===');

            final product = Product.fromJson(json);

            log('=== PARSING EXITOSO ===');
            return product;
          } catch (e, stackTrace) {
            log('=== ERROR EN PARSING ===');
            if (kDebugMode) {
              log('Error: $e');
              log('StackTrace: $stackTrace');
              log('JSON que causó el error: ${jsonEncode(json)}');
            }

            // Re-lanza el error para que se maneje en el nivel superior
            rethrow;
          }
        },
        timeout: Duration(seconds: 30),
      );

      log('=== RESPONSE EXITOSA ===');
      return response;
    } catch (e, stackTrace) {
      log('=== ERROR EN REPOSITORY ===');
      log('Error: $e');
      log('StackTrace: $stackTrace');

      // Puedes retornar un ApiResponse con error o re-lanzar la excepción
      // dependiendo de cómo esté estructurado tu ApiResponse
      rethrow;
    }
  }
}
