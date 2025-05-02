import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device & Network Info',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.devices_other, color: Colors.deepPurple),
              title: Text('Device: My Computer'),
              subtitle: Text('IP: 192.168.1.10\nStatus: Connected'),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Quick Send',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.flash_on, color: Colors.purple),
              title: Text('Send file to trusted device'),
              trailing: ElevatedButton(child: Text('Send'), onPressed: () {}),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Clipboard Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.content_copy),
                label: Text('Send Clipboard'),
                onPressed: () {},
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.download),
                label: Text('Pull Clipboard'),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
