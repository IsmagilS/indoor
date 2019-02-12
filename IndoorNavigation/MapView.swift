//
//  MapView.swift
//  indoor navigation a
//
//  Created by Исмагил Сайфутдинов on 01/02/2019.
//  Copyright © 2019 Исмагил Сайфутдинов. All rights reserved.
//

import UIKit
import CoreLocation

class MapView: UIView {
    
    var updateMapView = 0 { didSet { setNeedsDisplay() } }
    private var mapScale: CGFloat = 1.0 { didSet { setNeedsDisplay() } }
    private var mapOffsetX: CGFloat = 0.0 { didSet { setNeedsDisplay() } }
    private var mapOffsetY: CGFloat = 0.0 { didSet { setNeedsDisplay() } }
    
    var needsPathBuild = false { didSet { setNeedsDisplay() } }
    var pathVertexes: [Vertex]? = nil { didSet { setNeedsDisplay() } }
    
    var currentFloor: Floors? = nil { didSet { setNeedsDisplay() } }
    
    var currentPosition: CGPoint? = nil { didSet { setNeedsDisplay() } }
    
    var drawCurrentPosition = false { didSet { setNeedsDisplay() } }
    
    private var minX = 0.0
    private var maxX = 0.0
    private var minY = 0.0
    private var maxY = 0.0
    private var ratioX = 0.0
    private var ratioY = 0.0
    
    
    @objc func adjustMapScale(byHandlingGestureRecognizer recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .changed, .ended:
            mapScale *= recognizer.scale
            recognizer.scale = 1.0
            if mapScale < 0.25 {
                mapScale = 0.25
            }
            if mapScale > 10 {
                mapScale = 10
            }
        default:
            break
        }
    }
    
    @objc func getTappedRectangle(UsingHandlingGestureRecognizer recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            let magic = min(bounds.width, bounds.height)
            
            var localPolygon: Polygon?
            for rectangle in allRooms {
                if rectangle.floorsrelationship != currentFloor {
                    continue
                }
                
                let figure = Polygon(points: rectangle.parsePolygon() ?? [])
                
                if figure.points.count == 0 {
                    continue
                }
                
                figure.offset(dx: -minX, dy: -minY)
                figure.adjustCoordinates(multiplierX: ratioX, multiplierY: ratioY)
                figure.offset(dx: Double(magic) * 0.01, dy: Double(magic) * 0.01)
                figure.adjustCoordinates(multiplierX: Double(mapScale), multiplierY: Double(mapScale))
                figure.offset(dx: -Double(mapOffsetX), dy: -Double(mapOffsetY))
                
                let point = recognizer.location(in: recognizer.view)
                //point = point.offset(dx: -minX, dy: -minY).adjustCoordinates(multiplierX: ratioX, multiplierY: ratioY).offset(dx: Double(magic) * 0.01, dy: Double(magic) * 0.01).adjustCoordinates(multiplierX: Double(mapScale), multiplierY: Double(mapScale)).offset(dx: -Double(mapOffsetX), dy: -Double(mapOffsetY))
                
                if figure.isInside(point: (x: Double(point.x), y: Double(point.y))) {
                    if localPolygon == nil {
                        localPolygon = figure
                    }
                    else {
                        if localPolygon!.square() > figure.square() {
                            localPolygon = figure
                        }
                    }
                }
            }
            
            print("@@@@@@@@@@@@@@@")
            print(localPolygon?.points ?? [])
        default:
            break
        }
    }
    
    @objc func adjustMapOffset(byHandlingGestureRecognizer recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            mapOffsetX += -recognizer.translation(in: recognizer.view).x
            mapOffsetY += -recognizer.translation(in: recognizer.view).y
            recognizer.setTranslation(CGPoint.zero, in: recognizer.view)
        case .changed:
            mapOffsetX += -recognizer.translation(in: recognizer.view).x
            mapOffsetY += -recognizer.translation(in: recognizer.view).y
            recognizer.setTranslation(CGPoint.zero, in: recognizer.view)
            
        default:
            break
        }
    }
    
    func findLocation(_ beacons: [(signal : Int, item: Beacons)]) {
        var array = beacons.sorted(by: { $0.signal < $1.signal })
        
        var sumOfAll = (x: 0.0, y: 0.0)
        var countOfAll = 0.0
        for current in array {
            if current.signal != array[0].signal {
                break
            }
            if  current.1.roomsrelationship!.floorsrelationship != currentFloor {
                continue
            }
            
            sumOfAll.x += current.item.parseCoordinates()!.x
            sumOfAll.y += current.item.parseCoordinates()!.y
            countOfAll += 1
        }
        
        if countOfAll == 0 {
            currentPosition = nil
            return
        }
        
        let location = CGPoint(x: sumOfAll.x / countOfAll, y: sumOfAll.y / countOfAll)
        currentPosition = location
    }
    
    private func drawRooms(rooms: [Rooms]) {
        let magic = min(bounds.width, bounds.height)
        
        var figures =  [Polygon]()
        for room in rooms {
            figures.append(Polygon(points: room.parsePolygon()!))
        }
        
        for index in figures.indices {
            figures[index].offset(dx: -minX, dy: -minY)
            figures[index].adjustCoordinates(multiplierX: ratioX, multiplierY: ratioY)
            figures[index].offset(dx: Double(magic) * 0.01, dy: Double(magic) * 0.01)
            figures[index].adjustCoordinates(multiplierX: Double(mapScale), multiplierY: Double(mapScale))
            figures[index].offset(dx: -Double(mapOffsetX), dy: -Double(mapOffsetY))
        }
        
        for current in figures {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: current.points[0].x, y: current.points[0].y))
            for index in current.points.indices {
                path.addLine(to: CGPoint(x: current.points[index].x, y: current.points[index].y))
            }
            path.close()
            
            path.lineWidth = CGFloat(3.0)
            #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1).setFill()
            UIColor.black.setStroke()
            path.fill()
            path.stroke()
        }
    }
    
    private func drawExits(exits: [Edge]) {
        let magic = min(bounds.width, bounds.height)
        
        var exitsLines = [Polygon]()
        for exit in exits {
            if let currentExit = exit.parseDoorsCoordinates() {
                if let from = exit.vertexfromrelationship, let to = exit.vertextorelationship {
                    if let fromRoom = from.roomsrelationship, let toRoom = to.roomsrelationship {
                        if fromRoom.floorsrelationship == currentFloor, toRoom.floorsrelationship == currentFloor {
                            exitsLines.append(Polygon(points: currentExit))
                        }
                    }
                }
            }
        }
        
        for index in exitsLines.indices {
            exitsLines[index].offset(dx: -minX, dy: -minY)
            exitsLines[index].adjustCoordinates(multiplierX: ratioX, multiplierY: ratioY)
            exitsLines[index].offset(dx: Double(magic) * 0.01, dy: Double(magic) * 0.01)
            exitsLines[index].adjustCoordinates(multiplierX: Double(mapScale), multiplierY: Double(mapScale))
            exitsLines[index].offset(dx: -Double(mapOffsetX), dy: -Double(mapOffsetY))
        }
        
        for current in exitsLines {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: current.points[0].x, y: current.points[0].y))
            path.addLine(to: CGPoint(x: current.points[1].x, y: current.points[1].y))
            
            path.lineWidth = CGFloat(2.0)
            UIColor.white.setStroke()
            path.stroke()
        }
    }
    
    private func drawPoints(vertexes: [CGPoint]) -> [CGPoint] {
        let magic = min(bounds.width, bounds.height)
        
        var secondVertexesArray = vertexes
         for index in vertexes.indices {
            let newVertexValue: CGPoint = secondVertexesArray[index].offset(dx: -minX, dy: -minY).adjustCoordinates(multiplierX: ratioX, multiplierY: ratioY).offset(dx: Double(magic) * 0.01, dy: Double(magic) * 0.01).adjustCoordinates(multiplierX: Double(mapScale), multiplierY: Double(mapScale)).offset(dx: -Double(mapOffsetX), dy: -Double(mapOffsetY))
             secondVertexesArray[index] = newVertexValue
         }
        
        for current in secondVertexesArray {
            let path = UIBezierPath()
            
            if (drawCurrentPosition == true && current == secondVertexesArray.last!) {
                path.addArc(withCenter: current, radius: CGFloat(6), startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
                path.close()
                
                path.lineWidth = CGFloat(1.0)
                UIColor.green.setFill()
                UIColor.black.setStroke()
                path.fill()
                path.stroke()
            }
            else {
                path.addArc(withCenter: current, radius: CGFloat(3), startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
                path.close()
                
                path.lineWidth = CGFloat(2.0)
                UIColor.blue.setFill()
                UIColor.black.setStroke()
                path.fill()
                path.stroke()
            }
        }
         
        return secondVertexesArray
    }
    
    private func drawPath(vertexes: [CGPoint]?) {
        if vertexes == nil {
            return
        }
        if (vertexes!.count == 0) {
            return
        }
        
        let magic = min(bounds.width, bounds.height)
        
        var secondVertexesArray = vertexes!
        for index in vertexes!.indices {
            let newVertexValue: CGPoint = secondVertexesArray[index].offset(dx: -minX, dy: -minY).adjustCoordinates(multiplierX: ratioX, multiplierY: ratioY).offset(dx: Double(magic) * 0.01, dy: Double(magic) * 0.01).adjustCoordinates(multiplierX: Double(mapScale), multiplierY: Double(mapScale)).offset(dx: -Double(mapOffsetX), dy: -Double(mapOffsetY))
            secondVertexesArray[index] = newVertexValue
        }
        
        let path = UIBezierPath()
        let start = secondVertexesArray[0]
        path.move(to: CGPoint(x: start.x, y: start.y))
        
        for current in secondVertexesArray {
            path.addLine(to: CGPoint(x: current.x, y: current.y))
        }
        
        path.lineWidth = CGFloat(3.0)
        UIColor.blue.setStroke()
        path.stroke()
    }
    
    override func draw(_ rect: CGRect) {
        
        if currentFloor == nil {
            return
        }
        
        minX = Double.infinity
        maxX = -Double.infinity
        minY = Double.infinity
        maxY = -Double.infinity
        
        for current in currentFloor!.roomsrelationship! {
            for point in (current as! Rooms).parsePolygon()! {
                minX = min(minX, point.x)
                maxX = max(maxX, point.x)
            
                minY = min(minY, point.y)
                maxY = max(maxY, point.y)
            }
        }
        
        let magic = min(bounds.width, bounds.height)
        
        ratioX = (Double(magic) * 0.98) / (maxX - minX)
        ratioY = (Double(magic) * 0.98) / (maxY - minY)
        
        //--------Ismagil's comment----------
        /*
         all zoom and offset variables created
        */
        
        var rooms =  [Rooms]()
        
        for current in currentFloor!.roomsrelationship! {
            if let room = current as? Rooms {
                rooms.append(room)
            }
        }
        
        drawRooms(rooms: rooms)
        
        drawExits(exits: allEdges)
        
        var vertexes = [CGPoint]()
        for current in allEdges {
            if let vertex = current.vertexfromrelationship {
                if let room = vertex.roomsrelationship {
                    if room.floorsrelationship == currentFloor, let point = vertex.parseCoordinates() {
                        vertexes.append(CGPoint(x: point.x, y: point.y))
                    }
                }
            }
            if let vertex = current.vertextorelationship {
                if let room = vertex.roomsrelationship {
                    if room.floorsrelationship == currentFloor, let point = vertex.parseCoordinates() {
                        vertexes.append(CGPoint(x: point.x, y: point.y))
                    }
                }
            }
        }
        
        if let position = currentPosition {
            vertexes.append(position)
            drawCurrentPosition = true
        }
        else {
            drawCurrentPosition = false
        }
        vertexes = drawPoints(vertexes: vertexes)
        
        //--------Ismagil's comment----------
        /*
         map is drawn
        */
        
        if needsPathBuild {
            vertexes.removeAll()
            if pathVertexes == nil {
                return
            }
            if pathVertexes!.count == 0 {
                return
            }
            
            for current in pathVertexes! {
                if let room = current.roomsrelationship {
                    if room.floorsrelationship == currentFloor {
                        if let point = current.parseCoordinates() {
                            vertexes.append(CGPoint(x: point.x, y: point.y))
                        }
                    }
                }
            }
            
            drawPath(vertexes: vertexes)
        }
    }
}

extension CGPoint {
    func offset(dx: Double, dy: Double) -> CGPoint {
        let newX = x + CGFloat(dx)
        let newY = y + CGFloat(dy)
        return CGPoint(x: newX, y: newY)
    }
    
    func adjustCoordinates(multiplierX: Double, multiplierY: Double) -> CGPoint {
        let newX = x * CGFloat(multiplierX)
        let newY = y * CGFloat(multiplierY)
        return CGPoint(x: newX, y: newY)
    }
}

extension Polygon {
    func offset(dx: Double, dy: Double) {
        for index in 0 ..< points.count {
            points[index].x += dx
            points[index].y += dy
        }
    }
    
    func adjustCoordinates(multiplierX: Double, multiplierY: Double) {
        for index in 0 ..< points.count {
            points[index].x *= multiplierX
            points[index].y *= multiplierY
        }
    }
}

extension Vertex {
    func parseCoordinates() -> (x: Double, y: Double)? {
        var current = ""
        
        var coordinateX = 0.0
        var coordinateY = 0.0
        
        for currentSymbol in coordinates {
            if currentSymbol == Character(" ") {
                coordinateX = Double(current)!
                current = ""
            }
            else {
                current.append(currentSymbol)
            }
        }
        
        coordinateY = Double(current)!
        return (x: coordinateX, coordinateY)
    }
}

extension Beacons {
    func parseCoordinates() -> (x: Double, y: Double)? {
        var current = ""
        
        var coordinateX = 0.0
        var coordinateY = 0.0
        
        for currentSymbol in coordinates {
            if currentSymbol == Character(" ") {
                coordinateX = Double(current)!
                current = ""
            }
            else {
                current.append(currentSymbol)
            }
        }
        
        coordinateY = Double(current)!
        return (x: coordinateX, coordinateY)
    }
}


extension Edge {
    func parseDoorsCoordinates() -> [(x: Double, y: Double)]? {
        
        if doorscoordinates == "nil" {
            return nil
        }
        
        var current = ""
        
        var arrayToReturn = [(x: Double, y: Double)]()
        
        var coordinateX = 0.0
        var coordinateY = 0.0
        var numberOfCoordinatesFound = 0
        for currentSymbol in doorscoordinates {
            if currentSymbol == Character(" ") {
                numberOfCoordinatesFound += 1
                
                if numberOfCoordinatesFound % 2 == 1 {
                    coordinateX = Double(current)!
                }
                else {
                    coordinateY = Double(current)!
                    arrayToReturn.append((x: coordinateX, y: coordinateY))
                }
                current = ""
            }
            else {
                current.append(currentSymbol)
            }
        }
        
        if numberOfCoordinatesFound % 2 == 0 {
            return nil
        }
        
        coordinateY = Double(current)!
        arrayToReturn.append((x: coordinateX, y: coordinateY))
        
        return arrayToReturn
    }
}

extension Rooms {
    func parsePolygon() -> [(x: Double, y: Double)]? {
        var current = ""
        
        var arrayToReturn = [(x: Double, y: Double)]()
        
        var coordinateX = 0.0
        var coordinateY = 0.0
        var numberOfCoordinatesFound = 0
        for currentSymbol in polygon {
            if currentSymbol == Character(" ") {
                numberOfCoordinatesFound += 1
                
                if numberOfCoordinatesFound % 2 == 1 {
                    coordinateX = Double(current)!
                }
                else {
                    coordinateY = Double(current)!
                    arrayToReturn.append((x: coordinateX, y: coordinateY))
                }
                current = ""
            }
            else {
                current.append(currentSymbol)
            }
        }
        
        if numberOfCoordinatesFound % 2 == 0 {
            return nil
        }
        
        coordinateY = Double(current)!
        arrayToReturn.append((x: coordinateX, y: coordinateY))

        return arrayToReturn
    }
}

extension Beacons {
    static func < (lhs: Beacons, rhs: Beacons) -> Bool {
        return lhs.id < rhs.id
    }
    
    func parseMajorMinor() -> (major: Int?, minor: Int?) {
        var current = ""
        var firstNumber: Int? = nil
        var secondNumber: Int? = nil
        
        for currentSymbol in majorminor {
            if currentSymbol == Character(" ") {
                if current == "" {
                    firstNumber = nil
                }
                else {
                    firstNumber = Int(current)
                }
                
                current = ""
            }
            else {
                current.append(currentSymbol)
            }
        }
        
        if current == "" {
            secondNumber = nil
        }
        else {
            secondNumber = Int(current)
        }
        
        return (major: firstNumber, minor: secondNumber)
    }
}
