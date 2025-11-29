import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final _databaseName = "word_database.db";
  static final table = 'words';

  static final columnId = 'id';
  static final columnWord = 'word';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    // Eğer veritabanı dosyası yoksa, assets klasöründen kopyala
    if (!await File(path).exists()) {
      ByteData data = await rootBundle.load(join('assets', _databaseName));
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes);
    }

    return await openDatabase(path);
  }

  Future<void> insertWord(String word) async {
    Database db = await instance.database;
    await db.insert(table, {columnWord: word});
  }

  Future<List<String>> getWords() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(table);

    return List.generate(maps.length, (i) {
      return maps[i][columnWord];
    });
  }
}
