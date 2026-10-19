import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderTrackingScreen extends StatefulWidget {
  
    const OrderTrackingScreen({
      required this.orderId,
      required this.orderNumber,
      required this.orderStatus,
      super.key,
    });

    final String orderId;
    final String orderNumber;
    final String orderStatus;

    @override
State<OrderTrackingScreen> createState() =>
    _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late String _currentStatus;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.orderStatus;
    _loadOrderStatus();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadOrderStatus(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderStatus() async {
    try {
      final result = await Supabase.instance.client
          .from('orders')
          .select('order_status')
          .eq('id', widget.orderId)
          .single();

      if (!mounted) return;

      setState(() {
        _currentStatus = result['order_status'].toString();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not refresh order status.';  
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
      if (_isLoading) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Track Order'),
            actions: [
              IconButton(
                onPressed: _loadOrderStatus,
                tooltip: 'Refresh order status',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      if (_errorMessage != null) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Track Order'),
            actions: [
              IconButton(
                onPressed: _loadOrderStatus,
                tooltip: 'Refresh order status',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: Center(child: Text(_errorMessage!)),
        );
      }
    final stages = [
      'Processing',
      'Shipped',
      'Delivered',
    ];

    final currentIndex = stages.indexWhere(
      (stage) => stage.toLowerCase() == _currentStatus.toLowerCase(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        actions: [
          IconButton(
            onPressed: _loadOrderStatus,
            tooltip: 'Refresh order status',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Order #${widget.orderNumber}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Follow the progress of your beauty order.',
          ),
          const SizedBox(height: 32),

          for (int i = 0; i < stages.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(
                      i <= currentIndex
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: i <= currentIndex
                          ? const Color(0xFFC15B7A)
                          : Colors.grey,
                      size: 28,
                    ),
                    if (i < stages.length - 1)
                      Container(
                        width: 2,
                        height: 55,
                        color: i < currentIndex
                            ? const Color(0xFFC15B7A)
                            : Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stages[i],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        i < currentIndex
                            ? 'Completed'
                            : i == currentIndex
                                ? 'Current order status'
                                : 'Waiting for update',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),
          const Text(
            'Tracking updates depend on your order status.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
