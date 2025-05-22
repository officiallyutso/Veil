import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:veil/services/search_elsewhere_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SearchElsewhereOverlay extends StatefulWidget {
  final WebViewController controller;
  final VoidCallback onClose;
  final Function(String) onLoadUrl;
  
  const SearchElsewhereOverlay({
    super.key,
    required this.controller,
    required this.onClose,
    required this.onLoadUrl,
  });

  @override
  State<SearchElsewhereOverlay> createState() => _SearchElsewhereOverlayState();
}

class _SearchElsewhereOverlayState extends State<SearchElsewhereOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  String? _selectedText;
  bool _isLoading = true;
  
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
    _getSelectedText();
  }
  
  Future<void> _getSelectedText() async {
    final searchService = Provider.of<SearchElsewhereService>(context, listen: false);
    final text = await searchService.getSelectedText(widget.controller);
    
    setState(() {
      _selectedText = text;
      _isLoading = false;
    });
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
          bottom: 16.0 + (80.0 * _animation.value),
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
                        'Search Elsewhere',
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
                  else if (_selectedText == null || _selectedText!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No text selected. Select some text to search elsewhere.'),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Selected text: "${_selectedText!}"',
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Consumer<SearchElsewhereService>(
                          builder: (context, searchService, child) {
                            return SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: searchService.allSources.length,
                                itemBuilder: (context, index) {
                                  final source = searchService.allSources[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 16.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            _searchInSource(searchService, source);
                                          },
                                          borderRadius: BorderRadius.circular(8.0),
                                          child: Container(
                                            width: 50,
                                            height: 50,
                                            padding: const EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surface,
                                              borderRadius: BorderRadius.circular(8.0),
                                              border: Border.all(
                                                color: Theme.of(context).dividerColor,
                                              ),
                                            ),
                                            child: SvgPicture.asset(
                                              source.iconPath,
                                              width: 24,
                                              height: 24,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          source.name,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _searchInSource(SearchElsewhereService searchService, SearchSource source) {
    if (_selectedText == null || _selectedText!.isEmpty) return;
    
    final url = source.getSearchUrl(_selectedText!);
    
    // Close the overlay
    _animationController.reverse().then((_) {
      widget.onClose();
      
      // Load the URL in the current tab
      widget.onLoadUrl(url);
    });
  }
}