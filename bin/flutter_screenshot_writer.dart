import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';

bool verbose = false;
late Directory outputDir;

void main(List<String> argv) async {
  late int portNo;
  final argParser = ArgParser(allowTrailingOptions: false);
  argParser.addOption('port', abbr: 'p', defaultsTo: '3013', help: 'port to listen on');
  argParser.addOption('output_dir', abbr: 'o', defaultsTo: '${Directory.current.path}/screenshots', help: 'Output directory');
  argParser.addFlag('verbose', abbr: 'v', defaultsTo: true, help: 'verbose');
  final args = argParser.parse(argv);
  try {
    portNo = int.parse(args['port']);
    outputDir = Directory(args['output_dir']);
  } on FormatException catch (_) {
    stderr.write("${argParser.usage}\n");
    exit(1);
  }
  if (args.rest.isNotEmpty) {
    stderr.write("${argParser.usage}\n");
    exit(1);
  }
  verbose = args['verbose'];

  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, portNo);
  if (verbose) {
    print('Listening on port: $portNo, saving screenshots to: ${outputDir.path}');
  }
  server.listen((client) {
    handleConnection(client);
  });
}

void saveScreen(dynamic msg) async {
  String path = msg['path'];
  if (verbose) {
    print('Saving screen to: $path');
  }
  List<int> image = msg['image'].cast<int>();
  File f = File('$outputDir/$path');
  f.parent.createSync(recursive: true);
  f.writeAsBytesSync(image);
}

void handleConnection(Socket client) {
  var fullMessage = BytesBuilder();
  client.listen(
    (Uint8List data) async {
      fullMessage.add(data);
    },
    onError: (error) {
      if (verbose) print(error);
      client.close();
    },
    onDone: () {
      final stringData = String.fromCharCodes(fullMessage.toBytes());
      final msg = json.decode(stringData);
      saveScreen(msg);
      client.close();
    },
  );
}
