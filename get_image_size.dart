import 'dart:io';
import 'dart:typed_data';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart get_image_size.dart <path>');
    return;
  }
  final file = File(args[0]);
  if (!file.existsSync()) {
    print('File not found: ${args[0]}');
    return;
  }
  final bytes = file.readAsBytesSync();
  
  // PNG check
  if (bytes.length > 8 && 
      bytes[0] == 0x89 && bytes[1] == 0x50 && 
      bytes[2] == 0x4E && bytes[3] == 0x47) {
    print('Type: PNG');
    final data = ByteData.sublistView(bytes, 16, 24);
    final width = data.getUint32(0);
    final height = data.getUint32(4);
    print('Size: ${width}x$height');
    return;
  }

  // JPEG check
  if (bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
    print('Type: JPEG');
    int offset = 2;
    while (offset < bytes.length) {
      if (bytes[offset] == 0xFF) {
        final marker = bytes[offset + 1];
        if (marker == 0xC0 || marker == 0xC2) { // SOF0 or SOF2
          final height = (bytes[offset + 5] << 8) + bytes[offset + 6];
          final width = (bytes[offset + 7] << 8) + bytes[offset + 8];
          print('Size: ${width}x$height');
          return;
        }
        offset += 2 + (bytes[offset + 2] << 8) + bytes[offset + 3];
      } else {
        offset++;
      }
    }
  }
  print('Unknown format or could not find size.');
}
