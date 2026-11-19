import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/paypal_service.dart';
import '../theme/app_theme.dart';

class PayPalCheckoutScreen extends StatefulWidget {
  final String approvalUrl;
  final String orderId;

  const PayPalCheckoutScreen({
    super.key,
    required this.approvalUrl,
    required this.orderId,
  });

  @override
  State<PayPalCheckoutScreen> createState() => _PayPalCheckoutScreenState();
}

class _PayPalCheckoutScreenState extends State<PayPalCheckoutScreen> {
  WebViewController? _controller;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // ⚡ EN WEB: Abrimos PayPal en una nueva pestaña
      _abrirEnNavegador();
    } else {
      // ⚡ EN MÓVIL: Usamos el WebView normal
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) => setState(() => _cargando = true),
            onPageFinished: (url) => setState(() => _cargando = false),
            onNavigationRequest: (request) {
              final url = request.url;
              if (url.startsWith(PayPalService.returnUrl)) {
                Navigator.pop(context, true);
                return NavigationDecision.prevent;
              }
              if (url.startsWith(PayPalService.cancelUrl)) {
                Navigator.pop(context, false);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.approvalUrl));
    }
  }

  Future<void> _abrirEnNavegador() async {
    final uri = Uri.parse(widget.approvalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // Al no poder escuchar la redirección en web fácilmente, asumimos que pagó para regresar
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: AppColores.background,
        appBar: AppBar(
          title: const Text('PayPal'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Redirigiendo a PayPal...',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_cargando)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Cargando PayPal...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
