//
//  ViewController.swift
//  indoor navigation a
//
//  Created by Исмагил Сайфутдинов on 01/02/2019.
//  Copyright © 2019 Исмагил Сайфутдинов. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth
import Firebase

var allRooms = [Rooms]()
var allFloors = [Floors]()
var allVertexes = [Vertex]()
var allEdges = [Edge]()
var getDataBeacons = [Beacons]()

private var graph: Graph = Graph(edgesList: allEdges, vertexesList: allVertexes)

class ViewController: UIViewController, CLLocationManagerDelegate, FinderInsideDelegate {
    @IBOutlet weak var leadingS: NSLayoutConstraint!
    @IBOutlet weak var trailingS: NSLayoutConstraint!
    @IBOutlet var leadingC: NSLayoutConstraint!
    @IBOutlet var trailingC: NSLayoutConstraint!
    
    var hamburgerMenuIsVisible = false
    @IBAction func hamburgerBtnTapped(_ sender: Any) {
        //if the hamburger menu is NOT visible, then move the ubeView back to where it used to be
        if !hamburgerMenuIsVisible {
            leadingC.constant = 300
            //this constant is NEGATIVE because we are moving it 150 points OUTWARD and that means -150
            trailingC.constant = -300
            leadingS.constant = 300
            //this constant is NEGATIVE because we are moving it 150 points OUTWARD and that means -150
            trailingS.constant = -300
            
            //1
            hamburgerMenuIsVisible = true
        } else {
            //if the hamburger menu IS visible, then move the ubeView back to its original position
            leadingC.constant = 0
            trailingC.constant = 0
            leadingS.constant = 0
            trailingS.constant = 0
            
            //2
            hamburgerMenuIsVisible = false
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }) { (animationComplete) in
            print("The animation is complete!")
        }
    }

    
    @IBOutlet weak var mapView: MapView! {
        didSet {
            let pinch = UIPinchGestureRecognizer(target: mapView, action: #selector(MapView.adjustMapScale(byHandlingGestureRecognizer:)))
            mapView.addGestureRecognizer(pinch)
            
            let pan = UIPanGestureRecognizer(target: mapView, action: #selector(MapView.adjustMapOffset(byHandlingGestureRecognizer:)))
            mapView.isUserInteractionEnabled = true
            mapView.addGestureRecognizer(pan)
            
            let tap = UITapGestureRecognizer(target: mapView, action: #selector(MapView.getTappedRectangle(UsingHandlingGestureRecognizer:)))
            mapView.addGestureRecognizer(tap)
        }
    }
    @IBAction func floorStepper(_ sender: UIStepper) {
        mapView.currentFloor = allFloors[Int(sender.value)]
        currentFloorLabel.text = "Этаж: \(Int(sender.value) + 1)"
    }
    
    @IBOutlet weak var currentFloorLabel: UILabel!
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        self.mapView.updateMapView += 1
    }
    
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hse = WriteBase()
        
        FirebaseApp.configure()
        hse.readRoom()
        DispatchQueue.global(qos: .background).async { //асинхронное выполнение
            sleep(2)
            hse.saving()
            allVertexes = Vertex.allitems()
            allEdges = Edge.allitems()
            allRooms = Rooms.allitems()
            allFloors = Floors.allitems()
            getDataBeacons = Beacons.allitems()
            allFloors = allFloors.sorted(by: { $0.name ?? "kek" < $1.name ?? "kek" })
        }
        
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(sender:)))
        // the default direction is right
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(sender:)))
        leftSwipe.direction = .left
        
        
        view.addGestureRecognizer(rightSwipe)
        view.addGestureRecognizer(leftSwipe)

        locationManager.delegate = self
        
        if (CLLocationManager.authorizationStatus() != CLAuthorizationStatus.authorizedWhenInUse) {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    startScanning()
                }
            }
        }
    }
    
    func startScanning() {
        let uuid = UUID(uuidString: "10F86430-1346-11E4-9191-0800200C9A66")!
        
        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "brf0")
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0, getDataBeacons.count > 0, beacons.count <= getDataBeacons.count {
            var allBeacons = [(Int, Beacons)]()
            for current in getDataBeacons {
                allBeacons.append((0, current))
            }
            
            
            for index in beacons.indices {
                //let majorminor = String(Int(truncating: current.major)) + " " + String(Int(truncating: current.minor))
                var distance: Int
                if beacons[index].proximity == .immediate {
                    distance = 0
                }
                else if beacons[index].proximity == .near {
                    distance = 1
                }
                else if beacons[index].proximity == .far {
                    distance = 2
                }
                else {
                    distance = 3
                }
                
                for secondIndex in allBeacons.indices {
                    if allBeacons[secondIndex].1.parseMajorMinor().major == Int(truncating: beacons[index].major) {
                        allBeacons[secondIndex].0 = distance
                    }
                }
            }
            
            mapView.drawCurrentPosition = true
            mapView.findLocation(allBeacons)
        }
        else {
            mapView.findLocation(Array())
            mapView.drawCurrentPosition = false
        }
    }
    
    func updateDistance(_ distance: CLProximity) {
        UIView.animate(withDuration: 0.1, animations: {
            switch distance {
            case .unknown:
                self.mapView!.backgroundColor = UIColor.darkGray
            case .far:
                self.mapView!.backgroundColor = UIColor.red
            case .near:
                self.mapView!.backgroundColor = UIColor.orange
            case .immediate:
                self.mapView!.backgroundColor = UIColor.green
            }
        })
    }
    
    @objc func handleSwipe(sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            switch sender.direction {
            case .right:
                if !hamburgerMenuIsVisible {
                    leadingC.constant = 300
                    //this constant is NEGATIVE because we are moving it 150 points OUTWARD and that means -150
                    trailingC.constant = -300
                    leadingS.constant = 300
                    //this constant is NEGATIVE because we are moving it 150 points OUTWARD and that means -150
                    trailingS.constant = -300
                    //1
                    hamburgerMenuIsVisible = true
                    UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                        self.view.layoutIfNeeded()
                    }) { (animationComplete) in
                        print("The animation is complete!")
                    }
                }
            case .left:
                if hamburgerMenuIsVisible {
                    leadingC.constant = 0
                    trailingC.constant = 0
                    leadingS.constant = 0
                    trailingS.constant = 0
                    //2
                    hamburgerMenuIsVisible = false
                    UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                        self.view.layoutIfNeeded()
                    }) { (animationComplete) in
                        print("The animation is complete!")
                    }
                }
            default:
                break
                
            }
        }
    }
    
    func newSearch(_ controller: FinderInsideViewController,  fromField: String, ToField: String) {
        ////////added by Vadim
        dismiss(animated: true, completion: nil)
        print(fromField)
        print(ToField)
        //убрать текущий модальный контроллер
        
        if fromField == "" {
            var finishRoom: Rooms?
            for current in allRooms {
                if current.name == ToField {
                    finishRoom = current
                }
            }
            
            var nearestVertex: Vertex?
            if mapView.currentPosition == nil {
                print("No Current Position")
                return
            }
            let currentPosition = (x: Double(mapView.currentPosition!.x), y: Double(mapView.currentPosition!.y))
            
            for current in allVertexes {
                if nearestVertex == nil {
                    nearestVertex = current
                }
                else {
                    let nearestVertexCoordinates = (x: nearestVertex!.parseCoordinates()!.x, y: nearestVertex!.parseCoordinates()!.y)
                    let currentCoordinates = (x: current.parseCoordinates()!.x, y: current.parseCoordinates()!.y)
                    if distance(nearestVertexCoordinates, currentPosition) > distance(currentCoordinates, currentPosition) {
                        nearestVertex = current
                    }
                }
            }
            
            if finishRoom != nil, nearestVertex != nil {
                mapView.pathVertexes = graph.findShortestPathRunningDijkstra(start: nearestVertex!, finish: finishRoom!).1
                mapView.needsPathBuild = true
            }
            else {
                mapView.needsPathBuild = false
            }
        }
        else {
            var startRoom: Rooms?
            var finishRoom: Rooms?
            for current in allRooms {
                if current.name == fromField {
                    startRoom = current
                }
                if current.name == ToField {
                    finishRoom = current
                }
            }
            
            if finishRoom != nil && startRoom != nil {
                mapView.pathVertexes = graph.findShortestPathRunningDijkstra(start: startRoom!, finish: finishRoom!).1
                mapView.needsPathBuild = true
            }
            else {
                mapView.needsPathBuild = false
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as? FinderInsideViewController
        if let newBirthdayController = controller {
            newBirthdayController.delegate = self
        }
    }
    //////////
}

