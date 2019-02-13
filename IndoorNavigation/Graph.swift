//
//  Graph.swift
//  indoor navigation a
//
//  Created by Исмагил Сайфутдинов on 01/02/2019.
//  Copyright © 2019 Исмагил Сайфутдинов. All rights reserved.
//

import Foundation

class Graph {
    var adjacencyList = [Vertex : [(vertex: Vertex, length: Double)]] ()
    
    init(edgesList: [Edge], vertexesList: [Vertex]) {
        for currentEdge in edgesList {
            if let from = currentEdge.vertexfromrelationship, let to = currentEdge.vertextorelationship {
                if self.adjacencyList[from] == nil {
                    self.adjacencyList[from] = Array()
                }
                self.adjacencyList[from]!.append((to, Double(currentEdge.distance) ?? 0.0))
            }
        }
    }
    
    func findShortestPathRunningDijkstra(start: Rooms, finish: Rooms) -> (Double?, [Vertex]) {
        var minimalDist = Double.infinity
        var path = [Vertex]()
        for startVertex in start.vertexrelationship ?? [] {
            var usedVertexes = Set<Vertex>()
            var distances = [Vertex : Double]()
            var parents = [Vertex: Vertex]()
            
            distances[startVertex as! Vertex] = 0
            while true {
                var currentVertex: Vertex? = nil
                
                
                for probablyNewCurrentVertex in adjacencyList.keys {
                    if (usedVertexes.contains(probablyNewCurrentVertex) == false) {
                        if distances[probablyNewCurrentVertex] == nil {
                            continue
                        }
                        
                        if currentVertex == nil {
                            currentVertex = probablyNewCurrentVertex
                        }
                        else if distances[probablyNewCurrentVertex]! < distances[currentVertex!]! {
                            currentVertex = probablyNewCurrentVertex
                        }
                    }
                }
                
                if currentVertex == nil {
                    break
                }
                
                usedVertexes.insert(currentVertex!)
                
                for connected in adjacencyList[currentVertex!] ?? Array() {
                    if (distances[connected.vertex] ?? Double.infinity > distances[currentVertex!]! + connected.length) {
                        distances[connected.vertex] = distances[currentVertex!]! + connected.length
                        parents[connected.vertex] = currentVertex
                    }
                }
            }
            
            var finishVertex: Vertex? = nil
            
            for vertex in self.adjacencyList.keys {
                if let room = vertex.roomsrelationship, usedVertexes.contains(vertex) {
                    if room == finish {
                        if finishVertex == nil {
                            finishVertex = vertex
                        }
                        else if distances[finishVertex!]! > distances[vertex]! {
                            finishVertex = vertex
                        }
                    }
                }
            }
            
            if finishVertex == nil {
                continue
            }
            
            var lastVertexInPath = finishVertex!
            var shortestPath = [Vertex]()
            while (lastVertexInPath != startVertex as! Vertex) {
                shortestPath.append(lastVertexInPath)
                lastVertexInPath = parents[lastVertexInPath]!
            }
            shortestPath.append(startVertex as! Vertex)
            shortestPath.reverse()
            
            if distances[finishVertex!]! < minimalDist {
                minimalDist = distances[finishVertex!]!
                path = shortestPath
            }
        }
        if minimalDist < Double.infinity {
            return (minimalDist, path)
        }
        return (nil, Array())
    }
    
    func findShortestPathRunningDijkstra(start: Vertex, finish: Rooms) -> (Double?, [Vertex]) {
        var usedVertexes = Set<Vertex>()
        var distances = [Vertex : Double]()
        var parents = [Vertex: Vertex]()
        
        distances[start] = 0
        while true {
            var currentVertex: Vertex? = nil
            
            
            for probablyNewCurrentVertex in adjacencyList.keys {
                if (usedVertexes.contains(probablyNewCurrentVertex) == false) {
                    if distances[probablyNewCurrentVertex] == nil {
                        continue
                    }
                    
                    if currentVertex == nil {
                        currentVertex = probablyNewCurrentVertex
                    }
                    else if distances[probablyNewCurrentVertex]! < distances[currentVertex!]! {
                        currentVertex = probablyNewCurrentVertex
                    }
                }
            }
            
            if currentVertex == nil {
                break
            }
            
            usedVertexes.insert(currentVertex!)
            
            for connected in adjacencyList[currentVertex!] ?? Array() {
                if (distances[connected.vertex] ?? Double.infinity > distances[currentVertex!]! + connected.length) {
                    distances[connected.vertex] = distances[currentVertex!]! + connected.length
                    parents[connected.vertex] = currentVertex
                }
            }
        }
            
        var finishVertex: Vertex? = nil
        
        for vertex in self.adjacencyList.keys {
            if let room = vertex.roomsrelationship, usedVertexes.contains(vertex) {
                if room == finish {
                    if finishVertex == nil {
                        finishVertex = vertex
                    }
                    else if distances[finishVertex!]! > distances[vertex]! {
                        finishVertex = vertex
                    }
                }
            }
        }
            
        if finishVertex == nil {
            return (nil, Array())
        }
            
        var lastVertexInPath = finishVertex!
        var shortestPath = [Vertex]()
        while (lastVertexInPath != start) {
            shortestPath.append(lastVertexInPath)
            lastVertexInPath = parents[lastVertexInPath]!
        }
        shortestPath.append(start)
        shortestPath.reverse()
            
        return (distances[finishVertex!], shortestPath)
    }
}
