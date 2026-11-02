import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../models/repayment.dart';
import '../../models/transaction.dart';
import '../../models/transaction_type.dart';
import '../../services/receipt_share_service.dart';
import '../../state/app_state.dart';
import '../../utils/formatters.dart';

class ReceiptPreviewScreen extends StatefulWidget {
  const ReceiptPreviewScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  final _paperKey = GlobalKey();
  bool _sharing = false;

  Future<Uint8List> _capture() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _paperKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('取引記録の画像を作成できませんでした');
    return data.buffer.asUint8List();
  }

  Rect? _shareOrigin(BuildContext buttonContext) {
    final box = buttonContext.findRenderObject();
    if (box is! RenderBox) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _share({
    required bool pdf,
    required BuildContext buttonContext,
  }) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final origin = _shareOrigin(buttonContext);
    try {
      final bytes = await _capture();
      final suffix =
          widget.transactionId.length > 8
              ? widget.transactionId.substring(widget.transactionId.length - 8)
              : widget.transactionId;
      final fileStem = 'tsuketori-record-$suffix';
      if (pdf) {
        await ReceiptShareService.sharePdf(
          pngBytes: bytes,
          fileStem: fileStem,
          origin: origin,
        );
      } else {
        await ReceiptShareService.shareImage(
          pngBytes: bytes,
          fileStem: fileStem,
          origin: origin,
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('共有用ファイルを作成できませんでした')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final transaction = appState.transaction(widget.transactionId);
    if (transaction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('取引記録')),
        body: const Center(child: Text('取引が見つかりません')),
      );
    }
    final person = appState.person(transaction.personId);
    final repayments = appState.repaymentsForTransaction(transaction.id);

    return Scaffold(
      backgroundColor: const Color(0xffedece8),
      appBar: AppBar(
        title: const Text('取引記録を共有'),
        backgroundColor: const Color(0xffedece8),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
        children: [
          Center(
            child: RepaintBoundary(
              key: _paperKey,
              child: _ReceiptPaper(
                transaction: transaction,
                personName: person?.name ?? '不明な相手',
                repayments: repayments,
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 18,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Builder(
                  builder:
                      (buttonContext) => OutlinedButton.icon(
                        onPressed:
                            _sharing
                                ? null
                                : () => _share(
                                  pdf: false,
                                  buttonContext: buttonContext,
                                ),
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('画像で共有'),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Builder(
                  builder:
                      (buttonContext) => FilledButton.icon(
                        onPressed:
                            _sharing
                                ? null
                                : () => _share(
                                  pdf: true,
                                  buttonContext: buttonContext,
                                ),
                        icon:
                            _sharing
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('PDFで共有'),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptPaper extends StatelessWidget {
  const _ReceiptPaper({
    required this.transaction,
    required this.personName,
    required this.repayments,
  });

  final TransactionModel transaction;
  final String personName;
  final List<Repayment> repayments;

  @override
  Widget build(BuildContext context) {
    final identifier =
        transaction.id.length > 12
            ? transaction.id.substring(transaction.id.length - 12).toUpperCase()
            : transaction.id.toUpperCase();
    final kind = transaction.type == TransactionType.lend ? '貸付の記録' : '借入の記録';
    final remainingLabel =
        transaction.remainingAmount == 0
            ? '精算済み'
            : transaction.type == TransactionType.lend
            ? '受け取る予定'
            : '返す予定';

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: const Color(0xfffffdf6),
        border: Border.all(color: const Color(0xffd7d1c2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Color(0xff25231f),
          fontSize: 13,
          height: 1.45,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ツ ケ ト リ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '取 引 記 録',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              kind,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 22),
            const Divider(color: Color(0xff5d584f), thickness: 1),
            _line('記録番号', identifier),
            _line('取引日時', Formatters.dateTime(transaction.date)),
            _line('相手', personName),
            _line('種別', transaction.type.label),
            const Divider(color: Color(0xffb9b2a4)),
            _amountLine('取引金額', transaction.amount),
            _amountLine('返済済み', transaction.repaidAmount),
            _amountLine(
              remainingLabel,
              transaction.remainingAmount,
              emphasized: true,
            ),
            if (transaction.memo?.trim().isNotEmpty == true) ...[
              const Divider(color: Color(0xffb9b2a4)),
              _line('メモ', transaction.memo!.trim()),
            ],
            if (repayments.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                '返済履歴',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              const SizedBox(height: 6),
              for (final repayment in repayments)
                _line(
                  Formatters.date(repayment.date),
                  Formatters.yenSuffix(repayment.amount),
                ),
            ],
            const SizedBox(height: 24),
            const Divider(color: Color(0xff5d584f), thickness: 1),
            const SizedBox(height: 10),
            const Text(
              'この書面は、ツケトリがユーザー入力から生成した取引記録です。'
              '公的機関・金融機関・決済事業者が発行した領収書ではなく、'
              '支払いの証明には利用できません。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.5,
                color: Color(0xff5f5a52),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '生成日時  ${Formatters.dateTime(DateTime.now())}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: Color(0xff777168)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 82, child: Text(label)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _amountLine(String label, int amount, {bool emphasized = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              Formatters.yenSuffix(amount),
              style: TextStyle(
                fontSize: emphasized ? 20 : 15,
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}
