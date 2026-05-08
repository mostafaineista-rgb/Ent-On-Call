import 'dart:convert';
import 'dart:io';

void main() async {
  const url = 'https://script.google.com/macros/s/AKfycbzBcWqCUHr3ETfVTNJIiskoIefy3AONlL4ZS3Y-92UcF9pEqNqqcmynimWDLaXYRH09ww/exec';
  
  final client = HttpClient();
  
  print('--- TESTING NEW OPTIMIZED URL ---');
  final stopwatch = Stopwatch()..start();
  try {
    final request = await client.getUrl(Uri.parse('$url?action=bootstrap')).timeout(Duration(seconds: 30));
    final response = await request.close();
    print('Status: ${response.statusCode}');
    
    String body;
    if (response.statusCode == 302 || response.statusCode == 301) {
      final loc = response.headers.value('location')!;
      final req2 = await client.getUrl(Uri.parse(loc));
      final res2 = await req2.close();
      body = await res2.transform(utf8.decoder).join();
    } else {
      body = await response.transform(utf8.decoder).join();
    }
    
    stopwatch.stop();
    print('Response time: ${stopwatch.elapsedMilliseconds}ms');
    
    final data = jsonDecode(body);
    print('Keys: ${data.keys.toList()}');
    
    if (data.containsKey('specialists')) {
       print('Specialists: ${data['specialists'].length}');
    }
    if (data.containsKey('specialists_daily')) {
       print('Specialists Daily: ${data['specialists_daily'].length}');
    }
    if (data.containsKey('specialists_today')) {
       print('Today Assignment: ${data['specialists_today'] != null}');
    }

  } catch (e) {
    print('Error: $e');
  }
  client.close();
}
