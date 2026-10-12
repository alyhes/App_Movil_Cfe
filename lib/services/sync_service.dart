import 'dart:convert';

import 'package:http/http.dart' as http;

import '../database/database_helper.dart';

class SyncService {
  // ============================================================
  // DIRECCIÓN DEL SERVIDOR FASTAPI
  // ============================================================
  //
  // Esta es la IP de tu computadora dentro de la red Wi-Fi.
  // El teléfono se conecta a esta dirección para llegar a Ubuntu.
  //
  static const String baseUrl = 'http://192.168.1.108:8000';

  final DatabaseHelper _database = DatabaseHelper.instance;

  // ============================================================
  // SINCRONIZAR INSPECCIONES PENDIENTES
  // ============================================================

  Future<Map<String, dynamic>> sincronizarInspecciones() async {
    int enviadas = 0;
    int errores = 0;

    try {
      // Obtener inspecciones que todavía no se han sincronizado.
      final inspecciones =
          await _database.obtenerInspeccionesPendientes();

      // Si no hay inspecciones pendientes.
      if (inspecciones.isEmpty) {
        return {
          'exito': true,
          'mensaje':
              'No hay inspecciones pendientes de sincronizar.',
          'enviadas': 0,
          'errores': 0,
        };
      }

      // Recorrer todas las inspecciones pendientes.
      for (final inspeccion in inspecciones) {
        try {
          final int inspeccionId =
              inspeccion['id'] as int;

          // Obtener las anomalías de la inspección.
          final anomalias =
              await _database.obtenerAnomalias(
            inspeccionId,
          );

          // Convertir anomalías a formato JSON.
          final List<Map<String, dynamic>>
              anomaliasJson =
              anomalias.map((anomalia) {
            return {
              'id': anomalia['id'],
              'fecha_revision':
                  anomalia['fecha_revision'],
              'numero_estacion':
                  anomalia['numero_estacion'],
              'anomalia':
                  anomalia['anomalia'],
              'fecha_correccion':
                  anomalia['fecha_correccion'],
            };
          }).toList();

          // ======================================================
          // DATOS COMPLETOS DE LA INSPECCIÓN
          // ======================================================

          final Map<String, dynamic> datos = {
            'id': inspeccion['id'],
            'fecha_inspeccion':
                inspeccion['fecha_inspeccion'],
            'linea_transmision':
                inspeccion['linea_transmision'],
            'zona_transmision':
                inspeccion['zona_transmision'],
            'tipo_inspeccion':
                inspeccion['tipo_inspeccion'],
            'elaboro':
                inspeccion['elaboro'],
            'visto_bueno':
                inspeccion['visto_bueno'],
            'anomalias': anomaliasJson,
          };

          // ======================================================
          // ENVIAR A FASTAPI
          // ======================================================

          final respuesta = await http
              .post(
                Uri.parse(
                  '$baseUrl/inspecciones/',
                ),
                headers: {
                  'Content-Type':
                      'application/json',
                },
                body: jsonEncode(datos),
              )
              .timeout(
                const Duration(seconds: 10),
              );

          // ======================================================
          // RESPUESTA CORRECTA
          // ======================================================

          if (respuesta.statusCode == 200) {
            await _database
                .marcarInspeccionSincronizada(
              inspeccionId,
            );

            enviadas++;
          }

          // ======================================================
          // LA INSPECCIÓN YA EXISTE EN EL SERVIDOR
          // ======================================================

          else if (respuesta.statusCode == 409) {
            await _database
                .marcarInspeccionSincronizada(
              inspeccionId,
            );

            enviadas++;
          }

          // ======================================================
          // OTRO ERROR DEL SERVIDOR
          // ======================================================

          else {
            errores++;
          }
        } catch (e) {
          errores++;
        }
      }

      // ==========================================================
      // RESULTADO FINAL
      // ==========================================================

      if (errores == 0) {
        return {
          'exito': true,
          'mensaje':
              'Sincronización completada correctamente.',
          'enviadas': enviadas,
          'errores': errores,
        };
      }

      return {
        'exito': false,
        'mensaje':
            'La sincronización terminó con algunos errores.',
        'enviadas': enviadas,
        'errores': errores,
      };
    } catch (e) {
      return {
        'exito': false,
        'mensaje':
            'No se pudieron obtener las inspecciones pendientes.',
        'enviadas': enviadas,
        'errores': errores + 1,
      };
    }
  }

  // ============================================================
  // COMPROBAR CONEXIÓN CON FASTAPI
  // ============================================================

  Future<bool> comprobarConexion() async {
    try {
      final respuesta = await http
          .get(
            Uri.parse('$baseUrl/'),
          )
          .timeout(
            const Duration(seconds: 5),
          );

      return respuesta.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}