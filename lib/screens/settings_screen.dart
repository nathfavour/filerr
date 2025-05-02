import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _serviceUri;
  int? _port;
  String? _localIp;
  bool _loading = true;
  String? _error;
  bool _showQrDialog = false;
  String? _scannedServiceUri;
  int? _scannedPort;
  String? _scannedIp;

  @override
  void initState() {
    super.initState();
    _loadServiceInfo();
  }

  Future<void> _loadServiceInfo() async {
    try {
      final home =
          Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '';
      final configFile = File('$home/.noplacelike.json');
      if (!await configFile.exists()) {
        setState(() {
          _error = '.noplacelike.json not found in home directory.';
          _loading = false;
        });
        return;
      }
      final config = jsonDecode(await configFile.readAsString());
      final port = config['port'] ?? 8000;
      final ip = await _getLocalIp();
      final uri = 'http://$ip:$port';
      setState(() {
        _port = port;
        _localIp = ip;
        _serviceUri = uri;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading service info: $e';
        _loading = false;
      });
    }
  }

  Future<String> _getLocalIp() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
          return addr.address;
        }
      }
    }
    return '127.0.0.1';
  }

  Future<void> _scanQrAndSetService() async {
    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      // Fallback to dialog for non-mobile
      final result = await showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Simulate QR Scan'),
              content: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Paste service URI (e.g. http://192.168.1.2:8000)',
                ),
                onSubmitted: (value) => Navigator.of(context).pop(value),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
      );
      if (result != null && result.startsWith('http')) {
        final uri = Uri.tryParse(result);
        setState(() {
          _scannedServiceUri = result;
          _scannedPort = uri?.port;
          _scannedIp = uri?.host;
        });
      }
      return;
    }
    // On mobile, use QR scanner
    final result = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (context) => QrScanScreen()));
    if (result != null && result.startsWith('http')) {
      final uri = Uri.tryParse(result);
      setState(() {
        _scannedServiceUri = result;
        _scannedPort = uri?.port;
        _scannedIp = uri?.host;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(24),
          child:
              isMobile
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.qr_code_scanner,
                            color: Colors.deepPurple,
                          ),
                          title: Text('Scan Pairing QR Code'),
                          subtitle: Text(
                            'Scan a QR code from your desktop/server to connect.',
                          ),
                          trailing: ElevatedButton(
                            child: Text('Scan'),
                            onPressed: _scanQrAndSetService,
                          ),
                        ),
                      ),
                      if (_scannedServiceUri != null)
                        Card(
                          child: ListTile(
                            leading: Icon(Icons.link, color: Colors.purple),
                            title: Text('Service URI'),
                            subtitle: Text(_scannedServiceUri!),
                          ),
                        ),
                      if (_scannedPort != null)
                        Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.settings_ethernet,
                              color: Colors.purple,
                            ),
                            title: Text('Service Port'),
                            subtitle: Text('${_scannedPort ?? ''}'),
                          ),
                        ),
                      if (_scannedIp != null)
                        Card(
                          child: ListTile(
                            leading: Icon(Icons.router, color: Colors.purple),
                            title: Text('Service IP'),
                            subtitle: Text(_scannedIp!),
                          ),
                        ),
                      SizedBox(height: 24),
                      Text(
                        'Other Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('About filerr'),
                        subtitle: Text(
                          'A fast, local network file transfer app.',
                        ),
                      ),
                    ],
                  )
                  : (_loading
                      ? Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Card(
                            child: ListTile(
                              leading: Icon(
                                Icons.qr_code,
                                color: Colors.deepPurple,
                              ),
                              title: Text('Pairing QR Code'),
                              subtitle: Text(
                                'Scan this code on your mobile device to pair.',
                              ),
                              trailing:
                                  _serviceUri != null
                                      ? GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showQrDialog = true;
                                          });
                                        },
                                        child: QrImageView(
                                          data: _serviceUri!,
                                          version: QrVersions.auto,
                                          size: 80.0,
                                        ),
                                      )
                                      : SizedBox.shrink(),
                            ),
                          ),
                          if (_serviceUri != null)
                            Card(
                              child: ListTile(
                                leading: Icon(Icons.link, color: Colors.purple),
                                title: Text('Service URI'),
                                subtitle: Text(_serviceUri!),
                              ),
                            ),
                          if (_port != null)
                            Card(
                              child: ListTile(
                                leading: Icon(
                                  Icons.settings_ethernet,
                                  color: Colors.purple,
                                ),
                                title: Text('Service Port'),
                                subtitle: Text('$_port'),
                              ),
                            ),
                          if (_localIp != null)
                            Card(
                              child: ListTile(
                                leading: Icon(
                                  Icons.router,
                                  color: Colors.purple,
                                ),
                                title: Text('Local IP Address'),
                                subtitle: Text(_localIp!),
                              ),
                            ),
                          SizedBox(height: 24),
                          Text(
                            'App Data Directories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Card(
                            child: ListTile(
                              leading: Icon(
                                Icons.folder_special,
                                color: Colors.purple,
                              ),
                              title: Text('.noplacelike & .filerr'),
                              subtitle: Text(
                                'These folders in your home directory help filerr manage transfers and state.',
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Other Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          ListTile(
                            leading: Icon(Icons.info_outline),
                            title: Text('About filerr'),
                            subtitle: Text(
                              'A fast, local network file transfer app.',
                            ),
                          ),
                        ],
                      )),
        ),
        if (!isMobile && _showQrDialog && _serviceUri != null)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QrImageView(
                              data: _serviceUri!,
                              version: QrVersions.auto,
                              size: 260.0,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Scan this QR code to pair',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: Icon(Icons.close),
                              label: Text('Close'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showQrDialog = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class QrScanScreen extends StatefulWidget {
  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool scanned = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.deepPurple,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 250,
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.close),
                label: Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!scanned) {
        scanned = true;
        controller.pauseCamera();
        Navigator.of(context).pop(scanData.code);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
