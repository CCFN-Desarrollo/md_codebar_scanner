import 'package:md_codebar_scanner/repositories/product_repository.dart';
import 'package:md_codebar_scanner/services/api_service.dart';
import 'package:md_codebar_scanner/utils/storage_helper.dart';

import '../models/product_model.dart';

class ProductService {
  static Future<ApiResponse<Product>> getCode(String sku) async {
    await Future.delayed(Duration(milliseconds: 500));
    String servidor = await StorageHelper.getServidor();
    String sucursal = await StorageHelper.getSucursal();

    final verifyPriceUrl =
        "${servidor}/v2/products/${sku}/verifyPrice?priceListId=3&warehouseId=${sucursal}&searchBy=codebar";

    return await ProductRepository.getProduct(verifyPriceUrl);
  }
}
