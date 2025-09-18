import 'dart:html' as html;

class HtmlHelper {
  void open(String url, String target) {
    html.window.open(url, target);
  }
}