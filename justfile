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
    rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android ## android setup
    rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim ## ios setup
    cargo install cargo-ndk
    cargo install cargo-xcode
    cargo install cargo-expand
    cargo install 'flutter_rust_bridge_codegen@^2.0.0-dev'
    cd rust && cargo update
