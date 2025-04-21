// Stub implementation for non-web platforms
Future<void> downloadExcelWeb(List<int> excelBytes) async {
  // This should never be called on non-web platforms; handled by downloadExcelMobile
  throw UnsupportedError('Downloading Excel is only supported on web platforms.');
}