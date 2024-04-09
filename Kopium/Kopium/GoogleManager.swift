//
//  GoogleManager.swift
//  RFI-Reader
//
//  Created by Steve Suranie on 11/29/23.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST_Gmail
import GoogleAPIClientForREST_Drive

enum googleScope: String {
    case gMail = "https://www.googleapis.com/auth/gmail.modify"
    case gDrive = "https://www.googleapis.com/auth/drive"
    case gSheet = "https://www.googleapis.com/auth/spreadsheets.readonly"
}

class GoogleManager {
    
    let myAppManager = AppManager()
    var myViewController:ViewController!
    var currentUser:GIDGoogleUser?
    //let sheetService = GTLRSheetsService()
    let driveService = GTLRDriveService()
    let gmailService = GTLRGmailService()
    let strAPIKey = "AIzaSyApqe8mtK6I0XG5GTlx-oXpq0sNOJPVjoI"
    
    func signInToGoogle(completed: @escaping (returnBoolClosure)) {
        
        //store this in case we want to use it elsewhere
        var dictUser:Dictionary<String, Any> = [:]
        
        if let myViewController = self.myViewController {
            
            //sign in to google
            GIDSignIn.sharedInstance.signIn(
                withPresenting: myViewController.view.window!)  { signInResult, error in
                    
                    //if we signed in successfully do stuff
                    if let result = signInResult {
                        
                        //capture user data in case we want to use it later
                        //!!!!! - do not pass email or user id info to any backend servers - see Google docs for server token method
                        let user = result.user
                        dictUser["user"] = user
                        dictUser["emailAddress"] = user.profile?.email
                        dictUser["fullName"] = user.profile?.name
                        dictUser["givenName"] = user.profile?.givenName
                        dictUser["familyName"] = user.profile?.familyName
                        dictUser["profilePicUrl"] = user.profile?.imageURL(withDimension: 320)
                        dictUser["id"] = UUID().uuidString
                        
                        //determine what scopes are enabled by the user
                        let grantedScopes = user.grantedScopes
                        
                        //for some reason the scopes for the app were not granted to this user so we need to request them which requires another sign in.
                        if grantedScopes == nil || !grantedScopes!.contains(googleScope.gDrive.rawValue) || !grantedScopes!.contains(googleScope.gMail.rawValue) {
                            
                                //missing some scopes, ask the user if we can log in again to request them from Google
                            self.myAppManager.displayInfoAlert("The app needs to request access from Google to your Kargo GMail, GDrive and Google Sheets", myViewController, ["Okay", "Not Right Now"], true, response: {(bResponse:Bool) in
                                    
                                if bResponse {
                                    
                                    //log in again and request missing scopes
                                    let lstScopes = [googleScope.gDrive.rawValue, googleScope.gMail.rawValue, googleScope.gSheet.rawValue]
                                    guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
                                        print("There is an error with the user's sign in!")
                                        return ;  /* Not signed in. */
                                    }
                                    
                                    //call the addscopes function of the currentUser class, pass the array of scopes we need access to
                                    currentUser.addScopes(lstScopes, presenting: self.myViewController.view.window!) { signInResult, error in
                                        
                                        //check for errors
                                        guard error == nil else {
                                            print("There was an issue requesting the user's scopes from Google: \(String(describing: error?.localizedDescription as? String))")
                                            return
                                        }
                                        
                                        guard let signInResult = signInResult else {
                                            print("There was an error with the sign in process to add the scopes from Google.")
                                            return
                                        }
                                        
                                        //check if the scopes have been granted
                                        let user = signInResult.user
                                        let grantedScopes = user.grantedScopes
                                        if grantedScopes == nil || !grantedScopes!.contains(googleScope.gDrive.rawValue) || !grantedScopes!.contains(googleScope.gMail.rawValue) || !grantedScopes!.contains(googleScope.gSheet.rawValue){
                                            print("Something went wrong with getting the scopes. They are not in the user's grantedScopes property.")
                                        } else {
                                            let currentUser = GIDSignIn.sharedInstance.currentUser
                                        }
                                    }
                                }
                            })
                            
                        } else {
                            
                            guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
                                print("There is an error with the user's sign in!")
                                return ;  /* Not signed in. */
                            }
                            self.currentUser = currentUser
                            
                        }

                        if let strFullName = dictUser["fullName"] as? String {
                            //self.myAppManager.displayInfoAlert("You are logged in to Google \(strName)!", myViewController, [], false, response: {(bResponse:Bool) in })
                            self.myViewController.lblName.stringValue = "User: \(strFullName)"
//                            
//                            //TODO: figure out how to display the user image
//                            if let strPicURL = user.profile?.imageURL(withDimension: 320) as? Any {
//                                //print(strPicURL)
//                            }
                            
                            completed(true)
                        }
                    } else {
                        print(error)
                        self.myAppManager.displayInfoAlert("There was an error logging into Goggle and getting access to your Kargo Gmail, GDrive, and Google Sheets", myViewController, [], false, response: {(bResponse:Bool) in })
                    }
                       
                   
                }
        }
    }
    
    func getGmailList() {
        
        if let thisUser = currentUser as? GIDGoogleUser, let userId = thisUser.userID as? String {
            
            let listQuery = GTLRGmailQuery_UsersMessagesList.query(withUserId:userId)
            
            thisUser.refreshTokensIfNeeded { user, error in
                guard error == nil else { return }
                guard let user = user else { return }

                // Get the access token to attach it to a REST or gRPC request.
                let accessToken = user.accessToken.tokenString
                
                print(user)

                // Or, get an object that conforms to GTMFetcherAuthorizationProtocol for
                // use with GTMAppAuth and the Google APIs client library.
                //let authorizer = user.fetcherAuthorizer()
            }
//            let authentication = thisUser.authentication
//            let authorizer = GIDSignIn.sharedInstance.currentUser?.authentication?.fetcherAuthorizer()
//        gmailService.authorizer = authorizer
//
            gmailService.executeQuery(listQuery) { (ticket, response, error) in
                if response != nil {
                    print("Response: ")
                    print(response)
                } else {
                    print("Error: ")
                    print(error)
                }
            }
        }
    }
}
