import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class HtmlUtils {
  /// 將 HTML 文字轉換為純文字（移除所有標籤）
  static String htmlToPlainText(String htmlString) {
    if (htmlString.isEmpty) return '';
    
    try {
      final document = html_parser.parse(htmlString);
      return document.body?.text ?? '';
    } catch (e) {
      // 如果解析失敗，返回原始文字
      return htmlString;
    }
  }

  /// 將 HTML 文字轉換為 Flutter RichText Widget，支援超連結
  static Widget htmlToRichText(String htmlString, {
    TextStyle? defaultStyle,
    double? fontSize,
    Color? textColor,
    Color? linkColor,
  }) {
    if (htmlString.isEmpty) {
      return Text(
        '暫無描述',
        style: defaultStyle ?? TextStyle(
          fontSize: fontSize ?? 14,
          color: textColor ?? Colors.grey[600],
        ),
      );
    }
    
    try {
      final document = html_parser.parse(htmlString);
      final spans = <TextSpan>[];
      
      _parseNode(
        document.body!,
        spans,
        defaultStyle ?? TextStyle(
          fontSize: fontSize ?? 14,
          color: textColor ?? Colors.black87,
          height: 1.5,
        ),
        linkColor ?? Colors.blue,
      );
      
      return RichText(
        text: TextSpan(children: spans),
        softWrap: true,
      );
    } catch (e) {
      // 如果解析失敗，返回純文字
      return Text(
        htmlString,
        style: defaultStyle ?? TextStyle(
          fontSize: fontSize ?? 14,
          color: textColor ?? Colors.black87,
          height: 1.5,
        ),
      );
    }
  }

  static void _parseNode(
    html_dom.Node node,
    List<TextSpan> spans,
    TextStyle defaultStyle,
    Color linkColor,
  ) {
    if (node.nodeType == html_dom.Node.TEXT_NODE) {
      final text = node.text;
      if (text != null && text.trim().isNotEmpty) {
        spans.add(TextSpan(
          text: text,
          style: defaultStyle,
        ));
      }
    } else if (node.nodeType == html_dom.Node.ELEMENT_NODE) {
      final element = node as html_dom.Element;
      final tagName = element.localName?.toLowerCase();
      
      switch (tagName) {
        case 'a':
          final href = element.attributes['href'];
          if (href != null) {
            spans.add(TextSpan(
              text: element.text,
              style: defaultStyle.copyWith(
                color: linkColor,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _launchUrl(href),
            ));
          } else {
            _parseChildren(element, spans, defaultStyle, linkColor);
          }
          break;
          
        case 'b':
        case 'strong':
          _parseChildren(
            element,
            spans,
            defaultStyle.copyWith(fontWeight: FontWeight.bold),
            linkColor,
          );
          break;
          
        case 'i':
        case 'em':
          _parseChildren(
            element,
            spans,
            defaultStyle.copyWith(fontStyle: FontStyle.italic),
            linkColor,
          );
          break;
          
        case 'br':
          spans.add(TextSpan(text: '\n', style: defaultStyle));
          break;
          
        case 'p':
          _parseChildren(element, spans, defaultStyle, linkColor);
          spans.add(TextSpan(text: '\n\n', style: defaultStyle));
          break;
          
        case 'div':
          _parseChildren(element, spans, defaultStyle, linkColor);
          spans.add(TextSpan(text: '\n', style: defaultStyle));
          break;
          
        default:
          _parseChildren(element, spans, defaultStyle, linkColor);
          break;
      }
    }
  }

  static void _parseChildren(
    html_dom.Element element,
    List<TextSpan> spans,
    TextStyle defaultStyle,
    Color linkColor,
  ) {
    for (final child in element.nodes) {
      _parseNode(child, spans, defaultStyle, linkColor);
    }
  }

  static Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      print('無法開啟連結: $url, 錯誤: $e');
    }
  }
} 