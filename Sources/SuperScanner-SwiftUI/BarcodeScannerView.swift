import SwiftUI
import AVFoundation
import Vision

public struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding public var scannedCode: String?
    @Binding public var isShowingScanner: Bool?
    @Binding public var errorText: String?
    @Binding public var success: Bool?
    public var boxSize: CGSize = CGSize(width: 200, height: 200)
    public var boxPosition: CGPoint = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
    public var boxColor: UIColor = .clear
    public var boxLineWidth: CGFloat = 0
    public var boxFillColor: UIColor = UIColor.clear
    public var supportedBarcodeTypes: [VNBarcodeSymbology] = [.qr, .ean13, .code128]
    public var shouldVibrateOnSuccess: Bool = true
    public var outsideBoxAlpha: CGFloat = .zero
    public var scanInterval: TimeInterval = 1.0
    
    public init(scannedCode: Binding<String?>,
                isShowingScanner: Binding<Bool?>,
                errorText: Binding<String?>,
                success: Binding<Bool?>,
                boxSize: CGSize = CGSize(width: 200, height: 200),
                boxPosition: CGPoint = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2),
                boxColor: UIColor = .clear,
                boxLineWidth: CGFloat = 0,
                boxFillColor: UIColor = UIColor.clear,
                supportedBarcodeTypes: [VNBarcodeSymbology] = [.qr, .ean13, .code128],
                shouldVibrateOnSuccess: Bool = true,
                outsideBoxAlpha: CGFloat = .zero,
                scanInterval: TimeInterval = 1.0) {
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
    
    public func makeUIViewController(context: Context) -> UIViewController {
        let viewController = ScannerViewController()
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
    
    class ScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
        var captureSession: AVCaptureSession!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var centerBoxLayer: CAShapeLayer!
        var outsideBoxLayer: CAShapeLayer!
        var scannedCodeBinding: Binding<String?>?
        var isShowingScannerBinding: Binding<Bool?>?
        var errorTextBinding: Binding<String?>?
        var successBinding: Binding<Bool?>?
        var boxSize: CGSize = CGSize(width: 200, height: 200)
        var boxPosition: CGPoint = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        var boxColor: UIColor = .red
        var boxLineWidth: CGFloat = 2
        var boxFillColor: UIColor = UIColor.clear
        var supportedBarcodeTypes: [VNBarcodeSymbology] = [.qr, .ean13, .code128]
        var shouldVibrateOnSuccess: Bool = true
        var outsideBoxAlpha: CGFloat = 0.5
        var scanInterval: TimeInterval = 1.0
        var lastScanDate: Date = Date()
        
        override public func viewDidLoad() {
            super.viewDidLoad()
            
            captureSession = AVCaptureSession()
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                errorTextBinding?.wrappedValue = "Error accessing camera: Device not found."
                successBinding?.wrappedValue = false
                return
            }
            let videoInput: AVCaptureDeviceInput
            
            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                errorTextBinding?.wrappedValue = "Error accessing camera: \(error.localizedDescription)"
                successBinding?.wrappedValue = false
                return
            }
            
            if (captureSession.canAddInput(videoInput)) {
                captureSession.addInput(videoInput)
            } else {
                errorTextBinding?.wrappedValue = "Unable to add input to capture session"
                successBinding?.wrappedValue = false
                return
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            captureSession.addOutput(videoOutput)
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            setupCenterBox()
            setupOutsideBox()
            
            captureSession.startRunning()
        }
        
        func setupCenterBox() {
            let centerBox = CGRect(x: boxPosition.x - (boxSize.width / 2),
                                   y: boxPosition.y - (boxSize.height / 2),
                                   width: boxSize.width, height: boxSize.height)
            
            centerBoxLayer = CAShapeLayer()
            centerBoxLayer.path = UIBezierPath(rect: centerBox).cgPath
            centerBoxLayer.strokeColor = boxColor.cgColor
            centerBoxLayer.fillColor = boxFillColor.cgColor
            centerBoxLayer.lineWidth = boxLineWidth
            view.layer.addSublayer(centerBoxLayer)
        }
        
        func setupOutsideBox() {
            let fullRect = view.bounds
            let centerBox = CGRect(x: boxPosition.x - (boxSize.width / 2),
                                   y: boxPosition.y - (boxSize.height / 2),
                                   width: boxSize.width, height: boxSize.height)
            
            let path = UIBezierPath(rect: fullRect)
            let transparentPath = UIBezierPath(rect: centerBox).reversing()
            path.append(transparentPath)
            
            outsideBoxLayer = CAShapeLayer()
            outsideBoxLayer.path = path.cgPath
            outsideBoxLayer.fillColor = UIColor.black.withAlphaComponent(outsideBoxAlpha).cgColor
            view.layer.addSublayer(outsideBoxLayer)
        }
        
        public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            let currentDate = Date()
            if currentDate.timeIntervalSince(lastScanDate) < scanInterval {
                return
            }
            
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                errorTextBinding?.wrappedValue = "Error getting image buffer from sample buffer"
                successBinding?.wrappedValue = false
                return
            }
            
            let request = VNDetectBarcodesRequest { (request, error) in
                if let error = error {
                    self.errorTextBinding?.wrappedValue = "Barcode detection error: \(error.localizedDescription)"
                    self.successBinding?.wrappedValue = false
                    return
                }
                
                if let results = request.results as? [VNBarcodeObservation] {
                    for result in results {
                        if self.supportedBarcodeTypes.contains(result.symbology) {
                            DispatchQueue.main.async {
                                self.handleBarcodeObservation(result)
                            }
                        }
                    }
                } else {
                    self.errorTextBinding?.wrappedValue = "No barcode observations found"
                    self.successBinding?.wrappedValue = false
                }
            }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                errorTextBinding?.wrappedValue = "Failed to perform barcode request: \(error.localizedDescription)"
                successBinding?.wrappedValue = false
            }
        }
        
        func handleBarcodeObservation(_ observation: VNBarcodeObservation) {
            let barcodeBounds = previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
            
            let scanZoneRect = CGRect(x: boxPosition.x - boxSize.width / 2,
                                      y: boxPosition.y - boxSize.height / 2,
                                      width: boxSize.width,
                                      height: boxSize.height)
            
            if scanZoneRect.contains(barcodeBounds.origin) && scanZoneRect.contains(CGPoint(x: barcodeBounds.maxX, y: barcodeBounds.maxY)) {
                lastScanDate = Date()
                scannedCodeBinding?.wrappedValue = observation.payloadStringValue
                successBinding?.wrappedValue = true
                if shouldVibrateOnSuccess {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
                isShowingScannerBinding?.wrappedValue = false
                print(observation.payloadStringValue ?? "No barcode value")
            }
        }
        
        override public func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            captureSession.stopRunning()
        }
    }
}

