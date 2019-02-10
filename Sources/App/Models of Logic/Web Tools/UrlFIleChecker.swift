//
//  UrlChecker.swift
//  AnyGIS_ServerPackageDescription
//
//  Created by HR_book on 04/02/2019.
//

import Foundation
import Vapor

// Recursive checkers for file existing by URL

class UrlFIleChecker {
    
    let sqlHandler = SQLHandler()
    let output = OutputResponceGenerator()
    let urlPatchCreator = URLPatchCreator()
    let coordinateTransformer = CoordinateTransformer()
    
    var delegate: WebHandlerDelegate?
    
    
    // Checker for MultyLayer mode
    public func checkMultyLayerList(_ maps: [PriorityMapsList], _ index: Int, _ x: Int, _ y: Int, _ z: Int, _ req: Request) throws -> Future<Response> {

        let currentMapName = maps[index].mapName

        // Quick redirect for maps with global coverage
        guard !maps[index].notChecking else {
            return try delegate!.startSearchingForMap(currentMapName, xText: String(x), String(y), z, req)
        }


        // Filter checking maps by it's coverage area
        let coordinates = coordinateTransformer.tileNumberToCoordinates(x, y, z)
        let xRange = maps[index].xMin ... maps[index].xMax
        let yRange = maps[index].yMin ... maps[index].yMax

        let defaultValue = 0.0...0.0
        let isMapWithoutLimits = (xRange == defaultValue && xRange == defaultValue)
        let isPointInCoverageArea = xRange.contains(coordinates.lon_deg) && yRange.contains(coordinates.lat_deg)

        guard isMapWithoutLimits || isPointInCoverageArea else {
            return try checkMultyLayerList(maps, index+1, x, y, z, req)
        }


        // Start checking maps existing
        var redirectingResponse: Future<Response>

        let response = try checkMirrorsList(currentMapName, x, y, z, req)

        redirectingResponse = response.flatMap(to: Response.self) { res in

            if (res.http.status.code == 404) && (maps.count > index+1) {
                // print("Recursive find next ")
                return try self.checkMultyLayerList(maps, index+1, x, y, z, req)

            } else if(res.http.status.code == 404) {
                // print("Fail ")
                return self.output.notFoundResponce(req)

            } else {
                // print("Success ")
                return req.future(res)
            }
        }

        return redirectingResponse
    }
    
    
    
    
    
    // Checker for Mirrors mode
    public func checkMirrorsList(_ mirrorName: String, _ x: Int, _ y: Int, _ z: Int, _ req: Request) throws -> Future<Response> {
        
        // Load info for every mirrors from data base in Future format
        let mirrorsList = try sqlHandler.getMirrorsListBy(setName: mirrorName, req)
        
        // Synchronization Futrure to data object.
        let redirectingResponce = mirrorsList.flatMap(to: Response.self) { mirrorsListData  in
            
            guard mirrorsListData.count != 0 else {return self.output.notFoundResponce(req)}
            
            let urls = mirrorsListData.map {$0.url}
            let hosts = mirrorsListData.map {$0.host}
            let patchs = mirrorsListData.map {$0.patch}
            let ports = mirrorsListData.map {$0.port}
            
            var firstFoundedUrlResponse : Future<Response>
            
            // Custom randomized iterating of array
            let startIndex = 0
            let shuffledOrder = makeShuffledOrder(maxNumber: mirrorsListData.count)
            
            // File checker
            let firstCheckingIndex = shuffledOrder[startIndex] ?? 0
            
            
            if hosts[firstCheckingIndex] == "dont't need to check" {
                // Global maps. Dont't need to check it
                let newUrl = self.urlPatchCreator.calculateTileURL(x, y, z, urls[firstCheckingIndex], "")
                
                firstFoundedUrlResponse = self.output.redirect(to: newUrl, with: req)
                
            } else {
                // Local maps. Start checking of file existing for all mirrors URLs
                firstFoundedUrlResponse = self.findExistingMirrorNumber(index: startIndex, hosts, ports, patchs, urls, x, y, z, shuffledOrder, req: req)
            }
            
            return firstFoundedUrlResponse
        }
        
        return redirectingResponce
    }
    
    
    
    
    
    // Mirrors mode recursive checker sub function
    private func findExistingMirrorNumber(index: Int, _ hosts: [String], _ ports: [String], _ patchs: [String], _ urls: [String], _ x: Int, _ y: Int, _ z: Int, _ order: [Int:Int], req: Request) -> Future<Response> {
        
        guard let currentShuffledIndex = order[index] else {return output.notFoundResponce(req)}
        
        let timeout = 500       //TODO: I need to increase this speed
        let defaultPort = 8080
        var connection: EventLoopFuture<HTTPClient>
        
        // Connect to Host URL with correct port
        if ports[currentShuffledIndex] == "any" {
            connection = HTTPClient.connect(hostname: hosts[currentShuffledIndex], on: req)
        } else {
            let portNumber = Int(ports[currentShuffledIndex]) ?? defaultPort
            connection = HTTPClient.connect(hostname: hosts[currentShuffledIndex], port: portNumber, connectTimeout: .milliseconds(timeout), on: req)
        }
        
        // Synchronization: Waiting, while coonection will be started
        let firstFoundedFileIndex = connection.flatMap { (client) -> Future<Response> in
            
            // Generate URL and make Request for it
            let currentUrl = self.urlPatchCreator.calculateTileURL(x, y, z, patchs[currentShuffledIndex], "")
            
            let request = HTTPRequest(method: .HEAD, url: currentUrl)
            
            
            // Send Request and check HTML status code
            // Return index of founded file if success.
            return client.send(request).flatMap{ (response) -> Future<Response> in
                
                if response.status.code != 403 && response.status.code != 404 {
                    //print ("Success: File founded! ", hosts[index], currentUrl, response.status.code)
                    let newUrl = self.urlPatchCreator.calculateTileURL(x, y, z, urls[currentShuffledIndex], "")
                    return self.output.redirect(to: newUrl, with: req)
                    
                } else if (index + 1) < hosts.count {
                    //print ("Recursive find for next index: ", hosts[index], currentUrl, response.status.code)
                    return self.findExistingMirrorNumber(index: index+1, hosts, ports, patchs, urls, x, y, z, order, req: req)
                    
                } else {
                    //print("Fail: All URLs checked and file not founded. ", response.status.code)
                    return self.output.notFoundResponce(req)
                }
            }
        }
        
        return firstFoundedFileIndex
    }

}