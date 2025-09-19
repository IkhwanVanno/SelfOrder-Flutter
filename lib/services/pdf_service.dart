import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:selforder/services/api_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Generate receipt PDF
  Future<ApiResponse<String>> generateReceiptPdf({
    required Map<String, dynamic> order,
    required List<Map<String, dynamic>> orderItems,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final pdf = pw.Document();

      // Create PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              _buildHeader(),
              pw.SizedBox(height: 20),
              _buildOrderInfo(order),
              pw.SizedBox(height: 20),
              _buildOrderItems(orderItems),
              pw.SizedBox(height: 20),
              _buildPaymentSummary(order, paymentDetails),
              pw.SizedBox(height: 20),
              _buildFooter(),
            ];
          },
        ),
      );

      // Save PDF to file
      final output = await _getOutputFile('receipt_${order['ID']}.pdf');
      final file = File(output.path);
      await file.writeAsBytes(await pdf.save());

      return ApiResponse.success(file.path);
    } catch (e) {
      return ApiResponse.error('Failed to generate PDF: $e');
    }
  }

  // Generate order report PDF
  Future<ApiResponse<String>> generateOrderReportPdf({
    required List<Map<String, dynamic>> orders,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final pdf = pw.Document();

      // Calculate totals
      int totalOrders = orders.length;
      int totalAmount = 0;
      int totalItems = 0;

      for (var order in orders) {
        totalAmount += (order['TotalAmount'] as int? ?? 0);
        // Count items if available
        if (order['Items'] != null) {
          final items = order['Items'] as List<dynamic>;
          for (var item in items) {
            totalItems += (item['Quantity'] as int? ?? 0);
          }
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              _buildReportHeader(startDate, endDate),
              pw.SizedBox(height: 20),
              _buildReportSummary(totalOrders, totalAmount, totalItems),
              pw.SizedBox(height: 20),
              _buildOrdersTable(orders),
              pw.SizedBox(height: 20),
              _buildFooter(),
            ];
          },
        ),
      );

      final fileName = 'order_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final output = await _getOutputFile(fileName);
      final file = File(output.path);
      await file.writeAsBytes(await pdf.save());

      return ApiResponse.success(file.path);
    } catch (e) {
      return ApiResponse.error('Failed to generate report PDF: $e');
    }
  }

  // Share PDF file
  Future<ApiResponse<bool>> sharePdf({
    required String filePath,
    String? subject,
    String? text,
  }) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'Receipt',
        text: text ?? 'Please find the attached receipt.',
      );
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to share PDF: $e');
    }
  }

  // Download PDF to device storage
  Future<ApiResponse<String>> downloadPdf({
    required String filePath,
    String? customName,
  }) async {
    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          return ApiResponse.error('Storage permission denied');
        }
      }

      // Get downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null || !downloadsDir.existsSync()) {
        downloadsDir = await getExternalStorageDirectory();
      }

      if (downloadsDir == null) {
        return ApiResponse.error('Could not access storage directory');
      }

      final sourceFile = File(filePath);
      final fileName = customName ?? sourceFile.uri.pathSegments.last;
      final targetFile = File('${downloadsDir.path}/$fileName');

      await sourceFile.copy(targetFile.path);

      return ApiResponse.success(targetFile.path);
    } catch (e) {
      return ApiResponse.error('Failed to download PDF: $e');
    }
  }

  // Build PDF header
  pw.Widget _buildHeader() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Text(
            'SelfOrder Cafe',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Jl. Contoh No. 123, Surabaya',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Telp: 031-1234567 | Email: info@selforder.com',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Divider(thickness: 2),
        ],
      ),
    );
  }

  // Build order information section
  pw.Widget _buildOrderInfo(Map<String, dynamic> order) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RECEIPT',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Order ID: ${order['ID'] ?? 'N/A'}'),
                  pw.Text('Invoice: ${order['InvoiceNumber'] ?? 'N/A'}'),
                  pw.Text('Table Number: ${order['TableNumber'] ?? 'N/A'}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Date: ${_formatDate(order['Created'])}'),
                  pw.Text('Status: ${order['Status'] ?? 'N/A'}'),
                  pw.Text('Payment: ${order['PaymentMethod'] ?? 'N/A'}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build order items table
  pw.Widget _buildOrderItems(List<Map<String, dynamic>> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Order Items',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            // Items
            ...items.map((item) {
              final quantity = item['Quantity'] as int? ?? 0;
              final price = item['Price'] as int? ?? 0;
              final total = quantity * price;

              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(item['ProductName'] ?? item['Name'] ?? 'N/A'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(quantity.toString()),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(_currencyFormat.format(price)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(_currencyFormat.format(total)),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // Build payment summary
  pw.Widget _buildPaymentSummary(
    Map<String, dynamic> order,
    Map<String, dynamic>? paymentDetails,
  ) {
    final totalAmount = order['TotalAmount'] as int? ?? 0;
    final adminFee = 3000;
    final subtotal = totalAmount - adminFee;

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        child: pw.Column(
          children: [
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('totalAmount:'),
                pw.Text(_currencyFormat.format(subtotal)),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Admin Fee:'),
                pw.Text(_currencyFormat.format(adminFee)),
              ],
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  _currencyFormat.format(totalAmount),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            if (paymentDetails != null) ...[
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Text(
                'Payment Details',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              if (paymentDetails['reference'] != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Reference:'),
                    pw.Text(paymentDetails['reference'].toString()),
                  ],
                ),
              if (paymentDetails['vaNumber'] != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('VA Number:'),
                    pw.Text(paymentDetails['vaNumber'].toString()),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  // Build report header
  pw.Widget _buildReportHeader(DateTime? startDate, DateTime? endDate) {
    String dateRange = '';
    if (startDate != null && endDate != null) {
      dateRange = '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}';
    } else if (startDate != null) {
      dateRange = 'From ${_dateFormat.format(startDate)}';
    } else if (endDate != null) {
      dateRange = 'Until ${_dateFormat.format(endDate)}';
    } else {
      dateRange = 'All Time';
    }

    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Text(
            'ORDER REPORT',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            dateRange,
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Generated: ${_dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Build report summary
  pw.Widget _buildReportSummary(int totalOrders, int totalAmount, int totalItems) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text(
                totalOrders.toString(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Total Orders'),
            ],
          ),
          pw.Column(
            children: [
              pw.Text(
                _currencyFormat.format(totalAmount),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Total Revenue'),
            ],
          ),
          pw.Column(
            children: [
              pw.Text(
                totalItems.toString(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Total Items'),
            ],
          ),
        ],
      ),
    );
  }

  // Build orders table for report
  pw.Widget _buildOrdersTable(List<Map<String, dynamic>> orders) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Order Details',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Order ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Table', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            // Orders
            ...orders.map((order) {
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(order['ID']?.toString() ?? 'N/A'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(_formatDate(order['Created'])),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(order['TableNumber']?.toString() ?? 'N/A'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(order['Status'] ?? 'N/A'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(_currencyFormat.format(order['TotalAmount'] ?? 0)),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  // Build footer
  pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Divider(),
          pw.Text(
            'Thank you for your order!',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Follow us on social media @selfordercafe',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Get output file
  Future<File> _getOutputFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${directory.path}/pdfs');
    
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    
    return File('${pdfDir.path}/$fileName');
  }

  // Format date
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    
    DateTime dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date) ?? DateTime.now();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'N/A';
    }
    
    return _dateFormat.format(dateTime);
  }
}