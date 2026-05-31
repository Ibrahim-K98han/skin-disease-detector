import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'history_model.dart';
import 'history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await HistoryService.getHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    // Confirm dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('History মুছবে?'),
        content: const Text('সব history মুছে যাবে!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('হ্যাঁ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await HistoryService.clearHistory();
      setState(() => _history = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📋 স্ক্যান ইতিহাস',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
              tooltip: 'সব মুছো',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'কোনো history নেই',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'ছবি scan করলে এখানে দেখাবে',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return _buildHistoryCard(item);
              },
            ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final color = item.confidence > 70 ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ছবি
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: File(item.imagePath).existsSync()
                  ? Image.file(
                      File(item.imagePath),
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.diseaseBangla,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.disease,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.percent, size: 14, color: color),
                      Text(
                        ' ${item.confidence.toStringAsFixed(1)}% নিশ্চিত',
                        style: TextStyle(
                          fontSize: 13,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      Text(
                        ' ${dateFormat.format(item.dateTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
