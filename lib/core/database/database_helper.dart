import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;
  
  static Database? _database;
  
  DatabaseHelper._internal();
  
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);
    
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }
  
  Future<void> _onConfigure(Database db) async {
    // 啟用外鍵約束
    await db.execute('PRAGMA foreign_keys = ON');
  }
  
  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 當資料庫需要升級時的處理邏輯
    if (oldVersion < newVersion) {
      // 在這裡添加版本升級邏輯
      await _createTables(db);
    }
  }
  
  Future<void> _createTables(Database db) async {
    // 創建 Podcast 表格
    await db.execute('''
      CREATE TABLE IF NOT EXISTS podcasts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        rss_url TEXT UNIQUE NOT NULL,
        author TEXT,
        category TEXT,
        language TEXT,
        is_subscribed BOOLEAN DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // 創建 Episode 表格
    await db.execute('''
      CREATE TABLE IF NOT EXISTS episodes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        podcast_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        audio_url TEXT NOT NULL,
        duration INTEGER,
        publish_date TIMESTAMP,
        is_downloaded BOOLEAN DEFAULT 0,
        local_path TEXT,
        play_position INTEGER DEFAULT 0,
        is_played BOOLEAN DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (podcast_id) REFERENCES podcasts(id) ON DELETE CASCADE
      )
    ''');
    
    // 創建 Playlist 表格
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // 創建 Playlist Episodes 關聯表格
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlist_episodes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        episode_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
        FOREIGN KEY (episode_id) REFERENCES episodes(id) ON DELETE CASCADE
      )
    ''');
    
    // 創建索引以提高查詢效能
    await _createIndexes(db);
  }
  
  Future<void> _createIndexes(Database db) async {
    // Podcast 索引
    await db.execute('CREATE INDEX IF NOT EXISTS idx_podcasts_subscribed ON podcasts(is_subscribed)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_podcasts_rss_url ON podcasts(rss_url)');
    
    // Episode 索引
    await db.execute('CREATE INDEX IF NOT EXISTS idx_episodes_podcast_id ON episodes(podcast_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_episodes_publish_date ON episodes(publish_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_episodes_downloaded ON episodes(is_downloaded)');
    
    // Playlist Episodes 索引
    await db.execute('CREATE INDEX IF NOT EXISTS idx_playlist_episodes_playlist_id ON playlist_episodes(playlist_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_playlist_episodes_episode_id ON playlist_episodes(episode_id)');
  }
  
  /// 清理資料庫
  Future<void> clearDatabase() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('playlist_episodes');
      await txn.delete('playlists');
      await txn.delete('episodes');
      await txn.delete('podcasts');
    });
  }
  
  /// 關閉資料庫連接
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
  
  /// 刪除資料庫檔案
  Future<void> deleteDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);
    
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    
    _database = null;
  }
  
  /// 獲取資料庫大小
  Future<int> getDatabaseSize() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);
    
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
  
  /// 執行原始 SQL 查詢
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }
  
  /// 執行原始 SQL 命令
  Future<int> rawExecute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }
} 