import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';
import '../l10n.dart';
import '../state/app_state.dart';
import '../util/format.dart';

class ExportData {
  final List<Operation> ops;
  final OpType type;
  final String period;
  final String accountName;
  final String currency;
  final String? accountId;
  const ExportData({
    required this.ops,
    required this.type,
    required this.period,
    required this.accountName,
    required this.currency,
    this.accountId,
  });
}

String _fileStem(ExportData d) {
  final kind = d.type == OpType.income ? tr('Доходы') : tr('Расходы');
  return '${tr('Финансы')}_${kind}_${df('yyyy-MM-dd_HH-mm').format(DateTime.now())}';
}

List<String> _headers() => [tr('Дата'), tr('Категория'), tr('Счет'), tr('Сумма'), tr('Валюта'), tr('Теги'), tr('Комментарий')];

Future<File> exportExcel(AppState s, ExportData d, {Directory? dir}) async {
  final book = xl.Excel.createExcel();
  final sheetName = book.getDefaultSheet()!;
  final sh = book[sheetName];
  final bold = xl.CellStyle(bold: true);
  final head = xl.CellStyle(bold: true, fontColorHex: xl.ExcelColor.white, backgroundColorHex: xl.ExcelColor.fromHexString('#274E3E'));

  sh.appendRow([xl.TextCellValue('${tr('Финансы')} — ${d.type == OpType.income ? tr('Доходы') : tr('Расходы')}')]);
  sh.appendRow([xl.TextCellValue(tr('Период')), xl.TextCellValue(d.period)]);
  sh.appendRow([xl.TextCellValue(tr('Счет')), xl.TextCellValue(d.accountName)]);
  sh.appendRow([]);
  sh.appendRow([for (final h in _headers()) xl.TextCellValue(h)]);
  final headRow = sh.maxRows - 1;
  for (var c = 0; c < 7; c++) {
    sh.cell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: headRow)).cellStyle = head;
  }
  sh.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = bold;

  var total = 0.0;
  for (final o in d.ops) {
    final a = s.accountById(o.accountId);
    total += s.opValue(o, accountId: d.accountId);
    sh.appendRow([
      xl.TextCellValue(df('dd.MM.yyyy HH:mm').format(o.date)),
      xl.TextCellValue(s.categoryById(o.categoryId)?.name ?? '—'),
      xl.TextCellValue(a?.name ?? '—'),
      xl.DoubleCellValue(o.amount),
      xl.TextCellValue(a?.currency ?? d.currency),
      xl.TextCellValue(o.tags.map((t) => '#$t').join(' ')),
      xl.TextCellValue(o.comment),
    ]);
  }
  sh.appendRow([]);
  sh.appendRow([
    xl.TextCellValue(tr('Всего')),
    null,
    null,
    xl.DoubleCellValue((total * 100).roundToDouble() / 100),
    xl.TextCellValue(d.currency),
  ]);
  final last = sh.maxRows - 1;
  sh.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: last)).cellStyle = bold;
  sh.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: last)).cellStyle = bold;
  for (final (i, w) in [(0, 18.0), (1, 22.0), (2, 16.0), (3, 12.0), (4, 8.0), (5, 18.0), (6, 30.0)]) {
    sh.setColumnWidth(i, w);
  }

  final bytes = book.encode()!;
  final f = File('${(dir ?? await getTemporaryDirectory()).path}/${_fileStem(d)}.xlsx');
  await f.writeAsBytes(bytes, flush: true);
  return f;
}

Future<File> exportPdf(AppState s, ExportData d, {Directory? dir}) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  final medium = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Medium.ttf'));
  const green = pdf.PdfColor.fromInt(0xFF274E3E);
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: medium),
  );
  var total = 0.0;
  final rows = <List<String>>[];
  for (final o in d.ops) {
    final a = s.accountById(o.accountId);
    total += s.opValue(o, accountId: d.accountId);
    rows.add([
      df('dd.MM.yyyy HH:mm').format(o.date),
      s.categoryById(o.categoryId)?.name ?? '—',
      a?.name ?? '—',
      fmtMoney(o.amount, a?.currency ?? d.currency),
      [if (o.tags.isNotEmpty) o.tags.map((t) => '#$t').join(' '), if (o.comment.isNotEmpty) o.comment].join(' · '),
    ]);
  }
  doc.addPage(
    pw.MultiPage(
      pageFormat: pdf.PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: const pw.BoxDecoration(color: green, borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${tr('Финансы')} — ${d.type == OpType.income ? tr('Доходы') : tr('Расходы')}',
                style: pw.TextStyle(color: pdf.PdfColors.white, fontSize: 20, font: medium),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                '${tr('Период')}: ${d.period}   ·   ${tr('Счет')}: ${d.accountName}',
                style: const pw.TextStyle(color: pdf.PdfColors.white, fontSize: 11),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        if (rows.isEmpty)
          pw.Text(tr('Нет операций'))
        else
          pw.TableHelper.fromTextArray(
            headers: [tr('Дата'), tr('Категория'), tr('Счет'), tr('Сумма'), '${tr('Теги')} / ${tr('Комментарий')}'],
            data: rows,
            headerStyle: pw.TextStyle(color: pdf.PdfColors.white, font: medium, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: green),
            cellStyle: const pw.TextStyle(fontSize: 9.5),
            oddRowDecoration: const pw.BoxDecoration(color: pdf.PdfColor.fromInt(0xFFF1F4EE)),
            cellAlignments: {3: pw.Alignment.centerRight},
            columnWidths: {
              0: const pw.FixedColumnWidth(78),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FixedColumnWidth(80),
              4: const pw.FlexColumnWidth(1.6),
            },
          ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('${tr('Всего')}: ${fmtMoney(total, d.currency)}', style: pw.TextStyle(font: medium, fontSize: 13)),
        ),
      ],
    ),
  );
  final f = File('${(dir ?? await getTemporaryDirectory()).path}/${_fileStem(d)}.pdf');
  await f.writeAsBytes(await doc.save(), flush: true);
  return f;
}

Future<void> shareFile(File f, String mime) => SharePlus.instance.share(
  ShareParams(
    files: [XFile(f.path, mimeType: mime)],
    fileNameOverrides: [f.uri.pathSegments.last],
  ),
);
