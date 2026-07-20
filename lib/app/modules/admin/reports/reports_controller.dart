import 'package:get/get.dart';

import '../../../core/models/payout_request_model.dart';
import '../../../core/services/affiliate_program_service.dart';
import '../../../core/utils/app_snackbar.dart';

class DailyOrderReport {
  const DailyOrderReport({
    required this.date,
    required this.orders,
    required this.revenue,
  });

  final DateTime date;
  final int orders;
  final double revenue;

  factory DailyOrderReport.fromJson(Map<String, dynamic> json) {
    return DailyOrderReport(
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TopAffiliateReport {
  const TopAffiliateReport({
    required this.id,
    required this.name,
    required this.code,
    required this.orders,
    required this.revenue,
    required this.commission,
  });

  final int id;
  final String name;
  final String code;
  final int orders;
  final double revenue;
  final double commission;

  factory TopAffiliateReport.fromJson(Map<String, dynamic> json) {
    return TopAffiliateReport(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      code: (json['code'] as String?) ?? '',
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ReportsController extends GetxController {
  final totalRevenue = 0.0.obs;
  final grossSales = 0.0.obs;
  final totalDiscounts = 0.0.obs;
  final averageOrderValue = 0.0.obs;
  final totalOrders = 0.obs;
  final completedOrders = 0.obs;
  final affiliateOrders = 0.obs;
  final affiliateRevenue = 0.0.obs;
  final promoOrders = 0.obs;
  final promoDiscounts = 0.0.obs;
  final commissionTotal = 0.0.obs;
  final commissionPending = 0.0.obs;
  final commissionAvailable = 0.0.obs;
  final commissionProcessing = 0.0.obs;
  final commissionPaid = 0.0.obs;
  final paidPayouts = 0.0.obs;
  final pendingPayoutCount = 0.obs;
  final ordersByStatus = <String, int>{}.obs;
  final affiliateSources = <String, int>{}.obs;
  final ordersByDay = <DailyOrderReport>[].obs;
  final topAffiliates = <TopAffiliateReport>[].obs;
  final recentPayouts = <PayoutRequestModel>[].obs;
  final isLoading = true.obs;

  @override
  void onReady() {
    super.onReady();
    fetchReports();
  }

  Future<void> fetchReports() async {
    isLoading.value = true;
    try {
      final data = await AffiliateProgramService.getAdminReports();
      final summary = Map<String, dynamic>.from(
        data['summary'] as Map? ?? const {},
      );

      totalRevenue.value = (summary['net_revenue'] as num?)?.toDouble() ?? 0;
      grossSales.value = (summary['gross_sales'] as num?)?.toDouble() ?? 0;
      totalDiscounts.value =
          (summary['total_discounts'] as num?)?.toDouble() ?? 0;
      averageOrderValue.value =
          (summary['average_order_value'] as num?)?.toDouble() ?? 0;
      totalOrders.value = (summary['total_orders'] as num?)?.toInt() ?? 0;
      completedOrders.value =
          (summary['completed_orders'] as num?)?.toInt() ?? 0;
      affiliateOrders.value =
          (summary['affiliate_orders'] as num?)?.toInt() ?? 0;
      affiliateRevenue.value =
          (summary['affiliate_revenue'] as num?)?.toDouble() ?? 0;
      promoOrders.value = (summary['promo_orders'] as num?)?.toInt() ?? 0;
      promoDiscounts.value =
          (summary['promo_discounts'] as num?)?.toDouble() ?? 0;
      commissionTotal.value =
          (summary['commission_total'] as num?)?.toDouble() ?? 0;
      commissionPending.value =
          (summary['commission_pending'] as num?)?.toDouble() ?? 0;
      commissionAvailable.value =
          (summary['commission_available'] as num?)?.toDouble() ?? 0;
      commissionProcessing.value =
          (summary['commission_processing'] as num?)?.toDouble() ?? 0;
      commissionPaid.value =
          (summary['commission_paid'] as num?)?.toDouble() ?? 0;
      paidPayouts.value = (summary['paid_payouts'] as num?)?.toDouble() ?? 0;
      pendingPayoutCount.value =
          (summary['pending_payouts'] as num?)?.toInt() ?? 0;

      ordersByStatus.value = Map<String, dynamic>.from(
        data['orders_by_status'] as Map? ?? const {},
      ).map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
      affiliateSources.value = Map<String, dynamic>.from(
        data['affiliate_sources'] as Map? ?? const {},
      ).map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
      ordersByDay.value = ((data['orders_by_day'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (row) => DailyOrderReport.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();
      topAffiliates.value = ((data['top_affiliates'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (row) =>
                TopAffiliateReport.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();
      recentPayouts.value = ((data['recent_payouts'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (row) =>
                PayoutRequestModel.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();
    } on AffiliateProgramException catch (e) {
      AppSnackbar.show('error'.tr, e.message, type: AppSnackbarType.error);
    } finally {
      isLoading.value = false;
    }
  }
}
