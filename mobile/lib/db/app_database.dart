import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base de données locale unique (SQLite via sqflite) : dossiers, flux et
/// articles. Aucun serveur — tout vit sur l'appareil.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final db = await _open();
    _db = db;
    return db;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'revue_eco_bf.db');
    return openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE folders (
            id TEXT PRIMARY KEY,
            nom TEXT NOT NULL,
            ordre INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE feeds (
            id TEXT PRIMARY KEY,
            nom TEXT NOT NULL,
            site_url TEXT NOT NULL DEFAULT '',
            flux_url TEXT NOT NULL,
            folder_id TEXT,
            acces_limite INTEGER NOT NULL DEFAULT 0,
            ordre INTEGER NOT NULL,
            derniere_maj INTEGER,
            derniere_erreur TEXT,
            FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE articles (
            id TEXT PRIMARY KEY,
            feed_id TEXT NOT NULL,
            titre TEXT NOT NULL,
            lien TEXT NOT NULL,
            contenu TEXT NOT NULL DEFAULT '',
            resume_ia TEXT,
            date_publication INTEGER NOT NULL,
            date_ajout INTEGER NOT NULL,
            lu INTEGER NOT NULL DEFAULT 0,
            favori INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (feed_id) REFERENCES feeds(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('CREATE INDEX idx_articles_feed ON articles(feed_id)');
        await db.execute('CREATE INDEX idx_articles_date ON articles(date_publication)');
        await db.execute('CREATE INDEX idx_articles_favori ON articles(favori)');
        await db.execute('CREATE INDEX idx_feeds_folder ON feeds(folder_id)');
        await _createSettingsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE articles ADD COLUMN resume_ia TEXT');
          await _createSettingsTable(db);
        }
      },
    );
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        cle TEXT PRIMARY KEY,
        valeur TEXT
      )
    ''');
  }
}
