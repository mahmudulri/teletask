import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class LiveSMSDebugPage extends StatefulWidget {
  const LiveSMSDebugPage({super.key});

  @override
  _LiveSMSDebugPageState createState() => _LiveSMSDebugPageState();
}

class _LiveSMSDebugPageState extends State<LiveSMSDebugPage> {
  late IO.Socket socket;
  List<Map<String, dynamic>> logs = [];

  final String token =
      "eyJpdiI6Imk0OGhHQ3dZTWlNVHZ0UVE2cHRzWHc9PSIsInZhbHVlIjoiUnBJb291TVZzTGtvNFZFNWlyMDJTNm1OaE9STGVUNTM0Q0ZJQkxJdUdweHd2cmRrMFlkaHlnVlZOVlFJd0RWMDRhOHNmUTdhNlAxM29pSjlOZWNXZ3IyczdCeTl5S2Z3bUI5dmhoZ1pJY2Q3a2QxQjhIOFNHd1pNdXpFMDVkQXBWVTZFTm94UklpTFRRUVdvVDZwL1JweTNlQlZ2NzkxS1pkTnlWamtJM1FXMjFlb0l2UGk5dXhmTEYydGNDUXhNV0srVjNtaTJlREdNZzZ3M2ZuYTY3L08wbXRjUkdGUlVVYWUzYm5ta0pYc1dkaGhzOGJJYkhUYjNBNHNPbk5rT3JxSTJDZ3IreFYxVnZyZk1ESlhwVjNyMlBIM2NhM3pYaHFxNG5uNnZSTmR1eStlNjB3UWFZSU96aUs2TTgxUlpoWndaUmZvRzEzR3loYkhLbEQ5VEhYWEdFTTJ3ZC9iUUVOVHhJWndyay80a1JPL1M0SXpnY1ZtbnRTNkFLZXFyQ09WR2UxYXZJa1l1cTdrMlUzYUJ5T1M2bDBYVlhXQTMxdnFvcDkzTWx0R3dob0VCWVJnTS9ZUTcrS21pUk5jWUNjU1dBL3M1bTl1dlgyVmRsWFVWV1I4K1ZSRUlwMERGTi9rSjVSUnR6eGdEelBWOGk2Z093VDNscmtXTFlIQ3lYUUtSWjlFMTJyMXRwWGpRdWIyMkF4cWplcVo1S09WTXF0RXY2eGZwNlprPSIsIm1hYyI6ImQ1MDNkYjFlZTQxMzI1OTEwOTJmNGU0MjZmZTM4NjViYjUwMmNiNjkxY2MxNDA5Njc3ZDUzMmYwMjU0NzgxNGIiLCJ0YWciOiIifQ%3D%3D";

  final String user = "ad048fd835e108025245f5ae473853fb";

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io(
      'wss://ivasms.com:2087',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'token': token, 'user': user})
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      _addLog('✅ Connected to WebSocket', '');
    });

    socket.onDisconnect((_) {
      _addLog('⚠️ Disconnected', '');
    });

    socket.onConnectError((err) {
      _addLog('❌ Connection Error', err.toString());
    });

    socket.onAny((event, data) {
      _addLog('📡 Event: $event', data);
    });
  }

  // void _addLog(String title, dynamic data) {
  //   // ✅ Filter: Only show Panama-related events
  //   if (data is Map && data['country_iso'] == 'pa') {
  //     setState(() {
  //       logs.insert(0, {
  //         'title': title,
  //         'data': data.toString(),
  //       });
  //     });
  //   } else if (data.toString().toLowerCase().contains("PANAMA")) {
  //     setState(() {
  //       logs.insert(0, {
  //         'title': title,
  //         'data': data.toString(),
  //       });
  //     });
  //   }
  // }
  void _addLog(String title, dynamic data) {
    if (data is Map && data.containsKey('termination_name')) {
      setState(() {
        logs.insert(0, {
          'title': title,
          'data': data, // store whole map, not just string
        });
      });
    }
  }

  //   void _addLog(String title, dynamic data) {
  //   if (data is Map && data.containsKey('termination_name')) {
  //     final terminationName =
  //         data['termination_name']?.toString().toLowerCase() ?? '';
  //     if (terminationName.contains('panama')) {
  //       setState(() {
  //         logs.insert(0, {
  //           'title': title,
  //           'data': data['termination_name'] ?? '',
  //         });
  //       });
  //     }
  //   }
  // }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  bool _isPanamaOrPeru(dynamic data) {
    if (data is Map && data.containsKey('termination_name')) {
      final name = data['termination_name'].toString().toUpperCase();
      return name.contains('PANAMA') || name.contains('PERU');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: const Text('Live SMS Update'),
      ),
      body: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.all(12),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return Card(
            color: _isPanamaOrPeru(log['data']) ? Colors.green : Colors.white,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log['data'] is Map
                        ? (log['data']['termination_name'] ??
                            log['data'].toString())
                        : log['data'].toString(),
                    style: TextStyle(
                      fontSize: 20,
                      color: _isPanamaOrPeru(log['data'])
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
