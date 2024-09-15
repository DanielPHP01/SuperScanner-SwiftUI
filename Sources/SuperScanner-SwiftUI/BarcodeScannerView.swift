import SwiftUI
import AVFoundation
import Vision

// Made by Daniel Almazbekov 2024
// Linkedin https://www.linkedin.com/in/almazbekov-daniel-mobiledeveloper/

// MARK: - BarcodeScannerView
/// A SwiftUI view that represents a barcode scanner using Vision and AVFoundation frameworks.
public struct BarcodeScannerView: UIViewControllerRepresentable {
    // MARK: - Bindings
    @Binding public var scannedCode: String?
    @Binding public var isShowingScanner: Bool?
    @Binding public var errorText: String?
    @Binding public var success: Bool?

    // MARK: - Configuration Properties
    public var boxSize: CGSize = CGSize(width: 200, height: 200)
    public var boxPosition: CGPoint = CGPoint(
        x: UIScreen.main.bounds.width / 2,
        y: UIScreen.main.bounds.height / 2
    )
    public var boxColor: UIColor = .clear
    public var boxLineWidth: CGFloat = 0
    public var boxFillColor: UIColor = UIColor.clear
    public var supportedBarcodeTypes: [VNBarcodeSymbology] = [.qr, .ean13, .code128]
    public var shouldVibrateOnSuccess: Bool = true
    public var outsideBoxAlpha: CGFloat = .zero
    public var scanInterval: TimeInterval = 1.0

    // MARK: - Initializer
    public init(
        scannedCode: Binding<String?>,
        isShowingScanner: Binding<Bool?>,
        errorText: Binding<String?>,
        success: Binding<Bool?>,
        boxSize: CGSize = CGSize(width: 200, height: 200),
        boxPosition: CGPoint = CGPoint(
            x: UIScreen.main.bounds.width / 2,
            y: UIScreen.main.bounds.height / 2
        ),
        boxColor: UIColor = .clear,
        boxLineWidth: CGFloat = 0,
        boxFillColor: UIColor = UIColor.clear,
        supportedBarcodeTypes: [VNBarcodeSymbology] = [.qr, .ean13, .code128],
        shouldVibrateOnSuccess: Bool = true,
        outsideBoxAlpha: CGFloat = .zero,
        scanInterval: TimeInterval = 1.0
    ) {
        self._scannedCode = scannedCode
        self._isShowingScanner = isShowingScanner
        self._errorText = errorText
        self._success = success
        self.boxSize = boxSize
        self.boxPosition = boxPosition
        self.boxColor = boxColor
        self.boxLineWidth = boxLineWidth
        self.boxFillColor = boxFillColor
        self.supportedBarcodeTypes = supportedBarcodeTypes
        self.shouldVibrateOnSuccess = shouldVibrateOnSuccess
        self.outsideBoxAlpha = outsideBoxAlpha
        self.scanInterval = scanInterval
    }

    // MARK: - UIViewControllerRepresentable Methods
    public func makeUIViewController(context: Context) -> UIViewController {
        let viewController = ScannerViewController()
        // Passing bindings and configurations to the view controller
        viewController.scannedCodeBinding = $scannedCode
        viewController.isShowingScannerBinding = $isShowingScanner
        viewController.errorTextBinding = $errorText
        viewController.successBinding = $success
        viewController.boxSize = boxSize
        viewController.boxPosition = boxPosition
        viewController.boxColor = boxColor
        viewController.boxLineWidth = boxLineWidth
        viewController.boxFillColor = boxFillColor
        viewController.supportedBarcodeTypes = supportedBarcodeTypes
        viewController.shouldVibrateOnSuccess = shouldVibrateOnSuccess
        viewController.outsideBoxAlpha = outsideBoxAlpha
        viewController.scanInterval = scanInterval
        return viewController
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    // MARK: - ScannerViewController
    /// A UIViewController that handles barcode scanning using AVFoundation and Vision.
    class ScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
        // MARK: - Properties
        var captureSession: AVCaptureSession!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var centerBoxLayer: CAShapeLayer!
        var outsideBoxLayer: CAShapeLayer!
        var scannedCodeBinding: Binding<String?>?
        var isShowingScannerBinding: Binding<Bool?>?
        var errorTextBinding: Binding<String?>?
        var successBinding: Binding<Bool?>?
        var boxSize: CGSize = CGSize(width: 200, height: 200)
        var boxPosition: CGPoint = CGPoint(
            x: UIScreen.main.bounds.width / 2,
            y: UIScreen.main.bounds.height / 2
        )
        var boxColor: UIColor = .red
        var boxLineWidth: CGFloat = 2
        var boxFillColor: UIColor = UIColor.clear
        var supportedBarcodeTypes: [VNBarcodeSymbology] = [.qr, .ean13, .code128]
        var shouldVibrateOnSuccess: Bool = true
        var outsideBoxAlpha: CGFloat = 0.5
        var scanInterval: TimeInterval = 1.0
        var lastScanDate: Date = Date()
        var isSessionRunning = false

        // MARK: - Lifecycle Methods
        override public func viewDidLoad() {
            super.viewDidLoad()
            setupCaptureSession()
            setupPreviewLayer()
            setupCenterBox()
            setupOutsideBox()
            addObservers()
        }

        override public func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            startSession()
        }

