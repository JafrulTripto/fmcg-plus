class DashboardModel {
  final double todaySales;
  final double yesterdaySales;
  final double growthPercent;
  final int todayOrders;
  final double khataDues;
  final int pendingDebtors;
  final int lowStockCount;
  final double estProfit;
  final double netMarginPercent;

  DashboardModel({
    required this.todaySales,
    required this.yesterdaySales,
    required this.growthPercent,
    required this.todayOrders,
    required this.khataDues,
    required this.pendingDebtors,
    required this.lowStockCount,
    required this.estProfit,
    required this.netMarginPercent,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      todaySales: (json['today_sales'] as num?)?.toDouble() ?? 0.0,
      yesterdaySales: (json['yesterday_sales'] as num?)?.toDouble() ?? 0.0,
      growthPercent: (json['growth_percent'] as num?)?.toDouble() ?? 0.0,
      todayOrders: json['today_orders'] as int? ?? 0,
      khataDues: (json['khata_dues'] as num?)?.toDouble() ?? 0.0,
      pendingDebtors: json['pending_debtors'] as int? ?? 0,
      lowStockCount: json['low_stock_count'] as int? ?? 0,
      estProfit: (json['est_profit'] as num?)?.toDouble() ?? 0.0,
      netMarginPercent: (json['net_margin_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
