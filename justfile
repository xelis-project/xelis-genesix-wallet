default: gen lint

gen: gen_flutter
    flutter_rust_bridge_codegen generate

gen_flutter:
    flutter pub get
    dart run build_runner build

lint:
    cd rust && cargo fmt
    dart format .

clean:
    flutter clean
    cd rust && cargo clean
    
prep:
    cargo install 'flutter_rust_bridge_codegen@^2.0.0-dev'
    cd rust && cargo update
