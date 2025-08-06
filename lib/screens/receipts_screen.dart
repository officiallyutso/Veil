import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:veil/models/receipt_model.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({Key? key}) : super(key: key);

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Receipt> _receipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterReceipts();
      });
    });
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() { _isLoading = true; });
    final receiptService = Provider.of<dynamic>(context, listen: false); // Use your actual service type here
    final receipts = await receiptService.getAllReceipts();
    setState(() {
      _receipts = List<Receipt>.from(receipts);
      _isLoading = false;
    });
  }

  void _filterReceipts() {
    if (_searchQuery.isEmpty) {
      _loadReceipts();
      return;
    }
    final query = _searchQuery.toLowerCase();
    final receiptService = Provider.of<dynamic>(context, listen: false); // Use your actual service type here
    receiptService.getAllReceipts().then((allReceipts) {
      setState(() {
        _receipts = List<Receipt>.from(allReceipts).where((receipt) {
          return receipt.merchant.toLowerCase().contains(query) ||
              receipt.orderNumber.toLowerCase().contains(query) ||
              receipt.items.any((item) => item.name.toLowerCase().contains(query));
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showClearReceiptsDialog(context),
            tooltip: 'Clear All Receipts',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Receipts',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); })
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _receipts.isEmpty
                    ? Center(child: Text(_searchQuery.isEmpty ? 'No receipts found' : 'No results found for "$_searchQuery"'))
                    : ListView.builder(
                        itemCount: _receipts.length,
                        itemBuilder: (context, index) {
                          final receipt = _receipts[index];
                          return _buildReceiptCard(context, receipt);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context, Receipt receipt) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToReceiptDetails(context, receipt),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(receipt.merchant, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text(currencyFormat.format(receipt.total), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              if (receipt.orderNumber.isNotEmpty)
                Text('Order #: ${receipt.orderNumber}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text('Date: ${receipt.date}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text('${receipt.items.length} items', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Extracted: ${dateFormat.format(receipt.extractedAt)}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showReceiptOptions(context, receipt),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReceiptDetails(BuildContext context, Receipt receipt) {
    Navigator.pushNamed(context, '/receipt-details', arguments: receipt);
  }

  void _showReceiptOptions(BuildContext context, Receipt receipt) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToReceiptDetails(context, receipt);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  _shareReceipt(receipt);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteReceiptDialog(context, receipt);
                },
              ),
            ],
          ),
        );
      },
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

  void _showDeleteReceiptDialog(BuildContext context, Receipt receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: Text('Are you sure you want to delete the receipt from ${receipt.merchant}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final receiptService = Provider.of<dynamic>(context, listen: false); // Use your actual service type here
              await receiptService.deleteReceipt(receipt.id);
              await _loadReceipts();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt deleted')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearReceiptsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Receipts'),
        content: const Text('Are you sure you want to delete all receipts? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final receiptService = Provider.of<dynamic>(context, listen: false); // Use your actual service type here
              await receiptService.clearAllReceipts();
              await _loadReceipts();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All receipts cleared')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final receiptService = Provider.of<dynamic>(context, listen: false);
              await receiptService.clearAllReceipts();
              await _loadReceipts();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All receipts deteled')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
