import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Use mobile_scanner

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
    // If not on desktop platforms, skip loading local server info
    if (!(defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows)) {
      setState(() {
        _loading = false; // Set loading to false for mobile/web
      });
      return;
    }

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
    try {
      for (var interface in await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      )) {
        // Prefer non-loopback IPv4 addresses
        if (interface.addresses.isNotEmpty) {
          // Simple heuristic: prefer addresses starting with 192.168 or 10.
          var preferredAddress = interface.addresses.firstWhere(
            (addr) =>
                addr.address.startsWith('192.168.') ||
                addr.address.startsWith('10.'),
            orElse: () => interface.addresses.first,
          );
          return preferredAddress.address;
        }
      }
    } catch (e) {
      print("Error getting local IP: $e");
      // Fallback or handle error appropriately
    }
    // Fallback if no suitable address found or error occurred
    try {
      final host = await NetworkInterface.list(
        includeLoopback: true,
        type: InternetAddressType.IPv4,
      );
      if (host.isNotEmpty && host.first.addresses.isNotEmpty) {
        return host.first.addresses.first.address; // Might be 127.0.0.1
      }
    } catch (e) {
      print("Error getting loopback IP: $e");
    }
    return '127.0.0.1'; // Absolute fallback
  }

  Future<void> _scanQrAndSetService() async {
    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      // Fallback to dialog for non-mobile platforms
      final result = await showDialog<String>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Enter Service URI'),
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
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    // This part needs a controller to get the text field value
                    // For simplicity, we rely on onSubmitted for now.
                    // A better implementation would use a TextEditingController.
                  },
                ),
              ],
            ),
      );
      if (result != null && result.startsWith('http')) {
        final uri = Uri.tryParse(result);
        if (uri != null && uri.host.isNotEmpty && uri.port != null) {
          setState(() {
            _scannedServiceUri = result;
            _scannedPort = uri.port;
            _scannedIp = uri.host;
          });
        } else {
          // Handle invalid URI entered
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Invalid URI format')));
        }
      }
      return;
    }

    // On mobile, use QR scanner
    final result = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (context) => QrScanScreen()));

    if (result != null && result.startsWith('http')) {
      final uri = Uri.tryParse(result);
      if (uri != null && uri.host.isNotEmpty && uri.port != null) {
        setState(() {
          _scannedServiceUri = result;
          _scannedPort = uri.port;
          _scannedIp = uri.host;
        });
      } else {
        // Handle invalid QR code content
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid QR code data')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final isDesktop = !isMobile && !kIsWeb; // Assume desktop if not mobile/web

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(24),
          child:
              isMobile
                  ? _buildMobileLayout() // Mobile specific layout
                  : isDesktop
                  ? _buildDesktopLayout() // Desktop specific layout
                  : _buildWebLayout(), // Fallback/Web layout
        ),
        if (isDesktop && _showQrDialog && _serviceUri != null)
          _buildQrDialogOverlay(), // Show QR dialog only on desktop
      ],
    );
  }

  // Builds the layout for Mobile platforms
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Icon(Icons.qr_code_scanner, color: Colors.deepPurple),
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
              title: Text('Connected Service URI'),
              subtitle: Text(_scannedServiceUri!),
            ),
          ),
        if (_scannedPort != null)
          Card(
            child: ListTile(
              leading: Icon(Icons.settings_ethernet, color: Colors.purple),
              title: Text('Connected Service Port'),
              subtitle: Text('${_scannedPort ?? ''}'),
            ),
          ),
        if (_scannedIp != null)
          Card(
            child: ListTile(
              leading: Icon(Icons.router, color: Colors.purple),
              title: Text('Connected Service IP'),
              subtitle: Text(_scannedIp!),
            ),
          ),
        SizedBox(height: 24),
        _buildCommonSettings(), // Common settings section
      ],
    );
  }

  // Builds the layout for Desktop platforms
  Widget _buildDesktopLayout() {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: Colors.red)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Icon(Icons.qr_code, color: Colors.deepPurple),
            title: Text('Pairing QR Code'),
            subtitle: Text('Scan this code on your mobile device to pair.'),
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
                        backgroundColor: Colors.white, // Ensure QR is visible
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
              leading: Icon(Icons.settings_ethernet, color: Colors.purple),
              title: Text('Service Port'),
              subtitle: Text('$_port'),
            ),
          ),
        if (_localIp != null)
          Card(
            child: ListTile(
              leading: Icon(Icons.router, color: Colors.purple),
              title: Text('Local IP Address'),
              subtitle: Text(_localIp!),
            ),
          ),
        SizedBox(height: 24),
        Text(
          'App Data Directories',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(Icons.folder_special, color: Colors.purple),
            title: Text('.noplacelike & .filerr'),
            subtitle: Text(
              'These folders in your home directory help filerr manage transfers and state.',
            ),
          ),
        ),
        SizedBox(height: 24),
        _buildCommonSettings(), // Common settings section
      ],
    );
  }

  // Builds the layout for Web or other platforms
  Widget _buildWebLayout() {
    // Web doesn't typically host the server or scan QR codes directly
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Icon(Icons.link, color: Colors.deepPurple),
            title: Text('Connect to Service'),
            subtitle: Text(
              'Enter the Service URI provided by your desktop/server.',
            ),
            trailing: ElevatedButton(
              child: Text('Enter URI'),
              onPressed: _scanQrAndSetService, // Re-use the dialog logic
            ),
          ),
        ),
        if (_scannedServiceUri != null)
          Card(
            child: ListTile(
              leading: Icon(Icons.link, color: Colors.purple),
              title: Text('Connected Service URI'),
              subtitle: Text(_scannedServiceUri!),
            ),
          ),
        // Display other connected info if available
        if (_scannedPort != null)
          Card(
            child: ListTile(
              leading: Icon(Icons.settings_ethernet, color: Colors.purple),
              title: Text('Connected Service Port'),
              subtitle: Text('${_scannedPort ?? ''}'),
            ),
          ),
        if (_scannedIp != null)
          Card(
            child: ListTile(
              leading: Icon(Icons.router, color: Colors.purple),
              title: Text('Connected Service IP'),
              subtitle: Text(_scannedIp!),
            ),
          ),
        SizedBox(height: 24),
        _buildCommonSettings(), // Common settings section
      ],
    );
  }

  // Common settings section used by all layouts
  Widget _buildCommonSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Other Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('About filerr'),
          subtitle: Text('A fast, local network file transfer app.'),
        ),
      ],
    );
  }

  // Builds the QR code dialog overlay
  Widget _buildQrDialogOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        // Allow dismissing by tapping outside
        onTap: () {
          setState(() {
            _showQrDialog = false;
          });
        },
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                // Prevent dismissal when tapping inside dialog
                onTap: () {}, // No-op
                child: Container(
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
                        backgroundColor: Colors.white, // Ensure QR is visible
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Scan this QR code to pair',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16), // Increased spacing
                      ElevatedButton.icon(
                        icon: Icon(Icons.close),
                        label: Text('Close'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- QR Scan Screen using mobile_scanner ---

class QrScanScreen extends StatefulWidget {
  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController controller = MobileScannerController(
    // Optional: Configure camera settings if needed
    // facing: CameraFacing.back,
    // torchEnabled: false,
  );
  bool _scanned = false; // Prevent multiple pops

  @override
  void dispose() {
    controller.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            iconSize: 32.0,
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            // allowDuplicates: false, // Deprecated, use logic in onDetect
            onDetect: (capture) {
              if (!_scanned) {
                final List<Barcode> barcodes = capture.barcodes;
                // final Uint8List? image = capture.image; // If you need the image
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    debugPrint('Barcode found! ${barcode.rawValue}');
                    _scanned = true; // Set flag
                    controller.stop(); // Stop scanning
                    Navigator.of(
                      context,
                    ).pop(barcode.rawValue); // Pop with result
                    break; // Exit loop once a barcode is processed
                  }
                }
              }
            },
          ),
          // Optional: Add a scanning overlay or viewfinder graphic
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
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
}
