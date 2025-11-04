import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import '../utils/colors.dart';

class DebugLogScreen extends StatefulWidget {
  const DebugLogScreen({super.key});

  @override
  State<DebugLogScreen> createState() => _DebugLogScreenState();
}

class _DebugLogScreenState extends State<DebugLogScreen> {
  List<String> _logs = [];
  bool _isChecking = false;
  String _currentVersion = '';
  String _serverVersion = '';
  bool _isLoggedIn = false;
  String _username = '';
  String _warehouseCode = '';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
  }

  Future<void> _loadDebugInfo() async {
    _addLog('📱 Cargando información del dispositivo...');

    try {
      // Obtener versión actual
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentVersion = packageInfo.version;
      });
      _addLog('✅ Versión actual: $_currentVersion');

      // Obtener info de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        _username = prefs.getString('username') ?? 'No disponible';
        _warehouseCode = prefs.getString('warehouseCode') ?? 'No disponible';
      });
      _addLog('✅ Usuario logueado: $_isLoggedIn');
      _addLog('✅ Username: $_username');
      _addLog('✅ Sucursal: $_warehouseCode');
    } catch (e) {
      _addLog('❌ Error cargando info: $e');
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _logs.clear();
    });

    _addLog('🔄 Iniciando verificación de actualización...');

    try {
      // URL del archivo de versión
      final versionUrl =
          'http://crm.ccfnweb.com.mx/sap10/MD_CODEBAR_SCANNER_VERSION.text';
      _addLog('🌐 URL: $versionUrl');

      // Obtener versión actual
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentVersion = packageInfo.version;
      });
      _addLog('📱 Versión instalada: $_currentVersion');

      // Hacer petición al servidor
      _addLog('📡 Consultando servidor...');
      final response = await http
          .get(Uri.parse(versionUrl))
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Timeout - El servidor no respondió en 10 segundos',
              );
            },
          );

      _addLog('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        setState(() {
          _serverVersion = response.body.trim();
        });
        _addLog('✅ Versión en servidor: $_serverVersion');

        // Comparar versiones
        final needsUpdate = _compareVersions(_currentVersion, _serverVersion);

        if (needsUpdate) {
          _addLog('🎉 ¡HAY ACTUALIZACIÓN DISPONIBLE!');
          _addLog('📦 $_currentVersion → $_serverVersion');
        } else {
          _addLog('✅ Ya tienes la última versión');
        }
      } else {
        _addLog('❌ Error del servidor: ${response.statusCode}');
        _addLog('📄 Respuesta: ${response.body}');
      }
    } catch (e) {
      _addLog('❌ Error: $e');

      if (e.toString().contains('SocketException')) {
        _addLog(
          '🌐 No hay conexión a internet o el servidor no está disponible',
        );
      } else if (e.toString().contains('Timeout')) {
        _addLog('⏱️ Tiempo de espera agotado');
      }
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  bool _compareVersions(String current, String server) {
    try {
      _addLog('🔍 Comparando: "$current" vs "$server"');

      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> serverParts = server.split('.').map(int.parse).toList();

      _addLog('🔍 Current parts: $currentParts');
      _addLog('🔍 Server parts: $serverParts');

      for (int i = 0; i < serverParts.length; i++) {
        if (i < currentParts.length) {
          _addLog(
            '🔍 Comparando posición $i: ${serverParts[i]} vs ${currentParts[i]}',
          );

          if (serverParts[i] > currentParts[i]) {
            _addLog(
              '✅ ${serverParts[i]} > ${currentParts[i]} = ACTUALIZACIÓN DISPONIBLE',
            );
            return true;
          }
          if (serverParts[i] < currentParts[i]) {
            _addLog('❌ ${serverParts[i]} < ${currentParts[i]} = VERSIÓN MENOR');
            return false;
          }
          _addLog('➡️ ${serverParts[i]} == ${currentParts[i]} = CONTINUAR');
        } else {
          if (serverParts[i] > 0) {
            _addLog(
              '✅ Versión servidor tiene más partes = ACTUALIZACIÓN DISPONIBLE',
            );
            return true;
          }
        }
      }
      _addLog('✅ Todas las partes son iguales = MISMA VERSIÓN');
      return false;
    } catch (e) {
      _addLog('❌ Error comparando versiones: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug - Logs'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                _logs.clear();
              });
            },
            tooltip: 'Limpiar logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Información del sistema
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: AppColors.primary.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información del Sistema',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 8),
                _buildInfoRow('Versión Actual', _currentVersion),
                _buildInfoRow(
                  'Versión Servidor',
                  _serverVersion.isEmpty ? 'No consultado' : _serverVersion,
                ),
                _buildInfoRow('Logueado', _isLoggedIn ? 'Sí' : 'No'),
                _buildInfoRow('Usuario', _username),
                _buildInfoRow('Sucursal', _warehouseCode),
              ],
            ),
          ),

          // Botón de verificar actualización
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkForUpdates,
                icon: _isChecking
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(Icons.refresh),
                label: Text(
                  _isChecking ? 'Verificando...' : 'Verificar Actualización',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          // Lista de logs
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay logs aún',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Presiona "Verificar Actualización" para ver logs',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color logColor = AppColors.textPrimary;
                      IconData logIcon = Icons.circle;

                      if (log.contains('❌') || log.contains('Error')) {
                        logColor = AppColors.error;
                        logIcon = Icons.error_outline;
                      } else if (log.contains('✅')) {
                        logColor = AppColors.success;
                        logIcon = Icons.check_circle_outline;
                      } else if (log.contains('🔄') || log.contains('📡')) {
                        logColor = AppColors.info;
                        logIcon = Icons.sync;
                      } else if (log.contains('🎉')) {
                        logColor = AppColors.primary;
                        logIcon = Icons.celebration;
                      }

                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: logColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: logColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(logIcon, size: 18, color: logColor),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                log,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: logColor,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
