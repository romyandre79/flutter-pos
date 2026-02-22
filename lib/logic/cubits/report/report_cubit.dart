import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pos/data/repositories/report_repository.dart';
import 'package:flutter_pos/core/services/export_service.dart';
import 'package:flutter_pos/logic/cubits/report/report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final ReportRepository _reportRepository;
  final ExportService _exportService;

  ReportCubit({
    ReportRepository? reportRepository,
    ExportService? exportService,
  })  : _reportRepository = reportRepository ?? ReportRepository(),
        _exportService = exportService ?? ExportService(),
        super(const ReportInitial());

  /// Load report data
  Future<void> loadReport(DateTime startDate, DateTime endDate) async {
    emit(const ReportLoading());

    try {
      final data = await _reportRepository.getReportData(startDate, endDate);
      final orders =
          await _reportRepository.getOrdersByDateRange(startDate, endDate);

      emit(ReportLoaded(data: data, orders: orders));
    } catch (e) {
      emit(ReportError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Export report to Excel (Summary)
  Future<void> exportToExcel() async {
    final currentState = state;
    if (currentState is! ReportLoaded) return;

    emit(const ReportExporting());

    try {
      final filePath = await _exportService.exportOrdersToExcel(
        currentState.orders,
        currentState.data,
      );

      await _exportService.shareFile(filePath);

      emit(ReportExported(
        filePath: filePath,
        message: 'Laporan berhasil di-export',
      ));

      emit(currentState);
    } catch (e) {
      emit(ReportError(e.toString().replaceAll('Exception: ', '')));
      emit(currentState);
    }
  }

  /// Export Sales Detail
  Future<void> exportSalesDetail() async {
    final currentState = state;
    if (currentState is! ReportLoaded) return;

    emit(const ReportExporting());

    try {
      final orders = await _reportRepository.getOrdersWithItemsByDateRange(
        currentState.data.startDate,
        currentState.data.endDate,
      );

      final filePath = await _exportService.exportSalesDetailToExcel(
        orders,
        currentState.data,
      );

      await _exportService.shareFile(filePath);

      emit(ReportExported(
        filePath: filePath,
        message: 'Laporan Penjualan (Detail) berhasil di-export',
      ));

      emit(currentState);
    } catch (e) {
      emit(ReportError(e.toString().replaceAll('Exception: ', '')));
      emit(currentState);
    }
  }

  /// Export Purchase Detail
  Future<void> exportPurchaseDetail() async {
    final currentState = state;
    if (currentState is! ReportLoaded) return;

    emit(const ReportExporting());

    try {
      final purchases = await _reportRepository.getPurchasesWithItemsByDateRange(
        currentState.data.startDate,
        currentState.data.endDate,
      );

      final filePath = await _exportService.exportPurchaseDetailToExcel(
        purchases,
        currentState.data,
      );

      await _exportService.shareFile(filePath);

      emit(ReportExported(
        filePath: filePath,
        message: 'Laporan Pembelian (Detail) berhasil di-export',
      ));

      emit(currentState);
    } catch (e) {
      emit(ReportError(e.toString().replaceAll('Exception: ', '')));
      emit(currentState);
    }
  }

  /// Export Stock Report
  Future<void> exportStockReport() async {
    final currentState = state;

    emit(const ReportExporting());

    try {
      final products = await _reportRepository.getAllProducts();

      final filePath = await _exportService.exportStockReportToExcel(products);

      await _exportService.shareFile(filePath);

      emit(ReportExported(
        filePath: filePath,
        message: 'Laporan Stok berhasil di-export',
      ));

      if (currentState is ReportLoaded) {
        emit(currentState);
      } else {
        emit(currentState);
      }
    } catch (e) {
      emit(ReportError(e.toString().replaceAll('Exception: ', '')));
      emit(currentState);
    }
  }
}
