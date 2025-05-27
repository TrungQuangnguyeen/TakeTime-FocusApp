import 'package:flutter/material.dart';
import 'package:smart_management_app/services/app_blocking_service.dart';

class BlockingDebugScreen extends StatefulWidget {
  const BlockingDebugScreen({Key? key}) : super(key: key);

  @override
  State<BlockingDebugScreen> createState() => _BlockingDebugScreenState();
}

class _BlockingDebugScreenState extends State<BlockingDebugScreen> {
  Map<String, dynamic>? _diagnosticsResult;
  List<String> _serviceLogs = [];
  bool _isRunningDiagnostics = false;
  bool _isLoadingLogs = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
    _loadServiceLogs();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunningDiagnostics = true;
    });

    try {
      final result = await AppBlockingService.runDiagnostics();
      setState(() {
        _diagnosticsResult = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error running diagnostics: $e')),
      );
    } finally {
      setState(() {
        _isRunningDiagnostics = false;
      });
    }
  }

  Future<void> _loadServiceLogs() async {
    setState(() {
      _isLoadingLogs = true;
    });

    try {
      final logs = await AppBlockingService.getServiceLogs();
      setState(() {
        _serviceLogs = logs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading service logs: $e')),
      );
    } finally {
      setState(() {
        _isLoadingLogs = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    final success = await AppBlockingService.clearServiceLogs();
    if (success) {
      await _loadServiceLogs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service logs cleared')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to clear service logs')),
      );
    }
  }

  Future<void> _testOverlay() async {
    final success = await AppBlockingService.testOverlayDisplay();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Overlay test successful' : 'Overlay test failed'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    bool accessibilityResult = await AppBlockingService.requestAccessibilityPermission();
    bool usageStatsResult = await AppBlockingService.requestUsageStatsPermission();
    bool overlayResult = await AppBlockingService.requestOverlayPermission();

    String message = 'Permission requests:\n'
        'Accessibility: ${accessibilityResult ? 'Success' : 'Failed'}\n'
        'Usage Stats: ${usageStatsResult ? 'Success' : 'Failed'}\n'
        'Overlay: ${overlayResult ? 'Success' : 'Failed'}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    // Refresh diagnostics after permission requests
    await _runDiagnostics();
  }

  Widget _buildDiagnosticsCard() {
    if (_isRunningDiagnostics) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Running diagnostics...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_diagnosticsResult == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No diagnostics data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Diagnostics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._diagnosticsResult!.entries.map((entry) {
              return _buildDiagnosticItem(entry.key, entry.value);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticItem(String key, dynamic value) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help;

    if (value is bool) {
      statusColor = value ? Colors.green : Colors.red;
      statusIcon = value ? Icons.check_circle : Icons.error;
    } else if (value is int) {
      statusColor = value > 0 ? Colors.green : Colors.orange;
      statusIcon = value > 0 ? Icons.check_circle : Icons.warning;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatDiagnosticKey(key),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            _formatDiagnosticValue(value),
            style: TextStyle(color: statusColor),
          ),
        ],
      ),
    );
  }

  String _formatDiagnosticKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDiagnosticValue(dynamic value) {
    if (value is bool) {
      return value ? 'Enabled' : 'Disabled';
    } else if (value is List) {
      return '${value.length} items';
    } else if (value == null) {
      return 'N/A';
    }
    return value.toString();
  }

  Widget _buildServiceLogsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Service Logs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _loadServiceLogs,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh logs',
                    ),
                    IconButton(
                      onPressed: _clearLogs,
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear logs',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingLogs)
              const Center(child: CircularProgressIndicator())
            else if (_serviceLogs.isEmpty)
              const Text(
                'No service logs available',
                style: TextStyle(color: Colors.grey),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: _serviceLogs.length,
                  itemBuilder: (context, index) {
                    final log = _serviceLogs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ),
                      child: Text(
                        log,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocking System Debug'),
        actions: [
          IconButton(
            onPressed: _runDiagnostics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh diagnostics',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDiagnosticsCard(),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _requestAllPermissions,
                            icon: const Icon(Icons.security),
                            label: const Text('Request Permissions'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _testOverlay,
                            icon: const Icon(Icons.visibility),
                            label: const Text('Test Overlay'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await AppBlockingService.openAppSettings();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Open App Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildServiceLogsCard(),
          ],
        ),
      ),
    );
  }
}
