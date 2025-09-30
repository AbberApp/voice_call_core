abstract class Socket {


  final String? url;
  Map<String, dynamic>? queryParameters;
  Map<String, dynamic>? headers;

  Socket({required this.url, this.queryParameters, this.headers});

  Future<void> connect();

  void sendEvent(Map<String, dynamic> message);

  void onListenEvents(Function(dynamic) callback);

  void dispose();
}
