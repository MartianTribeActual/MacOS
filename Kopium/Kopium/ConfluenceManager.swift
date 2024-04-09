//
//  ConfluenceManager.swift
//  Kopium
//
//  Created by Steve Suranie on 3/11/24.
//

import Foundation

class ConfluenceManager {
    
    let myAppManager = AppManager()
    let authString = "Basic c3N1cmFuaWVAa2FyZ28uY29tOjRFeUYyQzFFRkZ0Z3dtYVh1dGJDNDQ3Mw"
    //let authString = "Basic a3RjQGthcmdvLmNvbTpldVFvbXhwd3RtaGpBUUh1UW10VDVBNjQ="
    //let authString = "Basic a3RjQGthcmdvLmNvbTpBVEFUVDN4RmZHRjBZNnBCU0oxYjBnVzNBMEJYMTZYdVh4SllFb1hFNTF2eXFmeE5pRWc2SlkxTFpLN0gtaG81UnZwMXdtNlRqUkVMeURyTmd4bkhfUEpSbzFyZzFSWTUzYkp6MFY1VTk0Y0p3by16Y1NBRXpmRThISFlONzg2OHJhVFRwTXh6S2x6TWVHejY5VFIxcHVobWpaNEs5WlA1SkdIdTlCUHVTeG5IRVNxb21CZDd5YUU9Q0YzNDVFRDU="
    
    //ktc@kargo.com:ATATT3xFfGF0Y6pBSJ1b0gW3A0BX16XuXxJYEoXE51vyqfxNiEg6JY1LZK7H-ho5Rvp1wm6TjRELyDrNgxnH_PJRo1rg1RY53bJz0V5U94cJwo-zcSAEzfE8HHYN7868raTTpMxzKlzMeGz69TR1puhmjZ4K9ZP5JGHu9BPuSxnHESqomBd7yaE=CF345ED5
    
    
    
    func getAllSpaces(completed: @escaping returnArrClosure) {
        
        myAppManager.callAPI("https://kargo1.atlassian.net/wiki/rest/api/", "space?limit=500&status=current&type=global", true, ["auth":authString], completed: {(dictResults:Dictionary<String, Any>) in
            if let dictData = dictResults["data"] as? Dictionary<String, Any>, let arrResults = dictData["results"] as? Array<Dictionary<String, Any>> {
                completed(arrResults)
            } else {
                print("There was an issue getting the Confluence spaces.")
            }
        })
        
    }
    
    func getSpaceContent(_ strId:String, completed: @escaping returnDictClosure) {
        
        myAppManager.callAPI("https://kargo1.atlassian.net/wiki/rest/api/", "space/\(strId)/content?limit=500", true, ["auth":authString], completed: {(dictResults:Dictionary<String, Any>) in
            completed(dictResults)
        })
    }
    
    
    func getPageContent(_ strId: String, completed: @escaping returnDictClosure) {
        myAppManager.callAPI("https://kargo1.atlassian.net/wiki/rest/api/", "content/\(strId)?expand=body.storage", true, ["auth":authString], completed: {(dictResults:Dictionary<String, Any>) in
            completed(dictResults)
        })
    }
    
}
