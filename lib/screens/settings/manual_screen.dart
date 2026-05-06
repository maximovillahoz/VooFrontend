import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../shared_flow/terms_web_view.dart';

class ManualScreen extends StatefulWidget {
  const ManualScreen({super.key});

  @override
  State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  WebViewController? _controller;
  String? _html;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _loadHtmlForWeb();
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadFlutterAsset('assets/voo_manual.html');
    }
  }

  Future<void> _loadHtmlForWeb() async {
    final html = await rootBundle.loadString('assets/voo_manual.html');

    if (!mounted) return;

    setState(() {
      _html = html;
    });
  }

  @override
  Widget build(BuildContext context) {
    final webHtml = _html;

    return Scaffold(
      backgroundColor: const Color(0xFF05051C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05051C),
        elevation: 0,
        title: const Text(
          'Manual de uso',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: kIsWeb
          ? webHtml == null
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFB15CFF),
                  ),
                )
              : TermsWebView(
                  htmlBase64: base64Encode(
                    const Utf8Encoder().convert(webHtml),
                  ),
                )
          : WebViewWidget(controller: _controller!),
    );
  }
}