default: gen lint

gen: gen_flutter
    flutter_rust_bridge_codegen

gen_flutter:
    flutter pub get
    dart run build_runner build

lint:
    cd native && cargo fmt
    dart format .

clean:
    flutter clean
    cd native && cargo clean
    
serve *args='':
    flutter pub run flutter_rust_bridge:serve {{args}}