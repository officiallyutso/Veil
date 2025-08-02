import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:veil/models/receipt_model.dart';

class ReceiptDetailsScreen extends StatelessWidget {
  final Receipt receipt;

  const ReceiptDetailsScreen({Key? key, required this.receipt}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt from ${receipt.merchant}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReceipt(receipt),
            tooltip: 'Share',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(receipt.merchant, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(receipt.date, style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                    if (receipt.orderNumber.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.receipt, size: 16),
                          const SizedBox(width: 8),
                          Text('Order #: ${receipt.orderNumber}', style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Divider(),
                    ...receipt.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(item.name, style: Theme.of(context).textTheme.bodyMedium)),
                          Text(currencyFormat.format(item.price),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: Theme.of(context).textTheme.titleMedium),
                        Text(currencyFormat.format(receipt.total),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receipt Information', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text('Extracted Date'),
                      subtitle: Text(DateFormat('MMMM d, yyyy, h:mm a').format(receipt.extractedAt)),
                      leading: const Icon(Icons.access_time),
                    ),
                    ListTile(
                      title: const Text('Source URL'),
                      subtitle: Text(receipt.sourceUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                      leading: const Icon(Icons.link),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: receipt.sourceUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('URL copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareReceipt(Receipt receipt) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final receiptText = '''
Receipt from ${receipt.merchant}
Date: ${receipt.date}
${receipt.orderNumber.isNotEmpty ? 'Order #: ${receipt.orderNumber}\n' : ''}
Items:
${receipt.items.map((item) => '- ${item.name}: ${currencyFormat.format(item.price)}').join('\n')}
Total: ${currencyFormat.format(receipt.total)}
''';
    Share.share(receiptText, subject: 'Receipt from ${receipt.merchant}');
  }
}
