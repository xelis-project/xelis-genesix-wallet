import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

const _integrationTestPath = 'integration_test/xswd_web_relayer_test.dart';
const _controlDefine = 'GENESIX_XSWD_E2E_CONTROL';
const _reusedWebPackageEnvironment = 'GENESIX_XSWD_E2E_XWF_WEB_PKG';
const _applicationId =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _nativeAsset =
    '0000000000000000000000000000000000000000000000000000000000000000';
const _secondaryContract =
    'abababababababababababababababababababababababababababababababab';
const _canonicalAddress =
    'xel:qcd39a5u8cscztamjuyr7hdj6hh2wh9nrmhp86ljx2sz6t99ndjqqm7wxj8';
const _aboveJavaScriptSafeInteger = '9007199254740993';
const _wideNonce = '9007199254740995';
const _maximumUnsigned64 = '18446744073709551615';
const _requestIds = <String>{
  'partial-prefetch',
  'no-change-prefetch',
  'get-address',
  'subscribe',
  'unsubscribe',
  'reject-transfer',
  'approve-invoke',
  'approve-invoke-all',
  'approve-invoke-specific',
  'approve-invoke-exclude',
  'replace-session',
  'cancel-transfer',
  'malformed-transfer',
};

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    stdout.writeln(
      'Build the resolved XWF Web package and run the real Genesix XSWD '
      'relay-to-review-to-decision browser test. Start a compatible ChromeDriver '
      'on localhost:4444 first (or set CHROMEDRIVER_PORT). Set '
      '$_reusedWebPackageEnvironment to reuse a validated XWF Web package.',
    );
    return;
  }
  if (arguments.isNotEmpty) {
    stderr.writeln('Unknown arguments. Use --help for usage.');
    exitCode = 64;
    return;
  }

  final driverPort = int.tryParse(
    Platform.environment['CHROMEDRIVER_PORT'] ?? '4444',
  );
  if (driverPort == null || driverPort < 1 || driverPort > 65535) {
    throw ArgumentError('CHROMEDRIVER_PORT must be a valid TCP port.');
  }
  await _requireReadyDriver(driverPort);
  final chromeBinary = Platform.environment['CHROME_EXECUTABLE'];
  final fixture = await _XswdRelayFixture.start();
  try {
    await _prepareXwfWebPackage();
    final flutter = _flutterInvocation();
    await _runChecked(
      executable: flutter.executable,
      arguments: [
        ...flutter.prefixArguments,
        'drive',
        '--no-pub',
        '--driver=test_driver/integration_test.dart',
        '--target=$_integrationTestPath',
        '-d',
        'web-server',
        '--driver-port=$driverPort',
        '--browser-name=chrome',
        if (chromeBinary != null && chromeBinary.isNotEmpty)
          '--chrome-binary=$chromeBinary',
        '--headless',
        '--web-header=Cross-Origin-Opener-Policy=same-origin',
        '--web-header=Cross-Origin-Embedder-Policy=require-corp',
        '--dart-define=$_controlDefine=${fixture.controlOrigin}',
        '--dart-define=GENESIX_DIAGNOSTICS=false',
      ],
      failureCode: 'genesix_xswd_web_test_failed',
      timeout: const Duration(minutes: 15),
    );
    stdout.writeln(
      'GENESIX_XSWD_WEB_E2E_PASS '
      'partial_prefetch=true prefetched_request=true no_change_prefetch=true '
      'request_scope=true connection_scope=true subscriptions=true '
      'inter_contract_review=none,all,specific,exclude '
      'individual_transaction_callbacks=4 '
      'relay=true review=true approve=true reject=true app_close_reject=true '
      'session_replacement=true malformed_session_closed=true '
      'amount=$_aboveJavaScriptSafeInteger '
      'max_gas=$_aboveJavaScriptSafeInteger nonce=$_wideNonce '
      'fee=$_maximumUnsigned64',
    );
  } finally {
    await fixture.close();
  }
}

Future<void> _requireReadyDriver(int port) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final request = await client.getUrl(Uri.http('127.0.0.1:$port', '/status'));
    final response = await request.close().timeout(const Duration(seconds: 5));
    final body = await utf8.decoder
        .bind(response)
        .join()
        .timeout(const Duration(seconds: 5));
    final status = jsonDecode(body);
    if (response.statusCode != HttpStatus.ok ||
        status is! Map<String, dynamic> ||
        status['value'] is! Map<String, dynamic> ||
        (status['value'] as Map<String, dynamic>)['ready'] != true) {
      throw StateError('ChromeDriver is not ready.');
    }
  } finally {
    client.close(force: true);
  }
}

