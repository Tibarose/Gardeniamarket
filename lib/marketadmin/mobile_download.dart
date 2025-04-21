import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> downloadExcelMobile(List<int> excelBytes) async {
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/products.xlsx';
  final file = File(filePath);
  await file.writeAsBytes(excelBytes);
  await OpenFile.open(filePath);
}