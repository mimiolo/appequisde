// Helper para abrir ubicaciones en Google Maps.
// Con fallback al navegador si el intent externo falla.
import 'package:url_launcher/url_launcher.dart';

class LocationHelper {
  /// Abre Google Maps en las coordenadas o búsqueda dada.
  static Future<bool> abrirMapa({
    double? lat,
    double? lng,
    String? buscar,
  }) async {
    Uri uri;

    if (lat != null && lng != null) {
      // Abre el mapa centrado en las coordenadas
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    } else if (buscar != null && buscar.isNotEmpty) {
      // Búsqueda por texto
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(buscar)}',
      );
    } else {
      uri = Uri.parse('https://www.google.com/maps');
    }

    return _abrirUri(uri);
  }

  /// Abre Google Maps con ruta desde la ubicación actual hasta el destino.
  static Future<bool> abrirRuta({
    required double destinoLat,
    required double destinoLng,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destinoLat,$destinoLng&travelmode=driving',
    );
    return _abrirUri(uri);
  }

  /// Intenta abrir la URI. Estrategia:
  /// 1. Probar con LaunchMode.externalApplication (abre app nativa)
  /// 2. Si falla, probar con LaunchMode.platformDefault (abre en navegador)
  /// 3. Si falla, probar con LaunchMode.inAppWebView (dentro de la app)
  static Future<bool> _abrirUri(Uri uri) async {
    print('🔗 Intentando abrir: $uri');

    // Intento 1: App externa (Google Maps app)
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('✅ Abierto en app externa');
        return true;
      }
    } catch (e) {
      print('⚠️ Falló externalApplication: $e');
    }

    // Intento 2: Plataforma default (navegador)
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
      print('✅ Abierto en navegador');
      return true;
    } catch (e) {
      print('⚠️ Falló platformDefault: $e');
    }

    // Intento 3: Dentro de la app
    try {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
      print('✅ Abierto en WebView interno');
      return true;
    } catch (e) {
      print('❌ Error definitivo al abrir URI: $e');
      return false;
    }
  }
}
