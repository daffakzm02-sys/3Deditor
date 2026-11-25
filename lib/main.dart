import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: Editor()));
}

class Editor extends StatefulWidget {
  const Editor({super.key});
  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  late final WebViewController c;

  @override
  void initState() {
    super.initState();
    c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1B1D22))
      ..addJavaScriptChannel('App', onMessageReceived: (m) async {
        final d = jsonDecode(m.message);
        if (d['t'] == 'pick') {
          final r = await FilePicker.platform.pickFiles(withData: true);
          if (r == null || r.files.single.bytes == null) return;
          final f = r.files.single;
          c.runJavaScript(
              'loadFile(${jsonEncode(f.name)},"${base64Encode(f.bytes!)}")');
        } else if (d['t'] == 'save') {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/${d['name']}');
          await file.writeAsBytes(base64Decode(d['b64']));
          await Share.shareXFiles([XFile(file.path)]);
        }
      })
      ..loadFlutterAsset('assets/editor.html');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF1B1D22),
        body: SafeArea(child: WebViewWidget(controller: c)),
      );
}
