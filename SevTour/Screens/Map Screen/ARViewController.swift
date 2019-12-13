
import UIKit
import CoreLocation
import SceneKit
import Vision
import AVFoundation

class ARViewController: UIViewController {
    
    //Vision
    var request: VNCoreMLRequest!
    
    let yolo = YOLO()
    var boundingBoxes = [BoundingBox]()
    var colors: [UIColor] = []
    let semaphore = DispatchSemaphore(value: 2)
    let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml") // A Serial Queue
    
    let ALTITUDA: Double = -1
    
    
    

    @IBOutlet weak var sceneLocationView: SceneLocationView!
    
    var routeCoordinates = [CLLocationCoordinate2D]()
    var destinationPoint = CLLocationCoordinate2D()
    var orientedToTrueNorth = Bool()
    var mlState: Bool = false
    
    @IBOutlet weak var previewView: UIView!
    let adjustNorthByTappingSidesOfScreen = true
    
    @IBOutlet weak var mlButton: UIButton!
    
    
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var alertLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.isNavigationBarHidden = true
        
        //confugure sceneLocationView
        sceneLocationView.orientToTrueNorth = orientedToTrueNorth
        sceneLocationView.locationDelegate = self
        sceneLocationView.showFeaturePoints = false
        sceneLocationView.showAxesNode = false
        
        
        if orientedToTrueNorth {
            previewView.isHidden = true
            sceneLocationView.run()
            self.plotARRoute()
            self.setUpBoundingBoxes()
            self.setUpVision()
            loopCoreMLUpdate()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneLocationView.pause()
    }
    
    @IBAction func startBtnPressed(_ sender: Any) {
        previewView.isHidden = true
        sceneLocationView.run()
        self.plotARRoute()
        self.setUpBoundingBoxes()
        self.setUpVision()
        loopCoreMLUpdate()
    }
    
    @IBAction func mlButtonPressed(_ sender: Any) {
        if mlState {
            mlButton.backgroundColor = UIColor.lightGray
            mlState = false
            boundingBoxes[0].hide()
            boundingBoxes[1].hide()
        } else {
            mlButton.backgroundColor = UIColor.white
            mlState = true
            semaphore.signal()
            loopCoreMLUpdate()
        }
    }
    
    //MARK: - Draw AR route
    func plotARRoute() {
        //add destination point
        let coor = CLLocation(coordinate: destinationPoint, altitude: ALTITUDA)
        if let image = UIImage(named: "desPin") {
            let annotationNode = LocationAnnotationNode(location: coor, image: image)
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        }
        
        // Add an AR annotation for every coordinate in routeCoordinates
        for coordinate in routeCoordinates {
            // TODO: Change altitude so that it is not hard coded
            let nodeLocation = CLLocation(coordinate: coordinate, altitude: ALTITUDA)
            
            let locationAnnotation = LocationAnnotationNode(location: nodeLocation, image: UIImage(named: "checkPoint")!) //"checkPoint"
            locationAnnotation.scaleRelativeToDistance = true
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: locationAnnotation)
            
        }
        
        // Use Turf to find the total distance of the polyline
        let distance = Turf.distance(along: routeCoordinates)
        
        // Walk the route line and add a small AR node and map view annotation every metersPerNode
        for i in stride(from: 0, to: distance, by: 5) {
            // Use Turf to find the coordinate of each incremented distance along the polyline
            if let nextCoordinate = Turf.coordinate(at: i, fromStartOf: routeCoordinates) {
                if routeCoordinates.contains(nextCoordinate) {
                    print("SKIPPED")
                    continue
                }
                let interpolatedStepLocation = CLLocation(coordinate: nextCoordinate, altitude: ALTITUDA)
                
                // Add an AR node
                let locationAnnotation = LocationAnnotationNode(location: interpolatedStepLocation, image: UIImage(named: "point")!)
                locationAnnotation.scaleRelativeToDistance = true
                sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: locationAnnotation)
            }
        }
        
        
    }
    
    @IBAction func closeBtnPressed(_ sender: Any) {
        navigationController!.popViewController(animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let touch = touches.first {
            if touch.view != nil {
                let location = touch.location(in: self.view)
                print(location)
                if location.x <= 40 && adjustNorthByTappingSidesOfScreen {
                    print("left side of the screen")
                    sceneLocationView.moveSceneHeadingAntiClockwise()
                } else if location.x >= view.frame.size.width - 40 && adjustNorthByTappingSidesOfScreen {
                    print("right side of the screen")
                    sceneLocationView.moveSceneHeadingClockwise()
                }
            }
        }
    }
}

