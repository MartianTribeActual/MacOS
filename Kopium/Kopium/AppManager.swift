//
//  AppManager.swift
//  Copium
//
//  Created by Steve Suranie on 2/16/24.
//

import Foundation
import CoreData
import Cocoa
import Alamofire


typealias returnBoolClosure = (_ flag:Bool) -> Void
typealias returnArrClosure = (_ arrData:Array<Any>) -> Void
typealias returnDictClosure = (_ dictData:Dictionary<String, Any>) -> Void
typealias returnDictFromDictClosure = (_ dictData:Dictionary<String, Any>) -> Dictionary<String, Any>
typealias returnStringClosure = (_ strData:String) -> Void
typealias returnArrCoreDataClosure = (_ arrData:Array<NSManagedObject>) -> Void

enum CustomError  {
    case noErrorDetected
    case dataFetchFailed
    case dataSaveFailed
    case invalidInput
    case formEntryError
    case entityCreationFailed
    case noAuthSubmitted
}

enum TaskType: Int16 {
    case createAuthor = 0
    case updateAuthor = 1
    case createDocument = 2
    case updateDocument = 3
    case flushLog = 4
    case getDirectories = 5
    case readDirectory = 6
    case appStarted = 7

}

enum Platform: String {
    case konnect = "Kargo Konnect"
    case confluence = "Confluence"
    case google = "Google"
    case zendesk = "Zendesk"
}

enum TableType: Int {
    case log = 0
    case content = 1
    case conSpaces = 2
    case pagelist = 4
}

class AppManager {
    
    var viewController:ViewController?
    var isUserSignedIn = false
    
    
    //MARK: - Alerts
    
    func displayInfoAlert(_ strMsg:String, _ vc:NSViewController, _ arrButtons:Array<String>, _ bNeedsResponse:Bool, response:returnBoolClosure) {
        
        let vIcon = NSView(frame: NSRect(x: 20.0, y: 20.0, width: 40.0, height: 40.0))
        let imgLogo = NSImage(named:"dark-logo")
        let ivLogo = NSImageView(image: imgLogo!)
        vIcon.addSubview(ivLogo)
        
        let alert: NSAlert = NSAlert()
        alert.icon = ivLogo.image
        alert.layout()
        alert.messageText = strMsg
        alert.alertStyle = NSAlert.Style.informational
        for strBtnTitle in arrButtons {
            alert.addButton(withTitle: strBtnTitle)
        }
        
        if bNeedsResponse {
            
            var bResponse = false
            let res = alert.runModal()
            if res.rawValue == 1000 {
                bResponse = true
            }
            
            response(bResponse)
            
        } else {
            
            alert.runModal()
        }
        
    }
    
    func getTaskType(_ idx:Int16) -> String {
        var strType = ""
        
        switch idx {
        case 0:
            strType = "Create Author"
        case 1:
            strType = "Update Author"
        case 2:
            strType = "Create Document"
        case 3:
            strType = "Update Document"
        case 4:
            strType = "Flush Log"
        case 5:
            strType = "Reading Directories"
        default:
            strType = "Unknown"
        }
        
        return strType
    }
    
    //MARK: - Call APIs
    func callAPI(_ rootURL:String, _ strEndPoint:String, _ bNeedsAuth:Bool, _ dictAuth:Dictionary<String, Any>, completed: @escaping returnDictClosure) {
        
        let apiURL = URL(string: "\(rootURL)\(strEndPoint)")
        let apiRequest = URLRequest(url: apiURL!)
        
        
        let config = URLSessionConfiguration.default
        if bNeedsAuth {
            if let myAuth = dictAuth["auth"] as? String {
                config.httpAdditionalHeaders = ["Authorization" : myAuth]
            } else {
                print("There was an error getting the auth from the passed in dictionary.")
            }
        }
//        //set up URL Session - add auth
//        let config = URLSessionConfiguration.default
//        if let strAuth = dictAuth["auth"] as? String {
//            let authString = "Basic a3RjQGthcmdvLmNvbTpldVFvbXhwd3RtaGpBUUh1UW10VDVBNjQ="
//            config.httpAdditionalHeaders = ["Authorization" : authString]
//        }
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: apiRequest) { (data, response, error) in
            //print(response)
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error with response.")
                return
            }
            
