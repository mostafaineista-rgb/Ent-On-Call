/// Web-specific HTTP client that uses the browser's native fetch() API.
/// Google Apps Script redirects (302) are handled transparently by fetch(),
/// while XMLHttpRequest (used by the http package) blocks on cross-origin redirects.
library;

import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Generic fetch function for web that handles redirects and CORS correctly for Google Apps Script.
Future<String> webFetch({
  required String url,
  required String method,
  Map<String, String>? body,
  String? userAgent,
}) async {
  try {
    final web.Headers headers = web.Headers();
    
    if (userAgent != null) {
      headers.set('User-Agent', userAgent);
    }

    JSAny? jsBody;
    if (body != null) {
      final encodedBody = body.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      jsBody = encodedBody.toJS;
      headers.set('Content-Type', 'application/x-www-form-urlencoded');
    }

    final options = web.RequestInit(
      method: method,
      redirect: 'follow',
      headers: headers,
      body: jsBody,
      mode: 'cors',
      credentials: 'omit',
    );

    web.console.log('webFetch: $method $url'.toJS);
    
    final responsePromise = web.window.fetch(url.toJS, options);
    final response = await responsePromise.toDart;
    
    web.console.log('webFetch: status=${response.status} ok=${response.ok}'.toJS);

    final textPromise = response.text();
    final text = await textPromise.toDart;
    final String bodyText = text.toDart;
    
    if (bodyText.length < 500) {
      web.console.log('webFetch: body=$bodyText'.toJS);
    } else {
      web.console.log('webFetch: body length=${bodyText.length}'.toJS);
    }

    if (!response.ok) {
      throw Exception('Web fetch failed: ${response.status} ${response.statusText}');
    }

    return bodyText;
  } catch (e) {
    web.console.error('webFetch error: $e'.toJS);
    rethrow;
  }
}

/// Compatibility wrappers
Future<String> webFetchGet(String url, {String? userAgent}) => 
    webFetch(url: url, method: 'GET', userAgent: userAgent);
Future<String> webFetchPost(String url, Map<String, String> formData, {String? userAgent}) => 
    webFetch(url: url, method: 'POST', body: formData, userAgent: userAgent);
