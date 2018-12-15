//
//  CoordinateTransformer.swift
//  AnyGIS_ServerPackageDescription
//
//  Created by nnngrach on 26/11/2018.
//

import Foundation

class CoordinateTransformer {
    
    enum TransformerError: Error {
        case inputValueIsNotINT
        case inputValueIsNotDOUBLE
        case unknownError
    }
    
    // MARK: Web Mercator transformations
    
    func normalizeCoordinates(_ xText: String, _ yText: String, _ zoom: Int) throws -> (x: Int, y: Int) {
        
        // If user find by lat/log (as double)
        if (xText.contains(".") || yText.contains(".")) {
            
            guard let latitude = Double(xText) else { throw TransformerError.inputValueIsNotDOUBLE}
            guard let longitude = Double(yText) else { throw TransformerError.inputValueIsNotDOUBLE}
            
            return coordinatesToTileNumbers(latitude, longitude, withZoom: zoom)
            
            //return [0, 0]
        
        // If user find directly by tile numbers (as int)
        } else {
            guard let xTile = Int(xText) else { throw TransformerError.inputValueIsNotINT}
            guard let yTile = Int(yText) else { throw TransformerError.inputValueIsNotINT}
            return (xTile, yTile)
        }
    }
    
    
    
    func coordinatesToTileNumbers(_ latitude: Double, _ longitude: Double, withZoom zoom: Int) -> (x: Int, y: Int) {
        let tileX = Int(floor((longitude + 180) / 360.0 * pow(2.0, Double(zoom))))
        let tileY = Int(floor((1 - log( tan( latitude * Double.pi / 180.0 ) + 1 / cos( latitude * Double.pi / 180.0 )) / Double.pi ) / 2 * pow(2.0, Double(zoom))))
        
        return (tileX, tileY)
    }
    
    
    func tileNumberToCoordinates(tileX : Int, tileY : Int, mapZoom: Int) -> (lat_deg : Double, lon_deg : Double) {
        let n : Double = pow(2.0, Double(mapZoom))
        let lon = (Double(tileX) / n) * 360.0 - 180.0
        let lat = atan( sinh (.pi - (Double(tileY) / n) * 2 * Double.pi)) * (180.0 / .pi)
        
        return (lat, lon)
    }
    
    
    
    
    
    // MARK: WGS-84 transformations
    
    
    
    
    
    
    
    // MARK: URL replacing functions
    
    func getX(from coordinates: [Int], serverName: String) -> String {
        return "\(coordinates[0])"
    }
    
    func getY(from coordinates: [Int], serverName: String) -> String {
        return "\(coordinates[1])"
    }
    
    func getZ(from coordinates: [Int], serverName: String) -> String {
        return "\(coordinates[2])"
    }
    
    
    func getS(from coordinates: [Int], serverName: String) -> String {
        if serverName == "wikimapia" {
            let result = ((coordinates[0]%4) + (coordinates[1]%4)*4)
            return "\(result)"
        } else {
            return String(serverName.randomElement()!)
        }
    }
    
    
    
    func getGoogleZ(from coordinates: [Int], serverName: String) -> String {
        let result = 17 - coordinates[2]
        return "\(result)"
    }
    
    func getInvY(from coordinates: [Int], serverName: String) -> String {
        let z = Double(coordinates[2])
        let result = Int(pow(2.0, z)) - coordinates[1] - 1
        return String(result)
    }
    
    
    
    func getSasZ(from coordinates: [Int], serverName: String) -> String {
        let result = 1 + coordinates[2]
        return "\(result)"
    }
    
    func getFolderX(from coordinates: [Int], serverName: String) -> String {
        let result = Int(coordinates[0] / 1024)
        return "\(result)"
    }
    
    func getFolderY(from coordinates: [Int], serverName: String) -> String {
        let result = Int(coordinates[1] / 1024)
        return "\(result)"
    }
    
}
