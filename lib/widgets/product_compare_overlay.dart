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

class _ProductCompareOverlayState extends State<ProductCompareOverlay> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
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
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
    _extractProductInfo();
  }
  
  Future<void> _extractProductInfo() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final productService = Provider.of<ProductCompareService>(context, listen: false);
      final product = await productService.extractProductFromPage(widget.currentUrl);
      
      if (!mounted) return;
      
      if (product == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No product found on this page';
        });
        return;
      }
      
      final alternatives = await productService.findAlternatives(product);
      
      if (!mounted) return;
      
      setState(() {
        _currentProduct = product;
        _alternatives = alternatives;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error comparing products: ${e.toString()}';
      });
    }
  }
  
  Future<void> _closeOverlay() async {
    await _animationController.reverse();
    if (mounted) {
      widget.onClose();
    }
  }
  
  Future<void> _navigateToProduct(String url) async {
    await _animationController.reverse();
    if (mounted) {
      widget.onClose();
      widget.onLoadUrl(url);
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
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          bottom: 16.0 + (100 * _slideAnimation.value),
          left: 16.0,
          right: 16.0,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 500,
                ),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 8),
                    Flexible(
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Product Comparison',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: _closeOverlay,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 24,
            minHeight: 24,
          ),
        ),
      ],
    );
  }
  
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _extractProductInfo,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_currentProduct == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No product found on this page'),
        ),
      );
    }
    
    return _buildProductComparison();
  }
  
  Widget _buildProductComparison() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentProduct(currencyFormat),
          const SizedBox(height: 16),
          _buildAlternatives(currencyFormat),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildCurrentProduct(NumberFormat currencyFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            _buildProductImage(_currentProduct!.imageUrl, 60),
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
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
    );
  }
  
  Widget _buildAlternatives(NumberFormat currencyFormat) {
    if (_alternatives.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Text('No alternative products found'),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Alternative Products (${_alternatives.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _alternatives.length,
            itemBuilder: (context, index) {
              final product = _alternatives[index];
              return _buildAlternativeCard(product, currencyFormat);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildAlternativeCard(Product product, NumberFormat currencyFormat) {
    final priceDifference = product.price - _currentProduct!.price;
    final isLowerPrice = priceDifference < 0;
    
    return Card(
      margin: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: () => _navigateToProduct(product.url),
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(product.imageUrl, 80),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
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
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${isLowerPrice ? '' : '+'}${currencyFormat.format(priceDifference.abs())}',
                            style: TextStyle(
                              color: isLowerPrice ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProductImage(String imageUrl, double size) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported),
          ),
        ),
      );
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: const Icon(Icons.shopping_bag),
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _closeOverlay,
          child: const Text('Close'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _currentProduct != null ? _showPriceTrackingDialog : null,
          child: const Text('Track Price'),
        ),
      ],
    );
  }
  
  void _showPriceTrackingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Price Tracking'),
        content: Text(
          'Would you like to track the price for "${_currentProduct!.name}"?\n\n'
          'Current price: ${NumberFormat.currency(symbol: '\$').format(_currentProduct!.price)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Price tracking enabled for ${_currentProduct!.name}'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {},
                  ),
                ),
              );
            },
            child: const Text('Track'),
          ),
        ],
      ),
    );
  }
}