Future<List<String>> _resolvedWebBuildArguments() async {
  final library = await Isolate.resolvePackageUri(
    Uri.parse('package:xelis_wallet_flutter/xelis_wallet_flutter.dart'),
  );
  if (library == null || library.scheme != 'file') {
    throw StateError('The XWF package must be resolved before this test.');
  }
  final packageRoot = File.fromUri(library).parent.parent;
  final entrypoint = File.fromUri(
    packageRoot.uri.resolve('bin/build_web.dart'),
  );
  if (!entrypoint.existsSync()) {
    throw StateError('The resolved XWF Web build executable is missing.');
  }
  // Invoke the package's existing CLI directly. `dart run` would first build
  // the host Native Assets even though this test needs only the WASM target.
  // flutter drive hosts the application's web/ directory, including Rust WASM.
  return [
    '--packages=${File('.dart_tool/package_config.json').absolute.path}',
    entrypoint.path,
    '--output',
    Directory('web/pkg').absolute.path,
  ];
}

Future<void> _prepareXwfWebPackage() async {
  final reusedPackage = Platform.environment[_reusedWebPackageEnvironment];
  if (reusedPackage == null || reusedPackage.trim().isEmpty) {
    await _runChecked(
      executable: Platform.resolvedExecutable,
      arguments: await _resolvedWebBuildArguments(),
      failureCode: 'xwf_web_build_failed',
      timeout: const Duration(minutes: 90),
    );
    return;
  }

  final source = Directory(reusedPackage).absolute;
  final destination = Directory('web/pkg').absolute;
  _requireWebPackage(source);
  if (_samePath(source.path, destination.path)) return;

  if (destination.existsSync()) destination.deleteSync(recursive: true);
  destination.createSync(recursive: true);
  await for (final entity in source.list(recursive: true, followLinks: false)) {
    final relative = entity.path.substring(source.path.length + 1);
    final target = '${destination.path}${Platform.pathSeparator}$relative';
    if (entity is Directory) {
      Directory(target).createSync(recursive: true);
    } else if (entity is File) {
      File(target).parent.createSync(recursive: true);
      entity.copySync(target);
    } else {
      throw StateError('xwf_web_package_contains_link');
    }
  }
  _requireWebPackage(destination);
}

void _requireWebPackage(Directory directory) {
  if (!directory.existsSync() ||
      !File('${directory.path}/xelis_wallet_flutter.js').existsSync() ||
      !File('${directory.path}/xelis_wallet_flutter_bg.wasm').existsSync()) {
    throw StateError('xwf_web_package_invalid');
  }
}

bool _samePath(String left, String right) {
  if (Platform.isWindows) {
    return left.toLowerCase() == right.toLowerCase();
  }
  return left == right;
}

Future<void> _runChecked({
  required String executable,
  required List<String> arguments,
  required String failureCode,
  Duration timeout = const Duration(minutes: 10),
}) async {
  final process = await Process.start(
    executable,
    arguments,
    mode: ProcessStartMode.inheritStdio,
  );
  late final int result;
  try {
    result = await process.exitCode.timeout(timeout);
  } on TimeoutException {
    process.kill();
    throw StateError(failureCode);
  }
  if (result != 0) {
    throw StateError(failureCode);
  }
}

({String executable, List<String> prefixArguments}) _flutterInvocation() {
  final cacheDirectory = File(Platform.resolvedExecutable).parent.parent.parent;
  final flutterTools = File(
    '${cacheDirectory.path}${Platform.pathSeparator}flutter_tools.snapshot',
  );
  if (flutterTools.existsSync()) {
    return (
      executable: Platform.resolvedExecutable,
      prefixArguments: [flutterTools.path, '--no-version-check'],
    );
  }
  return (executable: 'flutter', prefixArguments: const []);
}

final class _XswdRelayFixture {
  _XswdRelayFixture._(this._server);

  final HttpServer _server;
  final Map<String, _SanitizedRpcResponse> _responses = {};
  WebSocket? _socket;
  bool _registered = false;
  bool _acceptConnections = true;
  String? _protocolFailure;

