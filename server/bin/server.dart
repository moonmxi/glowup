import 'dart:io';

import 'package:glowup_server/api.dart';
import 'package:glowup_server/auth.dart';
import 'package:glowup_server/data_store.dart';

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args.first) ?? 3000 : 3000;
  final root = Directory.current;
  final store = DataStore(root: root);
  await store.init();
  final authManager = AuthManager(store);
  final api = ApiServer(store: store, authManager: authManager);

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('GlowUp local server listening on http://${server.address.address}:$port');

  await for (final request in server) {
    await api.handle(request);
  }
}
