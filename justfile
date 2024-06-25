default: gen lint

init: prep gen_rust_bridge flutter

gen: rust gen_rust_bridge flutter

gen_rust_bridge:
    flutter_rust_bridge_codegen generate

flutter:
    flutter pub get

lint:
    cd rust && cargo fmt
    dart format .

clean:
    flutter clean
    cd rust && cargo clean

rust:
    cd rust && cargo update

prep:
    cargo install 'flutter_rust_bridge_codegen@^2.0.0-dev'
    cd rust && cargo update

serve_web:
    flutter_rust_bridge_serve --crate rust --features="network_handler" --no-default-features