  static Future<_XswdRelayFixture> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixture = _XswdRelayFixture._(server);
    server.listen(fixture._handleRequest);
    return fixture;
  }

  String get controlOrigin =>
      'http://${_server.address.address}:${_server.port}';

  Future<void> close() async {
    _acceptConnections = false;
    await _socket?.close(WebSocketStatus.goingAway);
    await _server.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    _setCorsHeaders(request.response);
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    try {
      switch ((request.method, request.uri.path)) {
        case ('GET', '/relay'):
          await _acceptRelay(request);
        case ('GET', '/state'):
          await _writeState(request.response);
        case ('GET', '/send/partial-prefetch'):
          await _sendScenario(request.response, 'partial-prefetch');
        case ('GET', '/send/no-change-prefetch'):
          await _sendScenario(request.response, 'no-change-prefetch');
        case ('GET', '/send/get-address'):
          await _sendScenario(request.response, 'get-address');
        case ('GET', '/send/subscribe'):
          await _sendScenario(request.response, 'subscribe');
        case ('GET', '/send/unsubscribe'):
          await _sendScenario(request.response, 'unsubscribe');
        case ('GET', '/send/reject-transfer'):
          await _sendScenario(request.response, 'reject-transfer');
        case ('GET', '/send/approve-invoke'):
          await _sendScenario(request.response, 'approve-invoke');
        case ('GET', '/send/approve-invoke-all'):
          await _sendScenario(request.response, 'approve-invoke-all');
        case ('GET', '/send/approve-invoke-specific'):
          await _sendScenario(request.response, 'approve-invoke-specific');
        case ('GET', '/send/approve-invoke-exclude'):
          await _sendScenario(request.response, 'approve-invoke-exclude');
        case ('GET', '/send/replace-session'):
          await _sendScenario(request.response, 'replace-session');
        case ('GET', '/send/cancel-transfer'):
          await _sendScenario(request.response, 'cancel-transfer');
        case ('GET', '/send/malformed-transfer'):
          await _sendScenario(request.response, 'malformed-transfer');
        case ('GET', '/disconnect'):
          await _disconnect(request.response);
        default:
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
      }
    } catch (_) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {
        // The response may already belong to an upgraded WebSocket.
      }
    }
  }

  Future<void> _acceptRelay(HttpRequest request) async {
    if (!_acceptConnections || _socket != null) {
      request.response.statusCode = HttpStatus.conflict;
      await request.response.close();
      return;
    }
    final socket = await WebSocketTransformer.upgrade(request);
    _registered = false;
    _socket = socket;
    socket.listen(
      _handleRelayFrame,
      onError: _handleRelayError,
      onDone: () {
        if (identical(_socket, socket)) {
          _socket = null;
        }
      },
      cancelOnError: true,
    );
  }

  void _handleRelayFrame(dynamic frame) {
    try {
      final text = switch (frame) {
        String value => value,
        Uint8List value => utf8.decode(value),
        List<int> value => utf8.decode(value),
        _ => throw const FormatException('unsupported_frame'),
      };
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('invalid_rpc_root');
      }
      final id = decoded['id'];
      final result = decoded['result'];
      if (id == _applicationId &&
          result is Map<String, dynamic> &&
          result['success'] == true) {
        _registered = true;
        return;
      }
      if (id is! String || !_requestIds.contains(id)) {
        throw const FormatException('unexpected_rpc_id');
      }
      final error = decoded['error'];
      _responses[id] = _SanitizedRpcResponse(
        hasResult: decoded.containsKey('result'),
        hasError: error is Map<String, dynamic>,
        errorCode: error is Map<String, dynamic> ? error['code'] : null,
        errorKind: error is Map<String, dynamic> ? error['kind'] : null,
      );
    } catch (_) {
      _protocolFailure = 'invalid_relayer_frame';
    }
  }

  void _handleRelayError(Object _) {
    _protocolFailure = 'relayer_socket_error';
  }

  Future<void> _sendScenario(HttpResponse response, String id) async {
    final socket = _socket;
    if (!_registered || socket == null || socket.readyState != WebSocket.open) {
      response.statusCode = HttpStatus.conflict;
      await response.close();
      return;
    }
    final request = switch (id) {
      'partial-prefetch' || 'no-change-prefetch' => _prefetchRequest(id),
      'get-address' => _getAddressRequest(id),
      'subscribe' || 'unsubscribe' => _subscriptionRequest(id),
      final value when value.startsWith('approve-invoke') => _invokeRequest(id),
      'malformed-transfer' => _malformedTransferRequest(id),
      _ => _transferRequest(id),
    };
    socket.add(utf8.encode(request));
    response.statusCode = HttpStatus.accepted;
    await response.close();
  }

  Future<void> _disconnect(HttpResponse response) async {
    _acceptConnections = false;
    final socket = _socket;
    if (socket == null) {
      response.statusCode = HttpStatus.conflict;
      await response.close();
      return;
    }
    await socket.close(WebSocketStatus.goingAway);
    response.statusCode = HttpStatus.noContent;
    await response.close();
  }

  Future<void> _writeState(HttpResponse response) async {
    response.headers.contentType = ContentType.json;
    response.write(
      jsonEncode({
        'registered': _registered,
        'connected': _socket?.readyState == WebSocket.open,
        'settled_disconnected': _socket == null,
        if (_protocolFailure != null) 'failure': _protocolFailure,
        'responses': {
          for (final entry in _responses.entries)
            entry.key: entry.value.toJson(),
        },
      }),
    );
    await response.close();
  }
}

