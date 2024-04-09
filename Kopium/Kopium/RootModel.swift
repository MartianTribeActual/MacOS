//
//  RootModel.swift
//  Kopium
//
//  Created by Steve Suranie on 3/4/24.
//

import Foundation
import CoreData

class RootModel {
    
//MARK: - Confuence Management
    
    func getSpaceData(_ arrData:Array<Any>) -> Array<Dictionary<String, Any>> {
        
        var arrSpaceData:Array<Dictionary<String, Any>> = []
        for thisObj in arrData {
            if let dictSpace = thisObj as? Dictionary<String, Any> {
                if let strKey = dictSpace["key"] as? String, let strName = dictSpace["name"] as? String, let strId = dictSpace["id"] {
                    arrSpaceData.append(["key": strKey, "name": strName, "id": strId])
                }
            }
        }
        return arrSpaceData
    }
    
    func getSpacePages(_ dictResults:Dictionary<String, Any>) -> Array<Dictionary<String, Any>> {
        
        var arrSpacePages:Array<Dictionary<String, Any>> = []
        if let dictData = dictResults["data"] as? Dictionary<String, Any>, let dictPage = dictData["page"] as? Dictionary<String, Any>, let arrPages = dictPage["results"] as? Array<Any> { //} let arrPage = dictData["page"] as? Array<Dictionary<String, Any>> {
            for thisPage in arrPages {
                if let dictPage = thisPage as? Dictionary<String, Any>, let strTitle = dictPage["title"] as? String, let strId = dictPage["id"] as? String, let dictExpands = dictPage["_expandable"] as? Dictionary<String, Any> {
                    arrSpacePages.append(["title":strTitle, "id": strId])
                }
            }
        }
        
        return arrSpacePages
    }

}
