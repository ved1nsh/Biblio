import 'package:sembast/sembast_io.dart';
import 'package:path/path.dart' as p;

class SembastService {
  late Database _db;
  final _filePathStore = stringMapStoreFactory.store('book_file_paths');
  final _textStore = stringMapStoreFactory.store('extracted_texts');

  // Initialize the Sembast database at the given path
  Future<void> init(String path) async {
    final dbPath = p.join(path, 'biblio_local.db');
    _db = await databaseFactoryIo.openDatabase(dbPath);
  }

  // Store the local file path for a book (by bookId)
  Future<void> saveBookFilePath(String bookId, String filePath) async {
    await _filePathStore.record(bookId).put(_db, {'filePath': filePath});
  }

  // Retrieve the local file path for a book
  Future<String?> getBookFilePath(String bookId) async {
    final record = await _filePathStore.record(bookId).get(_db);
    if (record != null && record['filePath'] is String) {
      return record['filePath'] as String;
    }
    return null;
  }

  // Store the extracted text for a book (by bookId)
  Future<void> saveExtractedText(String bookId, List<String> paragraphs) async {
    await _textStore.record(bookId).put(_db, {'paragraphs': paragraphs});
  }

  // Retrieve the extracted text for a book
  Future<List<String>> getExtractedText(String bookId) async {
    final record = await _textStore.record(bookId).get(_db);
    if (record != null && record['paragraphs'] is List) {
      return List<String>.from(record['paragraphs'] as List<dynamic>);
    }
    return [];
  }

  // Optionally, delete extracted text for a book
  Future<void> deleteExtractedText(String bookId) async {
    await _textStore.record(bookId).delete(_db);
  }

  // Optionally, delete file path for a book
  Future<void> deleteBookFilePath(String bookId) async {
    await _filePathStore.record(bookId).delete(_db);
  }
}
