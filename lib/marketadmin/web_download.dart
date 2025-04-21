import 'dart:html' as html;

void downloadExcelWeb(List<int> excelBytes) {
  final blob = html.Blob([excelBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'products.xlsx')
    ..click();
  html.Url.revokeObjectUrl(url);
}