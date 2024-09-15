
# SuperScanner-SwiftUI


![SuperScanner-SwiftUI Logo](https://raw.githubusercontent.com/DanielPHP01/SuperScanner-SwiftUI/main/image.webp)



**Made by Daniel Almazbekov**

## Description

SuperScanner-SwiftUI is a customizable SwiftUI component for scanning barcodes and QR codes using the AVFoundation and Vision frameworks. It allows you to easily integrate scanning functionality into your app with minimal effort.

## Features

- Supports various barcode types: QR, EAN-13, Code128, and more.
- Customizable scanning area: Adjust the size and position of the scanning window.
- Vibration on successful scan: Optionally enables device vibration upon code detection.
- Automatic session management: The scanning session automatically pauses during transitions or when alerts are displayed and resumes upon returning.
- Easy integration: Add to your project effortlessly using CocoaPods or Swift Package Manager.
- Built entirely in SwiftUI: Ideal for modern SwiftUI applications.

## Installation

### CocoaPods

Add the following line to your Podfile:

```ruby
pod 'SuperScanner-SwiftUI', '~> 1.1.0'
```

Then run:

```bash
pod install
```

### Swift Package Manager

1. In Xcode, go to **File > Swift Packages > Add Package Dependency**.
2. Enter the repository URL:

   ```
   https://github.com/DanielPHP01/SuperScanner-SwiftUI.git
   ```

3. Choose version **1.1.0** or later.

## Usage

```swift
import SwiftUI
import SuperScanner_SwiftUI

struct ContentView: View {
    @State private var scannedCode: String?
    @State private var isShowingScanner: Bool = false
    @State private var errorText: String?
    @State private var success: Bool = false

    var body: some View {
        VStack {
            if let code = scannedCode {
                Text("Scanned Code: \(code)")
                    .padding()
            }

            Button(action: {
                isShowingScanner = true
            }) {
                Text("Scan Barcode")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .sheet(isPresented: $isShowingScanner) {
                BarcodeScannerView(
                    scannedCode: $scannedCode,
                    isShowingScanner: $isShowingScanner,
                    errorText: $errorText,
                    success: $success,
                    boxSize: CGSize(width: 250, height: 250),
                    boxColor: .green,
                    boxLineWidth: 4,
                    shouldVibrateOnSuccess: true
                )
            }

            if let error = errorText {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
}
```

## Customization

**BarcodeScannerView** supports various parameters for customization:

| Parameter                | Type                   | Description                                                              |
|--------------------------|------------------------|--------------------------------------------------------------------------|
| `boxSize`                | `CGSize`               | Size of the scanning area.                                               |
| `boxPosition`            | `CGPoint`              | Position of the scanning area on the screen.                             |
| `boxColor`               | `UIColor`              | Color of the scanning area’s border.                                     |
| `boxLineWidth`           | `CGFloat`              | Width of the border line.                                                |
| `boxFillColor`           | `UIColor`              | Fill color of the scanning area.                                         |
| `supportedBarcodeTypes`  | `[VNBarcodeSymbology]` | An array of supported barcode types.                                     |
| `shouldVibrateOnSuccess` | `Bool`                 | Enable vibration on successful scan.                                     |
| `outsideBoxAlpha`        | `CGFloat`              | Transparency of the shaded area outside the scanning zone.               |
| `scanInterval`           | `TimeInterval`         | Interval between scans to prevent multiple triggers.                     |

## Requirements

- iOS 13.0 or later
- Swift 5.3 or later

## License

SuperScanner-SwiftUI is distributed under the MIT License. See the LICENSE file for more information.

## Author

**Daniel Almazbekov**

- Email: [danielalmazbekov01@icloud.com](mailto:danielalmazbekov01@icloud.com)
- GitHub: [DanielPHP01](https://github.com/DanielPHP01)

## Contributions

Any suggestions and improvements are welcome! Please create an issue or submit a pull request to the repository.