final class _SanitizedRpcResponse {
  const _SanitizedRpcResponse({
    required this.hasResult,
    required this.hasError,
    required this.errorCode,
    required this.errorKind,
  });

  final bool hasResult;
  final bool hasError;
  final Object? errorCode;
  final Object? errorKind;

  Map<String, Object?> toJson() => {
    'received': true,
    'has_result': hasResult,
    'has_error': hasError,
    if (errorCode is int || errorCode is String) 'error_code': errorCode,
    if (errorKind == 'PERMISSION_DENIED' || errorKind == 'NOT_ONLINE_MODE')
      'error_kind': errorKind,
  };
}

void _setCorsHeaders(HttpResponse response) {
  response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Methods', 'GET, OPTIONS')
    ..set('Access-Control-Allow-Headers', 'Content-Type')
    ..set(HttpHeaders.cacheControlHeader, 'no-store');
}

String _transferRequest(String id) =>
    '''{"jsonrpc":"2.0","id":"$id","method":"wallet.build_transaction","params":{"transfers":[{"asset":"$_nativeAsset","amount":$_aboveJavaScriptSafeInteger,"destination":"$_canonicalAddress","encrypt_extra_data":false}],"fee":{"fixed":$_maximumUnsigned64},"fee_limit":$_maximumUnsigned64,"nonce":$_wideNonce,"tx_version":0,"broadcast":false,"tx_as_hex":true}}''';

String _prefetchRequest(String id) {
  final permissions = id == 'partial-prefetch'
      ? '["get_address","subscribe","build_transaction"]'
      : '["build_transaction"]';
  return '''{"jsonrpc":"2.0","id":"$id","method":"xswd.prefetch_permissions","params":{"permissions":$permissions}}''';
}

String _subscriptionRequest(String method) =>
    '''{"jsonrpc":"2.0","id":"$method","method":"wallet.$method","params":{"notify":"balance_changed"}}''';

String _getAddressRequest(String id) =>
    '''{"jsonrpc":"2.0","id":"$id","method":"wallet.get_address"}''';

String _invokeRequest(String id) =>
    // The real fixture wallet is offline. Allow must reach build_transaction,
    // which deterministically returns NOT_ONLINE_MODE before any broadcast.
    '''{"jsonrpc":"2.0","id":"$id","method":"wallet.build_transaction","params":{"invoke_contract":{"contract":"$_nativeAsset","max_gas":$_aboveJavaScriptSafeInteger,"entry_id":7,"parameters":[],"deposits":{"$_nativeAsset":{"amount":$_aboveJavaScriptSafeInteger,"private":false}},"permission":${_invokePermission(id)}},"fee":{"fixed":$_maximumUnsigned64},"fee_limit":$_maximumUnsigned64,"nonce":$_wideNonce,"tx_version":0,"broadcast":true,"tx_as_hex":true}}''';

String _invokePermission(String id) => switch (id) {
  'approve-invoke' => '"none"',
  'approve-invoke-all' => '"all"',
  'approve-invoke-specific' =>
    '{"specific":[{"contract":"$_secondaryContract","chunk":{"specific":[7,65535]}}]}',
  'approve-invoke-exclude' =>
    '{"exclude":[{"contract":"$_secondaryContract","chunk":{"exclude":[7]}}]}',
  _ => throw ArgumentError.value(id, 'id', 'Unknown invoke scenario.'),
};

String _malformedTransferRequest(String id) =>
    '''{"jsonrpc":"2.0","id":"$id","method":"wallet.build_transaction","params":{"transfers":[],"unreviewed":true,"broadcast":false}}''';