            //if not a 200 response
            if httpResponse.statusCode != 200 {
                print("statusCode: \(httpResponse.statusCode)")
                print(httpResponse)
            } else {
                
                //do something with the returned data
                if let data = data {
                    let dictJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                    if let dictJSON = dictJSON as? Dictionary<String, Any> {
                        completed(["success":true, "data":dictJSON])
                    }
                }
            }
        }
        task.resume()
        
    }
    
    
    //MARK: - Core Data
    
    func getManagedObjectContext() -> NSManagedObjectContext {
        guard let appDelegate = NSApp.delegate as? AppDelegate else {
            fatalError("Unable to access AppDelegate")
        }
        let fetchedManageObjectContext = appDelegate.persistentContainer.viewContext
        return fetchedManageObjectContext
    }
    
    func getAllEntityTypes() -> [NSEntityDescription] {
        let myMoc = getManagedObjectContext()
        guard let model = myMoc.persistentStoreCoordinator?.managedObjectModel else {
            // Handle the case where the managed object model is not available
            return []
        }
        
        return model.entities
        
    }
    
    func fetchEntity(_ strEntity:String, _ dictData:Dictionary<String, Any>) -> Dictionary<String, Any> {
        
        var bSuccess = false
        var bNeedsResponse = true
        var myError = CustomError.noErrorDetected
        var myResults = [NSFetchRequestResult]()
        let myMoc = getManagedObjectContext()
        
        var strMsg = ""
            
        guard let entityDescription = NSEntityDescription.entity(forEntityName: strEntity, in: myMoc) else {
            fatalError("Entity description not found when trying to fetch \(strEntity) entity.")
        }
        
        // Create a fetch request with the entity description
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = entityDescription
        
        if let bNeedsPredicate = dictData["needsPredicate"] as? Bool {
            if bNeedsPredicate {
                if let myPredicate = dictData["predicate"] as? NSPredicate {
                    fetchRequest.predicate = myPredicate
                }
            }
        }
        
        do {
            
            // Perform the fetch request
            myResults = try myMoc.fetch(fetchRequest)
            
            if myResults.count == 0 {
                myError = CustomError.dataFetchFailed
                strMsg = "There were no results."
                bNeedsResponse = true
            } else {
                bSuccess = true
                bNeedsResponse = false

            }
        } catch {
            myError = CustomError.dataFetchFailed
            bSuccess = false
        }
        
    
        return ["success":bSuccess, "error":myError, "message":strMsg, "needsResponse":bNeedsResponse, "results": myResults]
    }
    
    func createCoreDataEntry(_ strEntity:String, _ dictData:Dictionary<String, Any>) -> NSManagedObject? {
        
        let myMoc = getManagedObjectContext()
        
        guard let entityDescription = NSEntityDescription.entity(forEntityName: strEntity, in: myMoc) else {
            fatalError("Entity description not found when trying to fetch \(strEntity) entity.")
        }
        
        let newManagedObject = NSManagedObject(entity: entityDescription, insertInto: myMoc)
        
        if strEntity == "AppTask" {
            if let taskType = dictData["taskType"] as? TaskType, let strSummary = dictData["summary"] as? String {
                newManagedObject.setValue(UUID().uuidString, forKey: "taskId")
                newManagedObject.setValue(taskType.rawValue, forKey: "taskType")
                newManagedObject.setValue(strSummary, forKey: "summary")
                newManagedObject.setValue(Date(), forKey: "createDt")
                newManagedObject.setValue(getTime(), forKey: "startTime")
                newManagedObject.setValue(getTime(), forKey: "endTime")
            }
        } else if strEntity == "TaskEvent" {
            if let appTaskId = dictData["appTaskId"] as? String, let eventDesc = dictData["eventDesc"] as? String {
                newManagedObject.setValue(UUID().uuidString, forKey: "eventId")
                newManagedObject.setValue(eventDesc, forKey: "eventDesc")
                newManagedObject.setValue(appTaskId, forKey: "appTaskId")
                newManagedObject.setValue(getTime(), forKey: "eventTime")
            }
        } else if strEntity == "Author" {
            if let strFName = dictData["fname"] as? String, let strLName = dictData["lname"] as? String, let strEmail = dictData["email"] as? String {
                newManagedObject.setValue(UUID().uuidString, forKey: "authorId")
                newManagedObject.setValue(Date(), forKey: "createDt")
                newManagedObject.setValue(strFName, forKey: "fname")
                newManagedObject.setValue(strLName, forKey: "lname")
                newManagedObject.setValue(strEmail, forKey: "email")
                newManagedObject.setValue("", forKey: "imgURL")
            }
        }
        
        saveContext(myMoc)
        
        let dictEntities =  fetchEntity(strEntity, ["hasPredicate":false])
        
        if let arrEntities = dictEntities["results"] as? Array<NSManagedObject>, let currentEntity = arrEntities.last {
            return currentEntity
        }
        
        return nil
        
    }
    
    func clearEntities(_ strEntity:String) {
        
        let myMoc = getManagedObjectContext()
        
        let dictResults = fetchEntity(strEntity, ["hasPredicate":false])
        if let arrResults =  dictResults["results"] as? Array<NSManagedObject> {
            for thisObj in arrResults {
                myMoc.delete(thisObj)
            }
        }
        
        saveContext(myMoc)
        
        if strEntity == "AppTask" {
            if let _ = createCoreDataEntry("AppTask", ["summary":"Flushed log", "taskType": TaskType.flushLog]) {
                saveContext(myMoc)
            }
        }
        
    }
    
    func saveContext(_ myMoc:NSManagedObjectContext) {
        
        if myMoc.hasChanges {
            print("viewContext has changes - try context.save()")
            do {
                try myMoc.save()
                print("viewContext saved changes")
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        } else {
            print("\n----> viewContext does not have changes")
        }
    }
    
    //MARK: - Validations
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    //MARK: - Date Management
    
    func getTime() -> String {
        
        let currentTime = Date()
        
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        
        return formatter.string(from: currentTime)
        
    }
    
    func convertDateToString(_ dtToConvert:Date, _ strip:Bool) -> String {
        
        var strDate = ""
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Define your desired date format here
        let dateString = dateFormatter.string(from: dtToConvert)
        
        if strip {
            strDate = String(dateString.split(separator: " ")[0])
        } else {
            strDate = dateString
        }
        
        return strDate
        
    }
    
    //MARK: - TextField Functions
    
    func setTextFieldHeight(_ strTextToUse: String, _ textFieldToUse:NSTextField) -> CGFloat {
            textFieldToUse.stringValue = strTextToUse
            let getnumber = textFieldToUse.cell!.cellSize(forBounds: NSMakeRect(CGFloat(0.0), CGFloat(0.0), textFieldToUse.frame.width, CGFloat(Float.greatestFiniteMagnitude))).height
            return getnumber
    }
}

