import 'package:flutter/material.dart';
import 'expandable_card.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExpandableCard Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: Scaffold(
        appBar: AppBar(title: const Text('ExpandableCard Demo')),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            ExpandableCard(
              header: const Text(
                'Order #1042',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onExpansionChanged: (expanded) {
                debugPrint('Order #1042 expanded: $expanded');
              },
              expandedContent: const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  '3x Wireless Mouse\n1x USB-C Cable\nShipped: 2 days ago\n'
                  'Delivery estimate: Tomorrow by 8 PM',
                ),
              ),
            ),
            const SizedBox(height: 12),
            ExpandableCard(
              header: const Text(
                'Order #1043',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              expandedContent: const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('1x Mechanical Keyboard\nStatus: Processing'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