extension ARViewController {
    
    // MARK: - Setup
    func setUpBoundingBoxes() {
        for _ in 0..<YOLO.maxBoundingBoxes {
            boundingBoxes.append(BoundingBox())
        }
        
        for box in self.boundingBoxes {
            box.addToLayer(self.sceneLocationView.layer)
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
    
    // MARK: - Vision handler
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        // Measure how long it takes to predict a single video frame. Note that
        // predict() can be called on the next frame while the previous one is
        // still being processed. Hence the need to queue up the start times.
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let orientedCIImage = ciImage.oriented(.right)
        
        // Vision will automatically resize the input image.
        let handler = VNImageRequestHandler(ciImage: orientedCIImage)
        //let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
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
                
                if !mlState {return}
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
                
                //vibrate if red
                if color == UIColor.red {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
                
                //bydloCodeModeON
                /*countOfNothing = 0
                
                if color == UIColor.red {
                    countOfRed += 1
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                }
                if color == UIColor.green {
                    countOfGreen += 1
                }
                
                
                if countOfGreen >= 50 {
                    countOfRed = 0
                    alertView.isHidden = true
                    //alertView.backgroundColor = color
                    print("\(label)+++++++++++++++++++++++++++++++GREEN \(countOfGreen)")
                    //alertLabel.text = "GO"
                }
                
                if countOfRed >= 50 {
                    countOfGreen = 0
                    if color == UIColor.red {
                        alertView.isHidden = false
                        alertView.backgroundColor = color
                        print("\(label)--------------------------------RED \(countOfRed)")
                        alertLabel.text = "STOP"
                    } else {
                        alertView.isHidden = true
                    }
                }*/
                let alertRect = CGRect(x: (view.bounds.width - (view.bounds.width / 1.5)) / 2,
                                       y: view.bounds.height - ((view.bounds.width / 1.5) / 2 * 1.5),
                                       width: view.bounds.width / 1.5,
                                       height: (view.bounds.width / 1.5) / 2)
                
                boundingBoxes[i].showAlert(frame: alertRect, label: label, color: color)
                
                //boundingBoxes[i].show(frame: rect, label: label, color: color)
            } else {
                
                /*countOfNothing += 1
                
                if countOfNothing == 500 {
                    print("EMPTY \(countOfNothing)")
                    alertView.isHidden = true
                    countOfNothing = 0
                    countOfRed = 0
                    countOfGreen = 0
                }*/
                boundingBoxes[i].hide()
            }
        }
    }
    
    func loopCoreMLUpdate() {
        // Continuously run CoreML whenever it's ready. (Preventing 'hiccups' in Frame Rate)
        if mlState {
            dispatchQueueML.async {
                // 1. Run Update.
                self.updateCoreML()
                
                // 2. Loop this function.
                self.loopCoreMLUpdate()
            }
        }
        
    }
    
    func updateCoreML() {
        ///////////////////////////
        // Get Camera Image as RGB
        let pixbuff : CVPixelBuffer? = (sceneLocationView.session.currentFrame?.capturedImage)
        
        
        
        if let pixelBuffer = pixbuff {
            semaphore.wait()
            // For better throughput, perform the prediction on a background queue
            // instead of on the VideoCapture queue. We use the semaphore to block
            // the capture queue and drop frames when Core ML can't keep up.
            DispatchQueue.global().async {
                self.predictUsingVision(pixelBuffer: pixelBuffer)
            }
        }
        
    }

}



//MARK: - SceneLocationViewDelegate
extension ARViewController: SceneLocationViewDelegate {
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {}
    
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        print("sceneLocationViewDidRemoveSceneLocationEstimate")
    }
    
    func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
        print("sceneLocationViewDidConfirmLocationOfNode")
    }
    
    func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {
        print("sceneLocationViewDidSetupSceneNode")
    }
    
    func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {}
    

}
