// This app will compress the country flags in the assets folder to a single file.
import 'dart:io';

const kTypeInt = 4; // 32 bits, max value 4294967295 (2^32 - 1)
const kTypeShort = 2; // 16 bits, max value 65535 (2^16 - 1)
const kTypeByte = 1; // 8 bits, max value 255 (2^8 - 1)
const kTypeIntMax = 4294967295;
const kTypeShortMax = 65535;
const kTypeByteMax = 255;

const kFileLengthBytes = kTypeInt;
const kFileNameBytes = kTypeByte;

void main() {
  final siFlagsDir = Directory('res/si');
  final targetFile = File('res/all.bin');

  // File structure:
  // 1 bytes: number of flags
  // 1 bytes: flag code length
  // n bytes: flag code
  // 4 bytes: flag data length
  // n bytes: flag data

  final files = siFlagsDir.listSync().whereType<File>().toList();
  assert(files.isNotEmpty, 'No flags found in ${siFlagsDir.path}');
  assert(files.length < kTypeShortMax,
      'Too many flags: ${files.length} < $kTypeShortMax');
  final sink = targetFile.openWrite()
    ..add(intToBytes(files.length, kTypeShort));

  const maxFileContentLength = kTypeIntMax;
  const maxFileNamesLength = kTypeByteMax;

  for (final file in files) {
    final flagCode = file.path.split('\\').last.split('.').first;
    final lengthSync = file.lengthSync();
    assert(lengthSync < maxFileContentLength,
        '$file is too large: $lengthSync < $maxFileContentLength');
    final codeUnits = flagCode.codeUnits;
    assert(codeUnits.length < maxFileNamesLength,
        'Flag code $flagCode is too long: ${codeUnits.length}');
    sink.add(
      [
        ...intToBytes(codeUnits.length, kFileNameBytes),
        ...codeUnits,
        ...intToBytes(lengthSync, kFileLengthBytes),
        ...file.readAsBytesSync(),
      ],
    );
  }
  sink.close();
  print('Compressed ${files.length} flags to ${targetFile.path}');
}

List<int> intToBytes(int value, int maxBytes) {
  // big endian
  final bytes = List<int>.filled(maxBytes, 0);
  for (var i = 0; i < maxBytes; i++) {
    bytes[i] = (value >> (8 * (maxBytes - 1 - i))) & 0xFF;
  }
  return bytes;
}
