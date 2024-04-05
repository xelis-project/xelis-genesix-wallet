# XELIS Wallet

XELIS Wallet is a multiplatform cryptocurrency wallet built using the Flutter framework. It provides a convenient and secure way to manage your XELIS cryptocurrency assets on various platforms.

This wallet harnesses the power of Rust by incorporating a native Rust library from the XELIS blockchain, ensuring the same level of security as the XELIS Wallet CLI.

## Features

- Securely store and manage your XELIS tokens
- View your account balance and transaction history
- Send and receive XELIS tokens easily
- Support for multiple platforms, including:
  - iOS
  - Android
  - Windows
  - macOS
  - Linux

## Installation

Follow the steps below to install and run XELIS Wallet on your desired platform.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Rust tool chain](https://www.rust-lang.org/tools/install)
- [Just command runner](https://just.systems/)

### Clone the Repository

```
git clone https://github.com/xelis-project/xelis-mobile-wallet.git
```

### Build and Run

1. Navigate to the cloned repository:

```
cd xelis-mobile-wallet
```

2. Install the required dependencies and generate glue code :

```
just gen
```

3. Connect your device or emulator and run the application:
```
flutter run --release
```

4. Or, build the binary file:

```
flutter build --release
```

For platform-specific instructions and additional configuration steps, please refer to the documentation available by following the links provided.

## Contributing

We welcome contributions from the community! If you'd like to contribute to XELIS Wallet, please follow our [contribution guidelines](CONTRIBUTING.md) and submit a pull request.

## License

XELIS Wallet is open source and licensed under the [MIT License](LICENSE). Feel free to modify and distribute the application as per the terms of the license.

## Contact

For any questions or inquiries, please contact the XELIS team on [Discord](https://discord.gg/z543umPUdj).
