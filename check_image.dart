import 'dart:io';

void main() async {
  final file = File('assets/images/pixel_residents/admin_001.png');
  if (await file.exists()) {
    print('File exists. Size: ${await file.length()} bytes');
  } else {
    print('File does not exist!');
  }
}
