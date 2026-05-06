// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;

class TermsWebView extends StatefulWidget {
  final String htmlBase64;

  const TermsWebView({
    super.key,
    required this.htmlBase64,
  });

  @override
  State<TermsWebView> createState() => _TermsWebViewState();
}

class _TermsWebViewState extends State<TermsWebView> {
  late final String viewType;

  @override
  void initState() {
    super.initState();

    viewType = 'terms-html-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = 'data:text/html;base64,${widget.htmlBase64}'
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';

      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: viewType);
  }
}