default: gen lint

init: prep gen_rust_bridge flutter_get

gen: rust_update gen_rust_bridge flutter_get

watch_rust:
    flutter_rust_bridge_codegen generate --watch

watch_dart:
    flutter pub run build_runner watch --delete-conflicting-outputs

gen_rust_bridge:
    flutter_rust_bridge_codegen generate

flutter_get:
    flutter pub get

lint:
    cd rust && cargo fmt
    dart format .

clean:
    flutter clean
    cd rust && cargo clean

rust_update:
    cd rust && cargo update

prep:
    cargo install 'flutter_rust_bridge_codegen'
    cd rust && cargo update

run_web:
    flutter_rust_bridge_codegen build-web --verbose --cargo-build-args --no-default-features --cargo-build-args --features="network_handler" --release
    flutter run -d chrome --web-header=Cross-Origin-Opener-Policy=same-origin --web-header=Cross-Origin-Embedder-Policy=require-corp