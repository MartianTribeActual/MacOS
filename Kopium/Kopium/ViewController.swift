//
//  ViewController.swift
//  Kopium
//
//  Created by Steve Suranie on 2/21/24.
//

import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var vHUD: NSView!
    @IBOutlet weak var puSource: NSPopUpButton!
    @IBOutlet weak var puTasks: NSPopUpButton!
    @IBOutlet weak var puDestination: NSPopUpButton!
    @IBOutlet weak var lblName: NSTextField!
    @IBOutlet weak var btnGoogleSignIn: NSButton!
    @IBOutlet weak var btnFullScreen: NSButton!
    @IBOutlet var myTextView: NSTextView!
    
    //author card ib outlets
    @IBOutlet weak var vAuthorCard: NSView!
    @IBOutlet weak var btnSaveAuthor: NSButton!
    @IBOutlet weak var btnEditAuthorImage: NSButton!
    @IBOutlet weak var imgAuthor: NSImageView!
    @IBOutlet weak var txtLName: NSTextField!
    @IBOutlet weak var txtFName: NSTextField!
    @IBOutlet weak var authorConstLeading: NSLayoutConstraint!
    @IBOutlet weak var btnCloseAuthorCard: NSButton!
    @IBOutlet weak var txtEmail: NSTextField!
    
    //data view outlets
    @IBOutlet weak var vData: NSView!
    @IBOutlet weak var vDataHud: NSView!
    @IBOutlet weak var btnViewLog: NSButton!
    @IBOutlet weak var btnCloseData: NSButton!
    @IBOutlet weak var tblData: NSTableView!
    @IBOutlet weak var lblDataViewTitle: NSTextField!
    @IBOutlet weak var dataConstLeading: NSLayoutConstraint!
    @IBOutlet weak var btnClearLog: NSButton!
    
    //log cards
    @IBOutlet weak var vLogCard: NSView!
    @IBOutlet weak var lblLogTitle: NSTextField!
    @IBOutlet weak var lblLogSummary: NSTextField!
    @IBOutlet weak var lblLogTimestamp: NSTextField!
    @IBOutlet weak var logCardConstraintTop: NSLayoutConstraint!
    @IBOutlet weak var btnCloseLogCard: NSButton!
    
    var currentTask:TaskType?
    var currentTaskId:String?
    var currentSource:Platform?
    var currentDestination:Platform?
    var myTableType:TableType?
    var arrTableData:Array<Dictionary<String, Any>>?
    
    //Managers
    let myGoogleManager = GoogleManager()
    let myKonnectManager = KonnectManager()
    let myConfluenceManager = ConfluenceManager()
    let myAppManager = AppManager()
    let myRootModel = RootModel()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //config views
        vHUD.wantsLayer = true
        vHUD.layer?.backgroundColor = NSColor(named: "kopium-mud")?.cgColor
        
        vAuthorCard.wantsLayer = true
        vAuthorCard.layer?.backgroundColor = NSColor(named: "kopium-sand")?.cgColor
        
        vDataHud.wantsLayer = true
        vDataHud.layer?.backgroundColor = NSColor(named: "kopium-sand")?.cgColor
        
        tblData.wantsLayer = true
        tblData.layer?.backgroundColor = NSColor(named: "kopium-text-lite")?.cgColor
        
        vLogCard.wantsLayer = true
        vLogCard.layer?.backgroundColor = NSColor(named: "kopium-green")?.cgColor
        
        //config pull downs
        puTasks.removeAllItems()
        puTasks.addItems(withTitles: ["Select A Task", "Create an Author", "Edit an Author", "Create Document", "Edit Document", "Get Directories", "Get Content List"])
        
        puSource.removeAllItems()
        puSource.addItems(withTitles: ["Select A Source", "Kargo Konnect", "Confluence", "Google", "ZenDesk"])
        
        puDestination.removeAllItems()
        puDestination.addItems(withTitles: ["Select A Destination", "Kargo Konnect", "Confluence", "Google", "ZenDesk"])
        
        //comfig table
        tblData.delegate = self
        tblData.dataSource = self
        tblData.usesAutomaticRowHeights = true
        removeAllColumns()
        
        //_ = myAppManager.createCoreDataEntry("AppTask", ["summary":"App started", "taskType": TaskType.appStarted])
        
    }
    
    @IBAction func toggleFullScreen(_ sender: Any) {
        
        if let window = self.view.window {
            
            let authCardFrame = vAuthorCard.frame
            
            window.toggleFullScreen(nil)
            let winFrame = window.frame
            
            authorConstLeading.constant = winFrame.size.width + 1.0
            vAuthorCard.frame = NSRect(x: winFrame.size.width + 1.0, y: authCardFrame.origin.y, width: authCardFrame.size.width, height: authCardFrame.size.height)
        }
    }

    //MARK: - Selection Functions
    
    @IBAction func selectionManager(_ sender: NSPopUpButton) {
        
        var bHasError = false
        
        //check for error
        if sender.indexOfSelectedItem == 0 && sender.tag < 3 {
            var strMsg = ""
            switch sender.tag {
            case 0:
                strMsg = "You did not select a task."
            case 1:
                strMsg = "You did not select a source."
            case 2:
                strMsg = "You did not select a destination."
            default:
                print("No worries")
            }
            
            bHasError = true
            myAppManager.displayInfoAlert(strMsg, self, [], false, response: {(bResponse:Bool) in })
        }
        
        //task selection
        if sender.tag == 0 && bHasError == false {
            
            //check to see if author card is open, close if it is
            if authorConstLeading.constant == 984.0 {
                animateView(vAuthorCard, authorConstLeading, 1)
            }
            
            //check if we are doing a non-writing task
            let arrNonWritingTasks = [TaskType.createAuthor.rawValue, TaskType.updateAuthor.rawValue, TaskType.readDirectory.rawValue, TaskType.getDirectories.rawValue]
            //non writing tasks
            if arrNonWritingTasks.contains(Int16(sender.indexOfSelectedItem)) {
                
                //update current task
                if sender.indexOfSelectedItem == 1 {
                    currentTask = TaskType.createAuthor
                } else if sender.indexOfSelectedItem == 2 {
                    currentTask = TaskType.updateAuthor
                } else if sender.indexOfSelectedItem == 5 {
                    currentTask = TaskType.getDirectories
                }
                
                //check to see if there are any authors
                if let currentTask = currentTask {
                    switch currentTask {
                    case .updateAuthor:
                        checkAuthorList(nil)
                    case .createAuthor:
                        
                        //start task
                        if let myTask = myAppManager.createCoreDataEntry("AppTask", ["summary":"Creating an author", "taskType": TaskType.createAuthor]), let myTaskId = myTask.value(forKey: "taskId") as? String {
                            
                            currentTaskId = myTaskId
                            animateView(vAuthorCard, authorConstLeading, 0)
                        }
                    case .getDirectories:
                        if currentSource != nil {
                            //start task
                            if let currentSource = currentSource, let myTask = myAppManager.createCoreDataEntry("AppTask", ["summary":"Reading \(currentSource.rawValue) directories", "taskType": TaskType.readDirectory]), let myTaskId = myTask.value(forKey: "taskId") as? String {
                                
                                //make a task event
                                if self.makeTaskEvent(myTaskId, "Calling Confuence API to get all spaces.") {
                                    myConfluenceManager.getAllSpaces(completed: {(arrResults:Array<Any>) in
                                        
                                        //pop out to main thread
                                        DispatchQueue.main.async {
                                            self.arrTableData = self.myRootModel.getSpaceData(arrResults)
                                            self.removeAllColumns()
                                            self.configTable(TableType.conSpaces)
                                        }
                                    })
                                }
                                
                            }
                        } else {
                            puTasks.selectItem(at: 0)
                            myAppManager.displayInfoAlert("You must select a source to read a directory or space.", self, [], false, response: {(bResponse:Bool) in })
                        }
                    default:
                        print("There was an error.")
                        
                    }
                }
                
            } else {
                
                if currentSource != nil && currentDestination != nil {
                    if sender.indexOfSelectedItem == 3 {
                        currentTask = TaskType.createDocument
                    } else if sender.indexOfSelectedItem ==  4 {
                        currentTask = TaskType.updateDocument
                    }
                } else {
                    myAppManager.displayInfoAlert("You cannot select a content related task without selecting a source and destination first.", self, [], false, response: {(bResponse:Bool) in })
                }
            }
        } else if sender.tag == 1 && bHasError == false {
            switch sender.indexOfSelectedItem {
                case 1: currentSource = Platform.konnect
                case 2: currentSource = Platform.confluence
                case 3: currentSource = Platform.google
                case 4: currentSource = Platform.zendesk
                default:
                    print("There was an error in selecting the source.")
            }
        } else if sender.tag == 2 && bHasError == false {
            switch sender.indexOfSelectedItem {
                case 1: currentDestination = Platform.konnect
                case 2: currentDestination = Platform.confluence
                case 3: currentDestination = Platform.google
                case 4: currentDestination = Platform.zendesk
                default:
                    print("There was an error in selecting the source.")
            }
        }
    }
    
