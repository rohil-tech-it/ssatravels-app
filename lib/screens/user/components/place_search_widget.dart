// lib/screens/user/components/place_search_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ssatravels_app/services/route_service.dart';

class PlaceSearchWidget extends StatefulWidget {
  final RouteService routeService;
  final Function(Map<String, dynamic>) onPlaceSelected;
  final String hintText;
  final IconData prefixIcon;
  final Color themeColor;

  const PlaceSearchWidget({
    Key? key,
    required this.routeService,
    required this.onPlaceSelected,
    required this.hintText,
    this.prefixIcon = Icons.search,
    this.themeColor = const Color(0xFF00C853),
  }) : super(key: key);

  @override
  State<PlaceSearchWidget> createState() => _PlaceSearchWidgetState();
}

class _PlaceSearchWidgetState extends State<PlaceSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = false;
  Timer? _debounce;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _predictions.clear());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    
    if (query.length < 3) {
      setState(() => _predictions.clear());
      return;
    }
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);
      
      final results = await widget.routeService.searchPlaces(query);
      
      if (mounted) {
        setState(() {
          _predictions = results;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _selectPlace(Map<String, dynamic> prediction) async {
    setState(() => _isLoading = true);
    
    final details = await widget.routeService.getPlaceDetails(prediction['place_id']);
    
    if (details != null && mounted) {
      widget.onPlaceSelected(details);
      _controller.text = details['address'] ?? details['name'] ?? '';
      setState(() => _predictions.clear());
      _focusNode.unfocus();
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(widget.prefixIcon, color: widget.themeColor),
              suffixIcon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _predictions.clear());
                          },
                        )
                      : null,
            ),
          ),
        ),
        
        if (_predictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  leading: Icon(Icons.place, color: widget.themeColor),
                  title: Text(
                    prediction['main_text'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(prediction['secondary_text'] ?? ''),
                  onTap: () => _selectPlace(prediction),
                );
              },
            ),
          ),
      ],
    );
  }
}