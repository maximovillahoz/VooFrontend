import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'terms_web_view.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
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
        ..loadFlutterAsset('assets/voo_terminos_condiciones.html');
    }
  }

  Future<void> _loadHtmlForWeb() async {
    final html = await rootBundle.loadString(
      'assets/voo_terminos_condiciones.html',
    );

    if (!mounted) return;

    setState(() {
      _html = html;
    });
  }

  void _acceptTerms() {
    Navigator.pop(context, true);
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
          'Términos y condiciones',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: kIsWeb
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
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: GestureDetector(
                onTap: _acceptTerms,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4B175E),
                        Color(0xFF2A083D),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: const Color(0xFF7E2BE8),
                      width: 2.2,
                    ),
                  ),
                  child: const Text(
                    'Aceptar términos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}