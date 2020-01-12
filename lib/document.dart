import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_pdf_viewer/page.dart';

class CustomPdfDocument {
  static const MethodChannel _channel =
      const MethodChannel('flutter_plugin_pdf_viewer');

  String _filePath;
  int count;

  /// Load a PDF File from a given File
  ///
  ///
  static Future<CustomPdfDocument> fromFile(File f) async {
    CustomPdfDocument document = CustomPdfDocument();
    document._filePath = f.path;
    try {
      var pageCount =
          await _channel.invokeMethod('getNumberOfPages', {'filePath': f.path});
      document.count = document.count = int.parse(pageCount);
    } catch (e) {
      throw Exception('Error reading PDF!');
    }
    return document;
  }

  /// Load a PDF File from a given URL.
  /// File is saved in cache
  ///
  static Future<CustomPdfDocument> fromURL(String url) async {
    // Download into cache
    File f = await DefaultCacheManager().getSingleFile(url);
    CustomPdfDocument document = CustomPdfDocument();
    document._filePath = f.path;
    try {
      var pageCount =
          await _channel.invokeMethod('getNumberOfPages', {'filePath': f.path});
      document.count = document.count = int.parse(pageCount);
    } catch (e) {
      throw Exception('Error reading PDF!');
    }
    return document;
  }

  /// Load a PDF File from assets folder
  ///
  ///
  static Future<CustomPdfDocument> fromAsset(String asset) async {
    // To open from assets, you can copy them to the app storage folder, and the access them "locally"
    File file;
    try {
      var dir = await getApplicationDocumentsDirectory();
      file = File("${dir.path}/file.pdf");
      var data = await rootBundle.load(asset);
      var bytes = data.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      throw Exception('Error parsing asset file!');
    }
    CustomPdfDocument document = CustomPdfDocument();
    document._filePath = file.path;
    try {
      var pageCount = await _channel
          .invokeMethod('getNumberOfPages', {'filePath': file.path});
      document.count = document.count = int.parse(pageCount);
    } catch (e) {
      throw Exception('Error reading PDF!');
    }
    return document;
  }

  /// Load specific page
  ///
  /// [page] defaults to `1` and must be equal or above it
  Future<PDFPage> get({int page = 1}) async {
    assert(page > 0);
    var data = await _channel
        .invokeMethod('getPage', {'filePath': _filePath, 'pageNumber': page});
    return new PDFPage(data, page);
  }

  // Stream all pages
  Observable<PDFPage> getAll() {
    return Future.forEach<PDFPage>(List(count), (i) async {
      print(i);
      final data = await _channel
          .invokeMethod('getPage', {'filePath': _filePath, 'pageNumber': i});
      return new PDFPage(data, 1);
    }).asStream();
  }
}
