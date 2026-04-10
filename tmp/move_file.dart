import 'dart:io';
void main() {
  Directory.current = 'c:/Users/drmus/OneDrive/Desktop/apps/ENT-ON-CALL/ent_on_call';
  var file = File('assets/Dr. Mustafa pixel art sprite sheet.png');
  var dest = File('assets/pixel_residents/mustafa_saleh_mahmood.png');
  if (file.existsSync()) {
    if (!dest.parent.existsSync()) {
      dest.parent.createSync(recursive: true);
    }
    file.renameSync(dest.path);
    print('Moved');
  } else {
    print('Source not found');
    print('Files in assets:');
    Directory('assets').listSync().forEach((f) => print(f.path));
  }
}
