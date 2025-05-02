import 'package:flutter/material.dart';

class SendScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Files',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.folder_open),
            label: Text('Pick Files or Folders'),
            onPressed: () {},
          ),
          SizedBox(height: 24),
          Text(
            'Trusted Devices',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: Icon(Icons.devices, color: Colors.deepPurple),
                  title: Text('Device A'),
                  subtitle: Text('192.168.1.12'),
                  trailing: ElevatedButton(
                    child: Text('Send'),
                    onPressed: () {},
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.devices, color: Colors.deepPurple),
                  title: Text('Device B'),
                  subtitle: Text('192.168.1.15'),
                  trailing: ElevatedButton(
                    child: Text('Send'),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
