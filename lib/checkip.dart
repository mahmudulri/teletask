import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class IPCheckerScreen extends StatefulWidget {
  @override
  _IPCheckerScreenState createState() => _IPCheckerScreenState();
}

class _IPCheckerScreenState extends State<IPCheckerScreen> {
  final TextEditingController _ipController = TextEditingController();
  String? country;
  String? city;
  String? isp;
  bool? hosting;
  bool isLoading = false;
  String? errorMessage;

  Future<void> checkIP(String ip) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http.get(Uri.parse("http://ip-api.com/json/$ip"));
      if (response.statusCode == 200) {
        print(response.body.toString());
        final data = jsonDecode(response.body);
        if (data['status'] == 'fail') {
          setState(() {
            errorMessage = 'Invalid IP or rate limited';
            isLoading = false;
          });
          return;
        }
        setState(() {
          country = data['country'];
          city = data['city'];
          isp = data['isp'];
          hosting = data['hosting'] ?? false;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IP Checker'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'Enter IP Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  isLoading ? null : () => checkIP(_ipController.text.trim()),
              child:
                  isLoading ? CircularProgressIndicator() : Text('Check Info'),
            ),
            SizedBox(height: 20),
            if (errorMessage != null) ...[
              Text(errorMessage!, style: TextStyle(color: Colors.red)),
            ] else if (country != null) ...[
              InfoRow(label: 'Country', value: country!),
              InfoRow(label: 'City', value: city ?? 'Unknown'),
              InfoRow(label: 'ISP', value: isp ?? 'Unknown'),
              InfoRow(
                  label: 'Hosting',
                  value: hosting! ? 'Yes (Datacenter)' : 'No (Residential)'),
            ],
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
