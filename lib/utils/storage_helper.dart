import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class StorageHelper {
  static Future<void> saveSucursal(String sucursal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefsSucursal, sucursal);
  }

  static Future<void> saveServidor(String servidor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefsServidor, servidor);
  }

  static Future<String> getSucursal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefsSucursal) ?? '';
  }

  static Future<String> getServidor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefsServidor) ?? AppConstants.defaultServerApi;
  }
}
