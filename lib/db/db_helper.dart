import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._();
  DBHelper._();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'seguridad.db');
    return await openDatabase(
      path,
      version: 7,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, v) async {
        await _crearTablas(db);
        await _insertarDatosIniciales(db);
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute("""CREATE TABLE IF NOT EXISTS log_actividad (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER, accion TEXT NOT NULL, detalle TEXT,
            fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)""");
          await db.execute(
            """CREATE TABLE IF NOT EXISTS recuperacion_otp (
            id INTEGER PRIMARY KEY AUTOINCREMENT, correo TEXT NOT NULL,
            codigo TEXT NOT NULL, expira TIMESTAMP NOT NULL, usado INTEGER DEFAULT 0)""",
          );
        }
        if (oldV < 3) {
          await db.execute("""CREATE TABLE IF NOT EXISTS otp_codigos (
            id INTEGER PRIMARY KEY AUTOINCREMENT, usuario_id INTEGER NOT NULL,
            codigo TEXT NOT NULL, tipo TEXT NOT NULL, expira TIMESTAMP NOT NULL,
            usado INTEGER DEFAULT 0)""");
          await db.execute("""CREATE TABLE IF NOT EXISTS productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT, titulo TEXT NOT NULL,
            descripcion TEXT, precio REAL NOT NULL, imagen_url TEXT,
            stock INTEGER NOT NULL DEFAULT 0)""");
          await db.execute("""CREATE TABLE IF NOT EXISTS pedidos (
            id INTEGER PRIMARY KEY AUTOINCREMENT, usuario_id INTEGER NOT NULL,
            usuario_nombre TEXT, usuario_correo TEXT, total REAL NOT NULL,
            estado TEXT NOT NULL DEFAULT 'pendiente', items TEXT NOT NULL,
            createdAT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)""");
          await db.execute("""CREATE TABLE IF NOT EXISTS actividad (
            id INTEGER PRIMARY KEY AUTOINCREMENT, usuario_id INTEGER,
            usuario_correo TEXT, accion TEXT NOT NULL, detalle TEXT,
            createdAT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)""");
          await db.execute("""CREATE TABLE IF NOT EXISTS preferencias (
            id INTEGER PRIMARY KEY AUTOINCREMENT, usuario_id INTEGER NOT NULL UNIQUE,
            tema_oscuro INTEGER DEFAULT 0, notificaciones INTEGER DEFAULT 1,
            idioma TEXT DEFAULT 'es')""");
        }
        if (oldV < 4) {
          try {
            await db.execute('ALTER TABLE pedidos ADD COLUMN latitud REAL');
            await db.execute('ALTER TABLE pedidos ADD COLUMN longitud REAL');
          } catch (_) {}
        }
        if (oldV < 5) {
          try {
            await db.execute('ALTER TABLE pedidos ADD COLUMN direccion TEXT');
          } catch (_) {}
        }
        // ⚡ v6: tabla de productos Punto Red
        if (oldV < 6) {
          await db.execute("""CREATE TABLE IF NOT EXISTS punto_red_productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            servicio TEXT NOT NULL,
            producto TEXT NOT NULL,
            id_servicio TEXT,
            id_producto TEXT UNIQUE,
            id_cat_tipo_servicio TEXT,
            tipo_front TEXT,
            has_digito_verificador INTEGER DEFAULT 0,
            precio REAL NOT NULL,
            show_ayuda INTEGER DEFAULT 0,
            tipo_referencia TEXT,
            legend TEXT)""");
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_punto_red_servicio ON punto_red_productos(servicio)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_punto_red_producto ON punto_red_productos(producto)',
          );
        }
        // ⚡ v7: historial de transacciones Punto Red (solo exitosas)
        if (oldV < 7) {
          await db.execute(
            """CREATE TABLE IF NOT EXISTS punto_red_transacciones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_tx TEXT NOT NULL,
            num_autorizacion TEXT,
            id_servicio TEXT,
            id_producto TEXT,
            servicio TEXT,
            producto TEXT,
            telefono TEXT,
            monto REAL NOT NULL,
            comision REAL NOT NULL,
            saldo REAL NOT NULL,
            fecha TEXT,
            mensaje TEXT,
            codigo_mensaje TEXT,
            usuario_id INTEGER,
            usuario_correo TEXT,
            createdAT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)""",
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_prtx_idtx ON punto_red_transacciones(id_tx)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_prtx_usuario ON punto_red_transacciones(usuario_id)',
          );
        }
      },
    );
  }

  Future<void> _crearTablas(Database db) async {
    await db.execute("""CREATE TABLE rol_permiso (
      id INTEGER PRIMARY KEY, rol TEXT NOT NULL)""");

    await db.execute("""CREATE TABLE user_app(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      nombre TEXT NOT NULL, apellido_paterno TEXT, apellido_materno TEXT,
      pass TEXT NOT NULL, correo TEXT NOT NULL UNIQUE, role_id INTEGER NOT NULL,
      token_recuperacion TEXT, token_expiracion TIMESTAMP,
      codigo_verificacion TEXT, codigo_expiracion TIMESTAMP,
      createdAT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (role_id) REFERENCES rol_permiso (id))""");

    await db.execute("""CREATE TABLE log_actividad (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER,
      accion TEXT NOT NULL, detalle TEXT,
      fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)""");

    await db.execute(
      """CREATE TABLE recuperacion_otp (
      id INTEGER PRIMARY KEY AUTOINCREMENT, correo TEXT NOT NULL,
      codigo TEXT NOT NULL, expira TIMESTAMP NOT NULL, usado INTEGER DEFAULT 0)""",
    );

    await db.execute("""CREATE TABLE otp_codigos (
      id INTEGER PRIMARY KEY AUTOINCREMENT, usuario_id INTEGER NOT NULL,
      codigo TEXT NOT NULL, tipo TEXT NOT NULL, expira TIMESTAMP NOT NULL,
      usado INTEGER DEFAULT 0)""");

    await db.execute("""CREATE TABLE productos (
      id INTEGER PRIMARY KEY AUTOINCREMENT, titulo TEXT NOT NULL,
      descripcion TEXT, precio REAL NOT NULL, imagen_url TEXT,
      stock INTEGER NOT NULL DEFAULT 0)""");

    await db.execute("""CREATE TABLE pedidos (
      id INTEGER PRIMARY KEY AUTOINCREMENT, usuario_id INTEGER NOT NULL,
      usuario_nombre TEXT, usuario_correo TEXT, total REAL NOT NULL,
      estado TEXT NOT NULL DEFAULT 'pendiente', items TEXT NOT NULL,
      latitud REAL, longitud REAL, direccion TEXT,
      createdAT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)""");

    await db.execute("""CREATE TABLE actividad (
      id INTEGER PRIMARY KEY AUTOINCREMENT, usuario_id INTEGER,
      usuario_correo TEXT, accion TEXT NOT NULL, detalle TEXT,
      createdAT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)""");

    await db.execute("""CREATE TABLE preferencias (
      id INTEGER PRIMARY KEY AUTOINCREMENT, usuario_id INTEGER NOT NULL UNIQUE,
      tema_oscuro INTEGER DEFAULT 0, notificaciones INTEGER DEFAULT 1,
      idioma TEXT DEFAULT 'es')""");

    // ⚡ NUEVA: tabla Punto Red
    await db.execute("""CREATE TABLE punto_red_productos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      servicio TEXT NOT NULL,
      producto TEXT NOT NULL,
      id_servicio TEXT,
      id_producto TEXT UNIQUE,
      id_cat_tipo_servicio TEXT,
      tipo_front TEXT,
      has_digito_verificador INTEGER DEFAULT 0,
      precio REAL NOT NULL,
      show_ayuda INTEGER DEFAULT 0,
      tipo_referencia TEXT,
      legend TEXT)""");

    await db.execute(
      'CREATE INDEX idx_punto_red_servicio ON punto_red_productos(servicio)',
    );
    await db.execute(
      'CREATE INDEX idx_punto_red_producto ON punto_red_productos(producto)',
    );

    // ⚡ NUEVA v7: historial transacciones Punto Red
    await db.execute("""CREATE TABLE punto_red_transacciones (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      id_tx TEXT NOT NULL,
      num_autorizacion TEXT,
      id_servicio TEXT,
      id_producto TEXT,
      servicio TEXT,
      producto TEXT,
      telefono TEXT,
      monto REAL NOT NULL,
      comision REAL NOT NULL,
      saldo REAL NOT NULL,
      fecha TEXT,
      mensaje TEXT,
      codigo_mensaje TEXT,
      usuario_id INTEGER,
      usuario_correo TEXT,
      createdAT TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)""");

    await db.execute(
      'CREATE INDEX idx_prtx_idtx ON punto_red_transacciones(id_tx)',
    );
    await db.execute(
      'CREATE INDEX idx_prtx_usuario ON punto_red_transacciones(usuario_id)',
    );
  }

  Future<void> _insertarDatosIniciales(Database db) async {
    await db.insert('rol_permiso', {'id': 1, 'rol': 'admin'});
    await db.insert('rol_permiso', {'id': 2, 'rol': 'editor'});
    await db.insert('rol_permiso', {'id': 3, 'rol': 'lector'});
    await db.insert('user_app', {
      'nombre': 'Admin',
      'apellido_paterno': 'Sistema',
      'apellido_materno': '',
      'correo': 'admin@test.com',
      'pass': 'admin123',
      'role_id': 1,
    });
  }
}
