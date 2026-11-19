import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class MailHelper {
  static const String _username = 'mimiriamjlaa@gmail.com';
  static const String _passwordRaw = 'zkpl mrgs lgyo fnol';
  static final String _password = _passwordRaw.replaceAll(' ', '');
  static final smtpServer = gmail(_username, _password);

  static Future<void> sendEmail(String destino, String asunto, String mensaje,
      {String? htmlContent}) async {
    final message = Message()
      ..from = Address(_username, 'Seguridad App')
      ..recipients.add(destino)
      ..subject = asunto
      ..text = mensaje
      ..html = htmlContent ?? "<p style='font-family:Roboto;'>$mensaje</p>";
    try {
      await send(message, smtpServer);
      print('✅ Correo enviado a $destino');
    } catch (e) {
      print('❌ Error al enviar: $e');
      rethrow;
    }
  }

  static Future<void> sendPurchaseSummaryEmail({
    required String destino,
    required String nombreCliente,
    required List<Map<String, dynamic>> items,
    required double total,
    required String folio,
    required DateTime fecha,
  }) async {
    final asunto = 'Tu ticket de compra - $folio';
    final filas = items.map((it) {
      final titulo = it['titulo'] ?? '';
      final precio = (it['precio'] as num).toDouble();
      final cant = it['cantidad'] as int;
      final sub = precio * cant;
      return '''<tr>
        <td style="padding:12px;border-bottom:1px solid #eee;">$titulo</td>
        <td style="padding:12px;border-bottom:1px solid #eee;text-align:center;">$cant</td>
        <td style="padding:12px;border-bottom:1px solid #eee;text-align:right;">\$${precio.toStringAsFixed(2)}</td>
        <td style="padding:12px;border-bottom:1px solid #eee;text-align:right;font-weight:bold;color:#8B7FD9;">\$${sub.toStringAsFixed(2)}</td>
      </tr>''';
    }).join('');
    final fechaStr = '${fecha.day}/${fecha.month}/${fecha.year}';
    final html =
        '''<html><body style="font-family:Arial;background:#FDFBFF;padding:20px;">
      <div style="max-width:600px;margin:auto;background:#fff;border-radius:18px;overflow:hidden;">
        <div style="background:linear-gradient(135deg,#9F94E3,#E8B4D0);padding:32px;text-align:center;color:white;">
          <div style="font-size:48px;">🎫</div>
          <h1 style="margin:12px 0 4px;">TICKET DE COMPRA</h1>
        </div>
        <div style="padding:24px;"><p><strong>Cliente:</strong> $nombreCliente</p>
          <p><strong>Folio:</strong> $folio</p><p><strong>Fecha:</strong> $fechaStr</p></div>
        <div style="padding:20px;"><table style="width:100%;border-collapse:collapse;">
          <thead><tr style="background:#8B7FD9;color:white;">
            <th style="padding:12px;">Producto</th><th style="padding:12px;">Cant.</th>
            <th style="padding:12px;">P.U.</th><th style="padding:12px;">Subtotal</th>
          </tr></thead><tbody>$filas</tbody></table></div>
        <div style="padding:20px;text-align:right;background:#FAFAFE;">
          <p style="font-size:28px;font-weight:bold;color:#8B7FD9;">\$${total.toStringAsFixed(2)} MXN</p></div>
        <div style="padding:20px;text-align:center;background:#F0F1FA;color:#8B88A0;">¡Gracias por tu compra! 🛒</div>
      </div></body></html>''';
    await sendEmail(destino, asunto, 'Ticket $folio', htmlContent: html);
  }

  static Future<void> sendOtpEmail({
    required String destino,
    required String nombre,
    required String codigo,
    required String tipo,
  }) async {
    final esLogin = tipo == 'login';
    final asunto =
        esLogin ? 'Código de verificación' : 'Recuperación de contraseña';
    final titulo =
        esLogin ? 'Verificación en 2 pasos' : 'Recuperación de cuenta';
    final mensaje = esLogin
        ? 'Usa este código para completar tu inicio de sesión:'
        : 'Usa este código para restablecer tu contraseña:';
    final html =
        '''<html><body style="font-family:Arial;background:#FDFBFF;padding:20px;">
      <div style="max-width:500px;margin:auto;background:#fff;border-radius:20px;overflow:hidden;">
        <div style="background:linear-gradient(135deg,#9F94E3,#E8B4D0);padding:30px;text-align:center;color:white;">
          <div style="font-size:48px;">${esLogin ? "🔐" : "🔑"}</div>
          <h1 style="margin:10px 0;font-size:22px;">$titulo</h1>
        </div>
        <div style="padding:30px;text-align:center;">
          <p style="font-size:15px;color:#3D3A52;">Hola <strong>$nombre</strong>,</p>
          <p style="color:#8B88A0;">$mensaje</p>
          <div style="margin:24px 0;padding:20px;background:#F3EEFF;border-radius:14px;border:2px dashed #8B7FD9;">
            <span style="font-size:36px;font-weight:bold;letter-spacing:8px;color:#8B7FD9;font-family:monospace;">$codigo</span>
          </div>
          <p style="font-size:12px;color:#8B88A0;">Este código expira en 10 minutos.</p>
          <p style="font-size:12px;color:#8B88A0;">Si no lo solicitaste, ignora este correo.</p>
        </div>
      </div></body></html>''';
    await sendEmail(destino, asunto, 'Tu código: $codigo', htmlContent: html);
  }
}
