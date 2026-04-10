import 'dart:io';
import 'dart:typed_data';

void main() async {
  final file = File('c:/Users/drmus/OneDrive/Desktop/apps/ENT-ON-CALL/ent_on_call/assets/images/pixel_residents/resident_009.png');
  if (!file.existsSync()) {
    print('File not found');
    return;
  }
  
  final bytes = await file.readAsBytes();
  if (bytes.length < 24) {
    print('Invalid PNG');
    return;
  }
  
  // PNG dimensions are at offset 16 (width) and 20 (height) in big-endian
  final width = ByteData.sublistView(bytes, 16, 20).getUint32(0);
  final height = ByteData.sublistView(bytes, 20, 24).getUint32(0);
  
  print('Dimensions: $width x $height');
}
