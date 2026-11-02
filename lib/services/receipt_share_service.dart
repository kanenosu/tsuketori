import 'dart:typed_data';
import 'dart:ui';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReceiptShareService {
  static Future<ShareResult> shareImage({
    required Uint8List pngBytes,
    required String fileStem,
    Rect? origin,
  }) {
    final name = '$fileStem.png';
    return SharePlus.instance.share(
      ShareParams(
        title: 'ツケトリの取引記録',
        subject: 'ツケトリの取引記録',
        text: 'ツケトリで作成した取引記録です（公的な領収書ではありません）。',
        files: [XFile.fromData(pngBytes, mimeType: 'image/png', name: name)],
        fileNameOverrides: [name],
        sharePositionOrigin: origin,
      ),
    );
  }

  static Future<ShareResult> sharePdf({
    required Uint8List pngBytes,
    required String fileStem,
    Rect? origin,
  }) async {
    final document = pw.Document(
      title: 'ツケトリの取引記録',
      author: 'ツケトリ（ユーザー入力から生成）',
      subject: '公的な領収書ではない取引記録',
    );
    final image = pw.MemoryImage(pngBytes);
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );
    final bytes = await document.save();
    final name = '$fileStem.pdf';
    return SharePlus.instance.share(
      ShareParams(
        title: 'ツケトリの取引記録',
        subject: 'ツケトリの取引記録',
        text: 'ツケトリで作成した取引記録です（公的な領収書ではありません）。',
        files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: name)],
        fileNameOverrides: [name],
        sharePositionOrigin: origin,
      ),
    );
  }
}
