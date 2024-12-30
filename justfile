update: flutter_get flutter_generate install_rust_bridge_codegen rust_update gen_rust_bridge lint

init: flutter_get flutter_generate install_rust_bridge_codegen gen_rust_bridge

gen: flutter_get flutter_generate gen_rust_bridge

watch_rust:
    flutter_rust_bridge_codegen generate --watch

watch_dart:
    flutter pub run build_runner watch --delete-conflicting-outputs

gen_rust_bridge:
    flutter_rust_bridge_codegen generate

flutter_get:
    flutter pub get

flutter_generate:
    dart run build_runner build

lint:
    cd rust && cargo fmt
    dart format .

clean:
    flutter clean
    cd rust && cargo clean

rust_update:
    cd rust && cargo update

install_rust_bridge_codegen:
    cargo install 'flutter_rust_bridge_codegen'

run_web:
    flutter_rust_bridge_codegen build-web --verbose --cargo-build-args --no-default-features --cargo-build-args --features="network_handler" --release
    flutter run -d chrome --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp