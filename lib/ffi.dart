import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:xelis_wallet_app/bridge_definitions.dart';
import 'package:xelis_wallet_app/bridge_generated.dart';

export 'package:xelis_wallet_app/bridge_definitions.dart';
export 'package:xelis_wallet_app/bridge_generated.dart';

const base = 'rust';
final path = Platform.isWindows ? '$base.dll' : 'lib$base.so';
final dylib = loadDylib(path);
final Rust api = RustImpl(dylib);