        override public func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            stopSession()
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        // MARK: - Setup Methods
        /// Configures the capture session.
        func setupCaptureSession() {
            captureSession = AVCaptureSession()
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                errorTextBinding?.wrappedValue = "Error accessing camera: device not found."
                successBinding?.wrappedValue = false
                return
            }

            do {
                let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                if captureSession.canAddInput(videoInput) {
                    captureSession.addInput(videoInput)
                } else {
                    errorTextBinding?.wrappedValue = "Unable to add input to capture session"
                    successBinding?.wrappedValue = false
                    return
                }
            } catch {
                errorTextBinding?.wrappedValue = "Error accessing camera: \(error.localizedDescription)"
                successBinding?.wrappedValue = false
                return
            }

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            } else {
                errorTextBinding?.wrappedValue = "Unable to add output to capture session"
                successBinding?.wrappedValue = false
                return
            }
        }

        /// Sets up the preview layer to display the camera feed.
        func setupPreviewLayer() {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.insertSublayer(previewLayer, at: 0)
        }

        /// Draws the center scanning box.
        func setupCenterBox() {
            let centerBox = CGRect(
                x: boxPosition.x - (boxSize.width / 2),
                y: boxPosition.y - (boxSize.height / 2),
                width: boxSize.width,
                height: boxSize.height
            )

            centerBoxLayer = CAShapeLayer()
            centerBoxLayer.path = UIBezierPath(rect: centerBox).cgPath
            centerBoxLayer.strokeColor = boxColor.cgColor
            centerBoxLayer.fillColor = boxFillColor.cgColor
            centerBoxLayer.lineWidth = boxLineWidth
            view.layer.addSublayer(centerBoxLayer)
        }

        /// Shades the area outside the center box.
        func setupOutsideBox() {
            let fullRect = view.bounds
            let centerBox = CGRect(
                x: boxPosition.x - (boxSize.width / 2),
                y: boxPosition.y - (boxSize.height / 2),
                width: boxSize.width,
                height: boxSize.height
            )

            let path = UIBezierPath(rect: fullRect)
            let transparentPath = UIBezierPath(rect: centerBox).reversing()
            path.append(transparentPath)

            outsideBoxLayer = CAShapeLayer()
            outsideBoxLayer.path = path.cgPath
            outsideBoxLayer.fillColor = UIColor.black.withAlphaComponent(outsideBoxAlpha).cgColor
            view.layer.addSublayer(outsideBoxLayer)
        }

        /// Adds observers for app lifecycle events.
        func addObservers() {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appWillEnterForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
        }

        // MARK: - Session Control Methods
        /// Starts the capture session.
        func startSession() {
            if !captureSession.isRunning && !isSessionRunning {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.startRunning()
                    self.isSessionRunning = true
                }
            }
        }

        /// Stops the capture session.
        func stopSession() {
            if captureSession.isRunning && isSessionRunning {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.stopRunning()
                    self.isSessionRunning = false
                }
            }
        }

        // MARK: - App Lifecycle Handlers
        @objc func appDidEnterBackground() {
            stopSession()
        }

        @objc func appWillEnterForeground() {
            if isViewLoaded && view.window != nil {
                startSession()
            }
        }

        // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
        /// Processes the captured video frames.
        public func captureOutput(
            _ output: AVCaptureOutput,
            didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            let currentDate = Date()
            // Throttle scanning to prevent excessive processing.
            if currentDate.timeIntervalSince(lastScanDate) < scanInterval {
                return
            }

            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                errorTextBinding?.wrappedValue = "Error getting image from buffer"
                successBinding?.wrappedValue = false
                return
            }

            let request = VNDetectBarcodesRequest { (request, error) in
                if let error = error {
                    self.errorTextBinding?.wrappedValue = "Barcode detection error: \(error.localizedDescription)"
                    self.successBinding?.wrappedValue = false
                    return
                }

                if let results = request.results as? [VNBarcodeObservation], !results.isEmpty {
                    for result in results {
                        if self.supportedBarcodeTypes.contains(result.symbology) {
                            DispatchQueue.main.async {
                                self.handleBarcodeObservation(result)
                            }
                            break // Stop after handling the first supported barcode.
                        }
                    }
                }
            }

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                errorTextBinding?.wrappedValue = "Failed to perform recognition request: \(error.localizedDescription)"
                successBinding?.wrappedValue = false
            }
        }

        // MARK: - Barcode Handling
        /// Handles the barcode observation result.
        func handleBarcodeObservation(_ observation: VNBarcodeObservation) {
            guard let payload = observation.payloadStringValue else {
                errorTextBinding?.wrappedValue = "Barcode does not contain data"
                successBinding?.wrappedValue = false
                return
            }

            let barcodeBounds = previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
            let scanZoneRect = CGRect(
                x: boxPosition.x - boxSize.width / 2,
                y: boxPosition.y - boxSize.height / 2,
                width: boxSize.width,
                height: boxSize.height
            )

            if scanZoneRect.contains(barcodeBounds.origin) &&
                scanZoneRect.contains(CGPoint(x: barcodeBounds.maxX, y: barcodeBounds.maxY)) {
                lastScanDate = Date()
                scannedCodeBinding?.wrappedValue = payload
                successBinding?.wrappedValue = true
                if shouldVibrateOnSuccess {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
                isShowingScannerBinding?.wrappedValue = false
            }
        }
    }
}
