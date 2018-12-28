//
//  CloudinaryStructs.swift
//  AnyGIS_ServerPackageDescription
//
//  Created by HR_book on 15/12/2018.
//

import Vapor
    
struct CloudinaryPostMessage: Content {
    var file: String
    var public_id: String
    var upload_preset: String
}

struct CloudinaryImgUrl: Content {
    var url: String
}


