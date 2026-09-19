import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/delivery.dart';
import '../models/stock_movement.dart';
import '../models/payroll.dart';

class PdfService {
  static Future<void> generateAttendanceReport({
    required List<AttendanceRecord> attendance,
    required List<StoreUser> users,
    required String dateRange,
  }) async {
    final pdf = pw.Document();
    final userMap = {for (final u in users) u.uid: u};

    final present = attendance.where((r) =>
      r.status == AttendanceStatus.present || r.status == AttendanceStatus.complete).length;
    final late = attendance.where((r) => r.lateMinutes > 0).length;
    final absent = attendance.where((r) => r.status == AttendanceStatus.absent).length;
    final totalHours = attendance.fold<double>(0, (s, r) => s + r.totalHours);
    final totalOvertime = attendance.fold<double>(0, (s, r) => s + r.overtimeHours);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => pw.Header(
        level: 0,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Baycel Growcery', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
            pw.Text('Attendance Report', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ],
        ),
      ),
      footer: (context) => pw.Footer(
        trailing: pw.Text('Generated: ${DateTime.now().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 8)),
      ),
      build: (context) => [
        pw.SizedBox(height: 10),
        pw.Text('Period: $dateRange', style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 20),
        pw.Text('Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 10),
        _buildSummaryTable([
          ['Total Records', attendance.length.toString()],
          ['Present', present.toString()],
          ['Late', late.toString()],
          ['Absent', absent.toString()],
          ['Total Hours', totalHours.toStringAsFixed(1)],
          ['Total Overtime', totalOvertime.toStringAsFixed(1)],
        ]),
        pw.SizedBox(height: 20),
        pw.Text('Employee Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 10),
        if (attendance.isEmpty)
          pw.Text('No attendance records found.', style: const pw.TextStyle(color: PdfColors.grey600))
        else
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Employee', 'Role', 'Time In', 'Time Out', 'Hours', 'Late', 'Status'],
            data: attendance.map((r) {
              final user = userMap[r.employeeId];
              return [
                user?.name ?? r.employeeId,
                user?.role.value ?? '-',
                r.timeIn,
                r.timeOut ?? '-',
                r.totalHours.toStringAsFixed(1),
                r.lateMinutes > 0 ? '${r.lateMinutes}m' : '-',
                r.status?.name.toUpperCase() ?? '-',
              ];
            }).toList(),
          ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  static Future<void> generateSalesReport({
    required List<StockMovement> movements,
    required String dateRange,
  }) async {
    final pdf = pw.Document();
    final sales = movements.where((m) => m.productId == 'sales').toList();

    final today = DateTime.now();
    final todaySales = sales.where((m) =>
      m.createdAt.year == today.year && m.createdAt.month == today.month && m.createdAt.day == today.day);
    final todayTotal = todaySales.fold<double>(0, (s, m) => s + m.quantity);
    final weekAgo = today.subtract(const Duration(days: 7));
    final weekTotal = sales.where((m) => m.createdAt.isAfter(weekAgo)).fold<double>(0, (s, m) => s + m.quantity);
    final monthStart = DateTime(today.year, today.month, 1);
    final monthTotal = sales.where((m) => m.createdAt.isAfter(monthStart)).fold<double>(0, (s, m) => s + m.quantity);
    final totalRevenue = sales.fold<double>(0, (s, m) => s + m.quantity);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => pw.Header(
        level: 0,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Baycel Growcery', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
            pw.Text('Sales Report', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ],
        ),
      ),
      footer: (context) => pw.Footer(
        trailing: pw.Text('Generated: ${DateTime.now().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 8)),
      ),
      build: (context) => [
        pw.SizedBox(height: 10),
        pw.Text('Period: $dateRange', style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 20),
        pw.Text('Revenue Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 10),
        _buildSummaryTable([
          ['Today\'s Sales', '\u20B1${todayTotal.toStringAsFixed(0)}'],
          ['This Week', '\u20B1${weekTotal.toStringAsFixed(0)}'],
          ['This Month', '\u20B1${monthTotal.toStringAsFixed(0)}'],
          ['Total Revenue', '\u20B1${totalRevenue.toStringAsFixed(0)}'],
          ['Total Transactions', sales.length.toString()],
        ]),
        pw.SizedBox(height: 20),
        pw.Text('Transactions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 10),
        if (sales.isEmpty)
          pw.Text('No sales transactions found.', style: const pw.TextStyle(color: PdfColors.grey600))
        else
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Date', 'Time', 'Quantity', 'Amount'],
            data: sales.take(50).map((m) => [
              m.createdAt.toString().substring(0, 10),
              m.createdAt.toString().substring(11, 16),
              m.quantity.toStringAsFixed(0),
              '\u20B1${m.quantity.toStringAsFixed(0)}',
            ]).toList(),
          ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  static Future<void> generatePayrollReport({
    required List<PayrollRecord> payrolls,
    required List<StoreUser> users,
    required String dateRange,
  }) async {
    final pdf = pw.Document();

    final totalBasic = payrolls.fold<double>(0, (s, p) => s + p.basicPay);
    final totalOvertime = payrolls.fold<double>(0, (s, p) => s + p.overtimePay);
    final totalDeductions = payrolls.fold<double>(0, (s, p) => s + p.totalDeductions);
    final totalNet = payrolls.fold<double>(0, (s, p) => s + p.netPay);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => pw.Header(
        level: 0,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Baycel Growcery', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
            pw.Text('Payroll Summary', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ],
        ),
      ),
      footer: (context) => pw.Footer(
        trailing: pw.Text('Generated: ${DateTime.now().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 8)),
      ),
      build: (context) => [
        pw.SizedBox(height: 10),
        pw.Text('Period: $dateRange', style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 20),
        pw.Text('Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 10),
        _buildSummaryTable([
          ['Total Employees', users.length.toString()],
          ['Total Basic Pay', '\u20B1${totalBasic.toStringAsFixed(0)}'],
          ['Total Overtime', '\u20B1${totalOvertime.toStringAsFixed(0)}'],
          ['Total Deductions', '\u20B1${totalDeductions.toStringAsFixed(0)}'],
          ['Total Net Pay', '\u20B1${totalNet.toStringAsFixed(0)}'],
        ]),
        pw.SizedBox(height: 20),
        pw.Text('Employee Payroll', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 10),
        if (payrolls.isEmpty)
          pw.Text('No payroll records found.', style: const pw.TextStyle(color: PdfColors.grey600))
        else
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Employee', 'Role', 'Basic Pay', 'Overtime', 'Deductions', 'Net Pay', 'Status'],
            data: payrolls.map((p) => [
              p.employeeName,
              p.role,
              '\u20B1${p.basicPay.toStringAsFixed(0)}',
              '\u20B1${p.overtimePay.toStringAsFixed(0)}',
              '\u20B1${p.totalDeductions.toStringAsFixed(0)}',
              '\u20B1${p.netPay.toStringAsFixed(0)}',
              p.status.toUpperCase(),
            ]).toList(),
          ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  static Future<void> generateInventoryReport({
    required List<Product> products,
    required String dateRange,
  }) async {
    final pdf = pw.Document();

    final totalStock = products.fold<int>(0, (s, p) => s + p.stockQuantity);
    final lowStock = products.where((p) => p.stockQuantity <= p.reorderLevel).length;
    final totalValue = products.fold<double>(0, (s, p) => s + (p.price * p.stockQuantity));
    final categories = products.map((p) => p.category).toSet().length;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => pw.Header(
        level: 0,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Baycel Growcery', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
            pw.Text('Inventory Report', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ],
        ),
      ),
      footer: (context) => pw.Footer(
        trailing: pw.Text('Generated: ${DateTime.now().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 8)),
      ),
      build: (context) => [
        pw.SizedBox(height: 10),
        pw.Text('Period: $dateRange', style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 20),
        pw.Text('Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 10),
        _buildSummaryTable([
          ['Total Products', products.length.toString()],
          ['Total Stock Units', totalStock.toString()],
          ['Low Stock Items', lowStock.toString()],
          ['Categories', categories.toString()],
          ['Inventory Value', '\u20B1${totalValue.toStringAsFixed(0)}'],
        ]),
        pw.SizedBox(height: 20),
        pw.Text('Product List', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 10),
        if (products.isEmpty)
          pw.Text('No products found.', style: const pw.TextStyle(color: PdfColors.grey600))
        else
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Product', 'Category', 'Stock', 'Price', 'Value', 'Status'],
            data: products.map((p) => [
              p.name,
              p.category,
              p.stockQuantity.toString(),
              '\u20B1${p.price.toStringAsFixed(0)}',
              '\u20B1${(p.price * p.stockQuantity).toStringAsFixed(0)}',
              p.stockQuantity <= p.reorderLevel ? 'LOW STOCK' : 'OK',
            ]).toList(),
          ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  static Future<void> generateDeliveryReport({
    required List<Delivery> deliveries,
    required String dateRange,
  }) async {
    final pdf = pw.Document();

    final verified = deliveries.where((d) => d.status == DeliveryStatus.delivered).length;
    final discrepancy = deliveries.where((d) => d.status == DeliveryStatus.discrepancy).length;
    final pending = deliveries.where((d) => d.status == DeliveryStatus.pending).length;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => pw.Header(
        level: 0,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Baycel Growcery', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
            pw.Text('Delivery Report', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ],
        ),
      ),
      footer: (context) => pw.Footer(
        trailing: pw.Text('Generated: ${DateTime.now().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 8)),
      ),
      build: (context) => [
        pw.SizedBox(height: 10),
        pw.Text('Period: $dateRange', style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 20),
        pw.Text('Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 10),
        _buildSummaryTable([
          ['Total Deliveries', deliveries.length.toString()],
          ['Verified', verified.toString()],
          ['Discrepancies', discrepancy.toString()],
          ['Pending', pending.toString()],
        ]),
        pw.SizedBox(height: 20),
        pw.Text('Delivery Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 10),
        if (deliveries.isEmpty)
          pw.Text('No deliveries found.', style: const pw.TextStyle(color: PdfColors.grey600))
        else
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Date', 'Supplier', 'Items', 'Status'],
            data: deliveries.map((d) => [
              d.createdAt.toString().substring(0, 10),
              d.supplierName,
              d.items.length.toString(),
              d.status.name.toUpperCase(),
            ]).toList(),
          ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  static pw.Widget _buildSummaryTable(List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      headers: ['Metric', 'Value'],
      data: rows,
    );
  }
}
