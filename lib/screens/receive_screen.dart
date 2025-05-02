import 'package:flutter/material.dart';

class ReceiveScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receive Files',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.wifi_tethering, color: Colors.purple),
              title: Text('Waiting for incoming files...'),
              subtitle: Text('Make sure the sender is on the same network.'),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Recently Received',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.insert_drive_file, color: Colors.green),
                  title: Text('photo1.jpg'),
                  subtitle: Text('Received 2 min ago'),
                ),
                ListTile(
                  leading: Icon(Icons.insert_drive_file, color: Colors.green),
                  title: Text('document.pdf'),
                  subtitle: Text('Received 10 min ago'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
