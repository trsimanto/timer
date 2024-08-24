import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as pathJoiner;
import 'package:url_launcher/url_launcher.dart';

Future<String?> takePhoto(
    CameraMacOSController? macOSController, BuildContext context) async {
  try {
    if (macOSController != null) {
      CameraMacOSFile? imageData = await macOSController.takePicture();
      if (imageData != null) {
        return await savePicture(imageData.bytes!, context);
      }
    }
  } catch (e) {
    showAlert(context, message: e.toString());
  }
  return null;
}

Future<String?> savePicture(Uint8List photoBytes, BuildContext context) async {
  try {
    String filename = await imageFilePath;
    File f = File(filename);
    if (f.existsSync()) {
      f.deleteSync(recursive: true);
    }
    f.createSync(recursive: true);
    f.writeAsBytesSync(photoBytes);
    return f.path;
  } catch (e) {
    showAlert(context, message: e.toString());
  }
  return null;
}

Future<String?> listVideoDevices(BuildContext context) async {
  try {
    List<CameraMacOSDevice> videoDevices =
        await CameraMacOS.instance.listDevices(
      deviceType: CameraMacOSDeviceType.video,
    );
    if (videoDevices.isNotEmpty) {
      return videoDevices.first.deviceId;
    }
  } catch (e) {
    showAlert(context, message: e.toString());
  }
  return null;
}

Future<void> showAlert(
  BuildContext context, {
  String title = "ERROR",
  String message = "",
}) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}

Future<String> get imageFilePath async => pathJoiner.join(
    (await getApplicationDocumentsDirectory()).path,
    "P_${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}_${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}.tiff");

Future<void> openPicture(String path) async {
  Uri uriPath = Uri.file(path);
  if (await canLaunchUrl(uriPath)) {
    await launchUrl(uriPath);
  }
}

CameraImageData argb2bitmap(CameraImageData content) {
  final Uint8List updated = Uint8List(content.bytes.length);
  for (int i = 0; i < updated.length; i += 4) {
    updated[i] = content.bytes[i + 1];
    updated[i + 1] = content.bytes[i + 2];
    updated[i + 2] = content.bytes[i + 3];
    updated[i + 3] = content.bytes[i];
  }

  const int headerSize = 122;
  final int contentSize = content.bytes.length;
  final int fileLength = contentSize + headerSize;

  final Uint8List headerIntList = Uint8List(fileLength);

  final ByteData bd = headerIntList.buffer.asByteData();
  bd.setUint8(0x0, 0x42);
  bd.setUint8(0x1, 0x4d);
  bd.setInt32(0x2, fileLength, Endian.little);
  bd.setInt32(0xa, headerSize, Endian.little);
  bd.setUint32(0xe, 108, Endian.little);
  bd.setUint32(0x12, content.width, Endian.little);
  bd.setUint32(0x16, -content.height, Endian.little); //-height
  bd.setUint16(0x1a, 1, Endian.little);
  bd.setUint32(0x1c, 32, Endian.little); // pixel size
  bd.setUint32(0x1e, 3, Endian.little); //BI_BITFIELDS
  bd.setUint32(0x22, contentSize, Endian.little);
  bd.setUint32(0x36, 0x000000ff, Endian.little);
  bd.setUint32(0x3a, 0x0000ff00, Endian.little);
  bd.setUint32(0x3e, 0x00ff0000, Endian.little);
  bd.setUint32(0x42, 0xff000000, Endian.little);

  headerIntList.setRange(
    headerSize,
    fileLength,
    updated,
  );

  return CameraImageData(
      bytes: headerIntList,
      width: content.width,
      height: content.height,
      bytesPerRow: content.bytesPerRow);
}

CameraImageData rgba2bitmap(CameraImageData content) {
  print(content.bytes.sublist(0, 4));
  const int headerSize = 122;
  final int contentSize = content.bytes.length;
  final int fileLength = contentSize + headerSize;

  final Uint8List headerIntList = Uint8List(fileLength);

  final ByteData bd = headerIntList.buffer.asByteData();
  bd.setUint8(0x0, 0x42);
  bd.setUint8(0x1, 0x4d);
  bd.setInt32(0x2, fileLength, Endian.little);
  bd.setInt32(0xa, headerSize, Endian.little);
  bd.setUint32(0xe, 108, Endian.little);
  bd.setUint32(0x12, content.width, Endian.little);
  bd.setUint32(0x16, -content.height, Endian.little); //-height
  bd.setUint16(0x1a, 1, Endian.little);
  bd.setUint32(0x1c, 32, Endian.little); // pixel size
  bd.setUint32(0x1e, 3, Endian.little); //BI_BITFIELDS
  bd.setUint32(0x22, contentSize, Endian.little);
  bd.setUint32(0x36, 0x000000ff, Endian.little);
  bd.setUint32(0x3a, 0x0000ff00, Endian.little);
  bd.setUint32(0x3e, 0x00ff0000, Endian.little);
  bd.setUint32(0x42, 0xff000000, Endian.little);

  headerIntList.setRange(
    headerSize,
    fileLength,
    content.bytes,
  );

  return CameraImageData(
      bytes: headerIntList,
      width: content.width,
      height: content.height,
      bytesPerRow: content.bytesPerRow);
}