//MARK: - Content Functions
    
    func listFiles(_ strDir: String) {
        
        clearTable()
        myTableType = .pagelist
        
        var bHasError = false
        
        if let currentSource = currentSource {
            if currentSource == .confluence {
                myConfluenceManager.getSpaceContent(strDir, completed: {(dictResults:Dictionary<String, Any>) in
                    self.arrTableData = self.myRootModel.getSpacePages(dictResults)
                    if let arrTableData = self.arrTableData {
                        if arrTableData.count > 0 {
                            DispatchQueue.main.async {
                                self.removeAllColumns()
                                self.configTable(TableType.pagelist)
                            }
                        } else {
                           bHasError = true
                        }
                    } else {
                        bHasError = true
                    }
                })
            }
        }
        
        if bHasError {
            self.myAppManager.displayInfoAlert("There was no content stored in this space.", self, [], false, response: {(bResponse:Bool) in })
        }
        
    }
    
    func getPageData(_ dictPage:Dictionary<String, Any>) {
        
        if let pageId = dictPage["id"] as? String, let pageTitle = dictPage["title"] as? String {
            myConfluenceManager.getPageContent(pageId, completed: {(dictResults:Dictionary<String, Any>) in
                if let dictData = dictResults["data"] as? Dictionary<String, Any>, let dictBody = dictData["body"] as?  Dictionary<String, Any>, let dictStorage = dictBody["storage"] as? Dictionary<String, Any>, let strValue = dictStorage["value"] as? String {
                    
                    //convert html to attributed string to display in text view
                    if let attributedString = try? NSAttributedString(data: strValue.data(using: .utf8)!,
                                                                               options: [.documentType: NSAttributedString.DocumentType.html],
                                                                      documentAttributes: nil) {
                        
                        DispatchQueue.main.async {
                            self.myTextView.textStorage?.setAttributedString(attributedString)
                        }
                    }
                } else {
                    self.myAppManager.displayInfoAlert("There was an issue getting the content for \(pageTitle)", self, [], false, response: {(bResponse:Bool) in })
                }
            })
        }
    }
    
