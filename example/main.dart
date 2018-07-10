import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:angel_wings/angel_wings.dart';
import 'package:file/local.dart';

main() async {
  for (int i = 1; i < Platform.numberOfProcessors; i++) {
    var onError = new ReceivePort();
    Isolate.spawn(isolateMain, i, onError: onError.sendPort);
    onError.listen((e) => Zone.current
        .handleUncaughtError(e[0], new StackTrace.fromString(e[1].toString())));
  }

  isolateMain(0);
}

void isolateMain(int id) {
  var app = new Angel();
  var wings = new AngelWings(app, shared: true, useZone: false);

  app.injectEncoders({'gzip': gzip.encoder, 'deflate': zlib.encoder});

  var old = app.errorHandler;
  app.errorHandler = (e, req, res) {
    print(e);
    print(e.stackTrace);
    return old(e, req, res);
  };

  app.get('/hello', 'Hello, native world! This is isolate #$id.');

  var fs = const LocalFileSystem();
  var vDir = new VirtualDirectory(app, fs, source: fs.directory('web'));
  app.use(vDir.handleRequest);

  wings.startServer('127.0.0.1', 3000).then((_) {
    print(
        'Instance #$id listening at http://${wings.address.address}:${wings.port}');
  });
}
