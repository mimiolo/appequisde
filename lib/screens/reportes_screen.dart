import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/actividad_service.dart';
import '../db/db_helper.dart';
import '../theme/app_theme.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});
  @override
  State<ReportesScreen> createState() => _S();
}

class _S extends State<ReportesScreen> {
  int _totalPedidos = 0, _pendientes = 0, _entregados = 0, _cancelados = 0;
  double _ingresos = 0;
  List<Map<String, dynamic>> _actividad = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final db = await DBHelper.instance.database;
    final pedidos = await db.query('pedidos');
    double totalIngresos = 0;
    for (var p in pedidos) {
      totalIngresos += (p['total'] as num).toDouble();
      final e = p['estado'] as String;
      if (e == 'pendiente')
        _pendientes++;
      else if (e == 'entregado')
        _entregados++;
      else if (e == 'cancelado') _cancelados++;
    }
    final act = await ActividadService().obtenerTodas(limit: 30);
    setState(() {
      _totalPedidos = pedidos.length;
      _ingresos = totalIngresos;
      _actividad = act;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes y Monitoreo')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  const Text('Resumen de Pedidos',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(children: [
                    _stat('Total', '$_totalPedidos', AppColores.primary),
                    _stat('Ingresos', '\$${_ingresos.toStringAsFixed(0)}',
                        AppColores.accent),
                  ]),
                ]))),
        const SizedBox(height: 12),
        if (_totalPedidos > 0)
          Card(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Text('Por estado',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SizedBox(
                  height: 200,
                  child: PieChart(PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                          value: _pendientes.toDouble(),
                          color: AppColores.pedidoPendiente,
                          title: '$_pendientes',
                          radius: 50),
                      PieChartSectionData(
                          value: _entregados.toDouble(),
                          color: AppColores.pedidoEntregado,
                          title: '$_entregados',
                          radius: 50),
                      PieChartSectionData(
                          value: _cancelados.toDouble(),
                          color: AppColores.pedidoCancelado,
                          title: '$_cancelados',
                          radius: 50),
                    ],
                  ))),
            ]),
          )),
        const SizedBox(height: 12),
        const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Actividad reciente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ..._actividad.take(15).map((a) => Card(
                child: ListTile(
              leading: const Icon(Icons.history, color: AppColores.primary),
              title: Text(a['accion'] as String),
              subtitle: Text(
                  '${a['usuario_correo'] ?? "sistema"} · ${a['createdAT']}'),
              isThreeLine: false,
            ))),
      ]),
    );
  }

  Widget _stat(String label, String valor, Color color) => Expanded(
          child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(valor,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ]),
      ));
}