//MARK: - Author Functions
    
    @IBAction func saveAuthor(_ sender: Any) {
        
        if let myTaskId = currentTaskId  {
            
            var myError = CustomError.noErrorDetected
            var strErr = ""
            
            //validate text entries
            if let _ = myAppManager.createCoreDataEntry("TaskEvent", ["appTaskId":myTaskId, "eventDesc": "Validating author form field entries."]) {
                
                if txtFName.stringValue.isEmpty || txtLName.stringValue.isEmpty || txtEmail.stringValue.isEmpty {
                    myError = CustomError.formEntryError
                    strErr += "You did not enter all the required information:\n\n"
                    
                    if txtFName.stringValue.isEmpty {
                        strErr += "You must enter a first name\n\n"
                    }
                    
                    if txtLName.stringValue.isEmpty {
                        strErr += "You must enter a last or family name\n\n"
                    }
                    
                    if txtEmail.stringValue.isEmpty {
                        strErr += "You must enter a valid email address\n\n"
                    }
                }
                
                if !txtEmail.stringValue.isEmpty {
                    //validate email
                    let bIsValidEmail = myAppManager.isValidEmail(txtEmail.stringValue)
                    if !bIsValidEmail {
                        myError = CustomError.formEntryError
                        strErr += "The email address you entered is not valid\n"
                    }
                }
                
                if myError == .formEntryError {
                    myAppManager.displayInfoAlert(strErr, self, [], false, response: {(bResponse:Bool) in })
                } else {
                    
                    //check if author exists already
                    if let thisTask = myAppManager.createCoreDataEntry("TaskEvent", ["appTaskId":myTaskId, "eventDesc": "Checking if author exists."]) {
                        checkAuthorList(["fname": txtFName.stringValue, "lname": txtLName.stringValue, "email": txtEmail.stringValue])
                    }
                    
//                    if let thisAuthor = myAppManager.createCoreDataEntry("Author", ["fname": txtFName.stringValue, "lname": txtLName.stringValue, "email": txtEmail.stringValue]) {
//                    }
                }
            }
        }
    }
    
    func checkAuthorList(_ dictAuthor:Dictionary<String, Any>?) {
        
        if dictAuthor == nil {
            
            let dictAuthors = myAppManager.fetchEntity("Author", ["hasPredicate":false])
            if let myError = dictAuthors["error"] as? CustomError {
                if myError == .dataFetchFailed {
                    let strAlertMsg = "There were no Authors found. Do you want to create an Author?"
                    myAppManager.displayInfoAlert(strAlertMsg, self, ["Yes", "No"], true, response: {(bResponse:Bool) in
                        if bResponse {
                            animateView(vAuthorCard, authorConstLeading, 0)
                        }
                    })
                } else {
                    
                }
            }
        } else {
            if let dictAuthor = dictAuthor as? Dictionary<String, Any>, let strFName = dictAuthor["fname"] as? String, let strLName = dictAuthor["lname"] as? String {
                
                //check if author already exists
                let fNamePredicate = NSPredicate(format: "fname = %@", strFName)
                let lNamePredicate = NSPredicate(format: "lname = %@", strLName)
                let myPredicate = NSCompoundPredicate.init(type: .and, subpredicates: [fNamePredicate,lNamePredicate])
                let dictResults = myAppManager.fetchEntity("Author", ["hasPredicated": true, "predicate":myPredicate])
                if let arrResults =  dictResults["results"] as? Array<NSManagedObject> {
                    for thisAuthor in arrResults {
                        if let thisAuthor = thisAuthor as? Author {
                            
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func closeAuthorCard(_ sender: Any) {
        animateView(vAuthorCard, authorConstLeading, 1)
    }
    
    //MARK: - Setting Source
    
    @IBAction func selectSource(_ sender: NSPopUpButton) {
        
        if sender.indexOfSelectedItem == 0 {
            myAppManager.displayInfoAlert("You did not select a source.", self, [], false, response: {(bResponse:Bool) in })
        } else {
            
        }
    }
    
    //MARK: - Log Functions
    
    func makeTaskEvent(_ taskId:String, _ taskEvenSummary:String) -> Bool{
        if let _ = myAppManager.createCoreDataEntry("TaskEvent", ["appTaskId":taskId, "eventDesc": taskEvenSummary]) {
            return true
        }
        
        return false
    }
    
    @IBAction func viewLog(_ sender: Any) {
        
        //change data view title
        lblDataViewTitle.stringValue = "Kopium Log"
        
        animateView(vData, dataConstLeading, 0)
        
        var arrData:Array<Dictionary<String, Any>> = [[:]]
        
        let dictEntities =  myAppManager.fetchEntity("AppTask", ["hasPredicate":false])
        if let arrResults = dictEntities["results"] as? Array<NSManagedObject> {
            
            for thisEntry in arrResults {
                if let taskId = thisEntry.value(forKey: "taskId") as? String, let strSummary = thisEntry.value(forKey: "summary") as? String, let createDt = thisEntry.value(forKey: "createDt"), let startTime = thisEntry.value(forKey:"startTime"), let endTime = thisEntry.value(forKey:"endTime"), let taskType = thisEntry.value(forKey: "taskType") {
                    
                    arrData.append(["summary":strSummary, "date": createDt, "start": startTime, "end": endTime, "tasktype":taskType])
                    
                    //fetch task events
                    let myPredicate = NSPredicate(format: "appTaskId = %@", taskId)
                    let dictEvents = myAppManager.fetchEntity("TaskEvent", ["hasPredicate":true, "predicate": myPredicate])
                    if let arrEvents = dictEvents["results"] as? Array<NSManagedObject> {
                        for thisEvent in arrEvents {
                            if let eventDesc = thisEvent.value(forKey:"eventDesc"), let eventTime = thisEvent.value(forKey: "eventTime") {
                                arrData.append(["summary":"Task events: \(eventDesc)", "date": createDt, "start": eventTime, "end": endTime])
                            }
                        }
                    }
                }
            }
        }
        
        arrTableData = arrData
        if  arrData.count > 0 {
            configTable(TableType.log)
            
        }
    }
    
    @IBAction func closeLogCard(_ sender: Any) {
        animateView(vLogCard, logCardConstraintTop, 1)
    }
    
    
    @IBAction func clearLog(_ sender: Any) {
        myAppManager.clearEntities("TaskEvent")
        myAppManager.clearEntities("AppTask")
    }
    
    @IBAction func closeDataView(_ sender: Any) {
        animateView(vData, dataConstLeading, 1)
    }
    
    func displayLogEntry(_ idx:Int) {
        
        if let arrTableData = arrTableData, let dictRowData = arrTableData[idx] as? Dictionary<String, Any>, let strSummary = dictRowData["summary"] as? String, let taskType = dictRowData["tasktype"] as? Int16, let dtCreated = dictRowData["date"] as? Date {
            
            let strType = myAppManager.getTaskType(taskType)
            let strDate = myAppManager.convertDateToString(dtCreated, false)
            lblLogTitle.stringValue = strType
            lblLogSummary.stringValue = strSummary
            lblLogTimestamp.stringValue = strDate
            
            print(arrTableData[idx])
        }
        
        
        animateView(vLogCard, logCardConstraintTop, 0)
    }
    
    //MARK: - Table Functions
    
    func clearTable() {
        if var arrTableData = arrTableData {
            arrTableData.removeAll()
            tblData.reloadData()
        }
    }
    
    func removeAllColumns() {
        // Loop through all columns and remove each one
        while let column = tblData.tableColumns.last {
            tblData.removeTableColumn(column)
        }
    }
    
    func configTable(_ tableType:TableType) {
        
        if tableType == .log {
            
            let column1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column1"))
            column1.title = "Date"
            column1.width = 75.0
            tblData.addTableColumn(column1)
            
            let column2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column2"))
            column2.title = "Summary"
            column2.width = 225.0
            tblData.addTableColumn(column2)
            
        } else if tableType == .conSpaces {
            
            let column1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column1"))
            column1.title = "Space"
            column1.width = 75.0
            tblData.addTableColumn(column1)
            
            let column2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column2"))
            column2.title = "Name"
            column2.width = 225.0
            tblData.addTableColumn(column2)
            
        } else if tableType == .pagelist {
            
            let column1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column1"))
            column1.title = "Title"
            column1.width = 300.0
            tblData.addTableColumn(column1)
            
        }
        
        myTableType = tableType
        tblData.reloadData()
        animateView(vData, dataConstLeading, 0)
        
    }
    func numberOfRows(in tableView: NSTableView) -> Int {
        if let arrTableData = arrTableData {
            print("Number of rows delegate datasource count: \(arrTableData.count)")
            return arrTableData.count
        }
        
        return 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard let dataCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "dataCell"), owner: self) as? DataTableCell else {
            return nil
        }
        
        if let myTableType = myTableType {
            
            if let colId = tableColumn?.identifier.rawValue as? String, let arrTableData = arrTableData {
                
                dataCell.textField?.isEditable = false
                dataCell.textField?.lineBreakMode = .byWordWrapping
                dataCell.textField?.cell?.wraps = true
                
                if arrTableData.count > 0 && row < arrTableData.count {
                    
                    let rowData = arrTableData[row]
                    
                    if myTableType == .log {
                        
                        if let myDate = rowData["date"] as? Date, let strSummary = rowData["summary"] as? String {
                            if colId == "Column1" {
                                dataCell.textField?.stringValue = myAppManager.convertDateToString(myDate, true)
                            } else if colId == "Column2"{
                                dataCell.textField?.stringValue = strSummary
                            }
                        }
                    } else if myTableType == .conSpaces {
                        
                        if let mySpace = rowData["key"] as? String, let myName = rowData["name"] as? String {
                            if colId == "Column1" {
                                dataCell.textField?.stringValue = mySpace
                            } else if colId == "Column2"{
                                dataCell.textField?.stringValue = myName
                            }
                        }
                    } else if myTableType == .pagelist {
                        if let myTitle = rowData["title"] as? String {
                            if colId == "Column1" {
                                dataCell.textField?.stringValue = myTitle
                            }
                        }
                    }
                } else {
                    dataCell.textField?.stringValue = ""
                }
                
                return dataCell
            }
        }
           
        return nil
        
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        let tableView = notification.object as! NSTableView
        
        if let myTableType = myTableType {
            
            switch myTableType {
                case .log:
                    displayLogEntry(tableView.selectedRow)
                case .conSpaces:
                    if let arrTableData = arrTableData {
                        let dictSpace = arrTableData[tableView.selectedRow]
                        if let strKey = dictSpace["key"] as? String {
                            listFiles(String(strKey))
                            animateView(vData, dataConstLeading, 1)
                        } else {
                            print("Could not get the key for the selected space.")
                        }
                    }
                case .pagelist:
                    if let arrTableData = arrTableData {
                        let dictPage = arrTableData[tableView.selectedRow]
                        getPageData(dictPage)
                    }
                default:
                    print("No options for \(myTableType.rawValue) yet.")
            }
        }
    }
    
    //MARK: - Animation Functions
    
    func animateView(_ viewToAnimate:NSView, _ constraintToChange:NSLayoutConstraint, _ animateType:Int) {
        
        //0 = open
        //1 = close
        var myConstant:CGFloat = 0
        if viewToAnimate == vAuthorCard {
            myConstant = 1200.0
            if animateType == 0 {
                myConstant = 984.0
            }
        } else if viewToAnimate == vData {
            myConstant = -300.0
            if animateType == 0 {
                myConstant = 0.0
            }
        } else if viewToAnimate == vLogCard {
            myConstant = 650.0
            if animateType == 1 {
                myConstant = 850.0
            }
        }
              
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.3 // Animation duration in seconds
            constraintToChange.animator().constant = myConstant // New constant value for the constraint
            viewToAnimate.layoutSubtreeIfNeeded() // Ensure all pending layout operations are completed
        }, completionHandler: nil)
    }
    
    

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

