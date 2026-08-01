import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ganges_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE order_items ADD COLUMN item_url TEXT;');
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. products 商品テーブル
    await db.execute('''
      CREATE TABLE products (
        item_code TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        price INTEGER NOT NULL,
        image_url TEXT,
        item_url TEXT NOT NULL,
        review_average REAL DEFAULT 0.0,
        review_count INTEGER DEFAULT 0,
        cached_at TEXT NOT NULL
      )
    ''');

    // 2. cart_items カートテーブル
    await db.execute('''
      CREATE TABLE cart_items (
        id TEXT PRIMARY KEY,
        item_code TEXT NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity >= 1),
        added_at TEXT NOT NULL,
        FOREIGN KEY (item_code) REFERENCES products (item_code) ON DELETE CASCADE
      )
    ''');

    // 3. favorites お気に入りテーブル
    await db.execute('''
      CREATE TABLE favorites (
        id TEXT PRIMARY KEY,
        item_code TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_code) REFERENCES products (item_code) ON DELETE CASCADE
      )
    ''');

    // 4. orders 疑似注文テーブル
    await db.execute('''
      CREATE TABLE orders (
        order_id TEXT PRIMARY KEY,
        ordered_at TEXT NOT NULL,
        total_amount INTEGER NOT NULL,
        total_savings INTEGER NOT NULL,
        status TEXT DEFAULT 'completed'
      )
    ''');

    // 5. order_items 疑似注文明細テーブル
    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        item_code TEXT NOT NULL,
        title TEXT NOT NULL,
        price INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        image_url TEXT,
        item_url TEXT,
        FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE
      )
    ''');

    // 6. user_stats 節約統計テーブル
    await db.execute('''
      CREATE TABLE user_stats (
        id TEXT PRIMARY KEY,
        total_saved_amount INTEGER DEFAULT 0,
        total_order_count INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // 統計テーブルの初期レコードを挿入
    await db.insert('user_stats', {
      'id': 'main_stats',
      'total_saved_amount': 0,
      'total_order_count': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> close() async {
    final db = await _database;
    if (db != null) {
      await db.close();
    }
  }
}
