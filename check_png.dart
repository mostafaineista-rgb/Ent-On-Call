import 'dart:io';

void main() async {
  final file = File('assets/images/pixel_residents/admin_001.png');
  final bytes = await file.readAsBytes();
  // check if first few bytes match PNG signature
  if (bytes.length > 8 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
    print('Valid PNG signature found.');
  } else {
    print('Invalid PNG signature!');
  }
}
