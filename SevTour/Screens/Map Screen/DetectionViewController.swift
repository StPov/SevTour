
import UIKit
import Vision
import AVFoundation

class DetectionViewController: UIViewController {

    
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var zoomInBtn: UIButton!
    @IBOutlet weak var zoomOutBtn: UIButton!
    
    @IBOutlet weak var videoPreview: UIView!
    
    var videoCapture: VideoCapture!
    var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    
    //Vision
    var request: VNCoreMLRequest!
    
    let yolo = YOLO()
    var boundingBoxes = [BoundingBox]()
    var colors: [UIColor] = []
    let semaphore = DispatchSemaphore(value: 2)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        self.setUpBoundingBoxes()
        self.setUpVision()
        self.setUpCamera()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.videoCapture.stop()
    }
    
    @objc func willEnterForeground() {
        print("willEnterForeground")
    }
    
    @objc func didBecomeActive() {
        print("didBecomeActive")
        self.videoCapture.start()
    }
    
    @objc func didEnterBackground() {
        print("didEnterBackground")
        self.videoCapture.stop()
    }
    
    func dismissController() {
        self.dismiss(animated: true) {
            NotificationCenter.default.removeObserver(self)
            print("dismiss")
        }
    }
    
    @IBAction func closeBtnPressed(_ sender: Any) {
        self.dismissController()
    }
    
    @IBAction func zoomInPtnPressed(_ sender: Any) {
        self.videoCapture.zoomIn()
    }
    
    @IBAction func zoomOutBtnPressed(_ sender: Any) {
        self.videoCapture.zoomOut()
    }
    
    @IBAction func panGestureHandler(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: self.view?.window)
        
        if sender.state == UIGestureRecognizer.State.began {
            self.initialTouchPoint = touchPoint
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.y - self.initialTouchPoint.y > 0 {
                self.view.frame = CGRect(x: 0, y: touchPoint.y - self.initialTouchPoint.y, width: self.view.frame.size.width, height: self.view.frame.size.height)
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            if touchPoint.y - self.initialTouchPoint.y > 100 {
                self.dismissController()
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                })
            }
        }
    }
    
    
    
    // MARK: - Setup
    func setUpBoundingBoxes() {
        for _ in 0..<YOLO.maxBoundingBoxes {
            boundingBoxes.append(BoundingBox())
        }
        
        // Make colors for the bounding boxes. There is one color for each class,
        // 20 classes in total.
        colors.append(.red)
        colors.append(.green)
    }
    
    func setUpVision() {
        
        //import CoreML model
        guard let selectedModel = try? VNCoreMLModel(for: AmpelPilot_2812rg().model) else {
            fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project from https://developer.apple.com/machine-learning/ . Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
        }
        
        self.request = VNCoreMLRequest(model: selectedModel, completionHandler: visionRequestDidComplete)
        self.request.imageCropAndScaleOption = VNImageCropAndScaleOption.scaleFill
    }
    
    func setUpCamera() {
        videoCapture = nil
        
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 15
        
        videoCapture.setUp(sessionPreset: AVCaptureSession.Preset.hd1920x1080) { success in
            if success {
                
                // Add the video preview into the UI.
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // Add the bounding box layers to the UI, on top of the video preview.
                for box in self.boundingBoxes {
                    box.addToLayer(self.videoPreview.layer)
                }
                
                // Once everything is set up, we can start capturing live video.
                self.videoCapture.start()
            }
        }
    }
    
    func resizePreviewLayer() {
        self.videoCapture.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill;
        self.videoCapture.previewLayer?.frame = videoPreview.bounds
        self.videoPreview.bringSubviewToFront(self.closeBtn)
        self.videoPreview.bringSubviewToFront(self.zoomInBtn)
        self.videoPreview.bringSubviewToFront(self.zoomOutBtn)
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Vision handler
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        // Measure how long it takes to predict a single video frame. Note that
        // predict() can be called on the next frame while the previous one is
        // still being processed. Hence the need to queue up the start times.
        
        // Vision will automatically resize the input image.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            
            let features = observations.first?.featureValue.multiArrayValue {
            let boundingBoxes = yolo.computeBoundingBoxes(features: features)
            self.showOnMainThread(boundingBoxes)
        }
    }
    
    func showOnMainThread(_ boundingBoxes: [YOLO.Prediction]) {
        DispatchQueue.main.async {
            self.show(predictions: boundingBoxes)
            self.semaphore.signal()
        }
    }
    
    func show(predictions: [YOLO.Prediction]) {
        for i in 0..<boundingBoxes.count {
            if i < predictions.count {
                let prediction = predictions[i]
                
                // The predicted bounding box is in the coordinate space of the input
                // image, which is a square image of 416x416 pixels. We want to show it
                // on the video preview, which is as wide as the screen and has a 4:3
                // aspect ratio. The video preview also may be letterboxed at the top
                // and bottom.
                let width = view.bounds.width
                let height = width * 16 / 9
                let scaleX = width / CGFloat(YOLO.inputWidth)
                let scaleY = height / CGFloat(YOLO.inputHeight)
                let top = (view.bounds.height - height) / 2
                
                // Translate and scale the rectangle to our own coordinate system.
                var rect = prediction.rect
                rect.origin.x *= scaleX
                rect.origin.y *= scaleY
                rect.origin.y += top
                rect.size.width *= scaleX
                rect.size.height *= scaleY
                
                // Show the bounding box.
                let label = String(format: "%@ %.1f", labels[prediction.classIndex], prediction.score * 100)
                let color = colors[prediction.classIndex]
                boundingBoxes[i].show(frame: rect, label: label, color: color)
            } else {
                boundingBoxes[i].hide()
            }
        }
    }

}


// MARK: - VideoCaptureDelegate
extension DetectionViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?) {
        
        semaphore.wait()
        
        if let pixelBuffer = pixelBuffer {
            // For better throughput, perform the prediction on a background queue
            // instead of on the VideoCapture queue. We use the semaphore to block
            // the capture queue and drop frames when Core ML can't keep up.
            DispatchQueue.global().async {
                self.predictUsingVision(pixelBuffer: pixelBuffer)
            }
        }
    }
    
    func videoCaptureDidStart(_ capture: VideoCapture) {}
    
    func videoCaptureDidStop(_ capture: VideoCapture) {}
}

