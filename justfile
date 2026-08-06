set windows-shell := ["cmd.exe", "/d", "/c"]

update: flutter_get gen_flutter format

init: flutter_get gen_flutter

gen: flutter_get gen_flutter

watch_dart:
    flutter pub run build_runner watch

flutter_get:
    flutter pub get

gen_flutter:
    dart run build_runner build -d

format:
    dart format lib test integration_test tool

clean:
    flutter clean

gen_arb:
    cd lib/l10n && python ./scripts/csv_to_arb.py
    flutter pub get
    cd ../..

sync_forui_docs:
    dart run tool/sync_forui_docs.dart

validate_news_feed:
    dart run tool/validate_news_feed.dart

### Web build and run commands ###

build_wallet_web:
    dart run xelis_wallet_flutter:build_web --output web/pkg

run_web: build_wallet_web
    flutter run -d chrome --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp
