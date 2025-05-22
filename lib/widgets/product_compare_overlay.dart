import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veil/services/product_compare_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';

class ProductCompareOverlay extends StatefulWidget {
  final WebViewController controller;
  final String currentUrl;
  final VoidCallback onClose;
  final Function(String) onLoadUrl;
  
  const ProductCompareOverlay({
    super.key,
    required this.controller,
    required this.currentUrl,
    required this.onClose,
    required this.onLoadUrl,
  });

  @override
  State<ProductCompareOverlay> createState() => _ProductCompareOverlayState();
}

class _ProductCompareOverlayState extends State<ProductCompareOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isLoading = true;
  Product? _currentProduct;
  List<Product> _alternatives = [];
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _animationController.forward();
    _extractProductInfo();
  }
  
  Future<void> _extractProductInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final productService = Provider.of<ProductCompareService>(context, listen: false);
      final product = await productService.extractProductFromPage(widget.currentUrl);
      
      if (product == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No product found on this page';
        });
        return;
      }
      
      final alternatives = await productService.findAlternatives(product);
      
      setState(() {
        _currentProduct = product;
        _alternatives = alternatives;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error comparing products: $e';
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          bottom: 16.0,
          left: 16.0,
          right: 16.0,
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Product Comparison',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _animationController.reverse().then((_) {
                            widget.onClose();
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_errorMessage.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(_errorMessage),
                      ),
                    )
                  else if (_currentProduct == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No product found on this page'),
                      ),
                    )
                  else
                    _buildProductComparison(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProductComparison() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current product
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                if (_currentProduct!.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.network(
                      _currentProduct!.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.shopping_bag),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentProduct!.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current price: ${currencyFormat.format(_currentProduct!.price)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'From: ${_currentProduct!.merchant}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
                // Alternatives
        if (_alternatives.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No alternative products found'),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Alternative Products',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _alternatives.length,
                  itemBuilder: (context, index) {
                    final product = _alternatives[index];
                    final priceDifference = product.price - _currentProduct!.price;
                    final isLowerPrice = priceDifference < 0;
                    
                    return Card(
                      margin: const EdgeInsets.only(right: 12.0),
                      child: InkWell(
                        onTap: () {
                          _animationController.reverse().then((_) {
                            widget.onClose();
                            widget.onLoadUrl(product.url);
                          });
                        },
                        child: Container(
                          width: 160,
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.imageUrl.isNotEmpty)
                                Center(
                                  child: Image.network(
                                    product.imageUrl,
                                    height: 80,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.shopping_bag),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                product.name,
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(product.price),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    isLowerPrice ? Icons.arrow_downward : Icons.arrow_upward,
                                    size: 14,
                                    color: isLowerPrice ? Colors.green : Colors.red,
                                  ),
                                  Text(
                                    '${isLowerPrice ? '' : '+'}${currencyFormat.format(priceDifference)}',
                                    style: TextStyle(
                                      color: isLowerPrice ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.merchant,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          
        const SizedBox(height: 16),
        
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                _animationController.reverse().then((_) {
                  widget.onClose();
                });
              },
              child: const Text('Close'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // Implement price tracking functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Price tracking will be implemented soon')),
                );
              },
              child: const Text('Track Price'),
            ),
          ],
        ),
      ],
    );
  }
}