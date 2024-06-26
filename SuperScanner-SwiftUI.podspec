
Pod::Spec.new do |spec|
  spec.name         = "SuperScanner-SwiftUI"
  spec.version      = "1.0.0"
  spec.summary      = "A SwiftUI view for barcode scanning using AVFoundation and Vision frameworks."
  spec.description  = "SuperScanner-SwiftUI provides a customizable SwiftUI view for scanning barcodes using AVFoundation and Vision frameworks."
  spec.homepage     = "https://github.com/DanielPHP01/SuperScanner-SwiftUI"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Daniel Almazbekov" => "danielalmazbekov01@icloud.com" }
  spec.source       = { :git => "https://github.com/DanielPHP01/SuperScanner-SwiftUI.git", :tag => "1.0.0" }

  spec.ios.deployment_target = "13.0"

  spec.source_files = "Sources/**/*.{swift}"

  spec.frameworks = "UIKit", "AVFoundation", "Vision"
end
