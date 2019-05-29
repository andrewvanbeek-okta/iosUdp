//
//  fullCardController.swift
//  TwelveTest
//
//  Created by Andrew Vanbeek on 5/26/19.
//  Copyright © 2019 Andrew Vanbeek. All rights reserved.
//

import Foundation
import Eureka
import KeychainAccess
import OktaOidc
import SwiftyJSON

class FullCardViewController: FormViewController, UITextViewDelegate, UITextFieldDelegate {
    
    struct FormItems {
        static let name = "name"
        static let firstname = "firstname"
        static let lastname = "lastname"
        static let email = "email"
    }
    
     var summaryObject: Dictionary = [String: Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
            DispatchQueue.main.async {
                
                TextAreaRow.defaultCellSetup = { cell, row in
                    cell.textView.delegate = self
                    cell.textView.sizeToFit()
                }
                
                var responsObject = JSON(self.summaryObject)
                var userInfo = responsObject.dictionaryValue
                userInfo.removeValue(forKey: "image_url")
                var keys = Array(userInfo.keys)
                let section = Section()
                self.form +++
                section
                keys.forEach { item in
                    var txtValue = userInfo[item]?.rawString()
                    if(txtValue!.count < 15) {
                        section <<< TextRow(item) {
                            $0.title = item
                            $0.value = userInfo[item]?.rawString()
                            $0.baseCell.isUserInteractionEnabled = false
                        }
                    } else {
                        section <<< TextAreaRow(item) {
                            $0.title = item
                            $0.value = item + ": " + (userInfo[item]?.rawString())!
                            $0.cell.sizeToFit()
                            $0.baseCell.sizeToFit()
                        }
                    }
                }
                section <<< ButtonRow() {
                    $0.title = "Save"
                    }.onCellSelection {  cell, row in
                    self.addDataToUser()
                }
            }
        
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
    
    func addDataToUser() {
        var config = self.getConfig()
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            print("no go")
            return
        }
        stateManager.getUser { response, error in
            if let error = error {
                // Error
                return
            }
            print("TEST!!!!!!!!!!!!!!!!!!!!!!!!!!!")
            var oktaUser = JSON(response)
            var userSub = oktaUser["sub"].stringValue
            var resource = self.getApi()
            var parameters = ["userId": userSub, "resource": resource, "token": stateManager.accessToken!] as Dictionary<String, Any>
            var responsObject = JSON(self.summaryObject)
            var userInfo = responsObject.dictionaryValue
            parameters["data"] = userInfo
            self.submitData(params: parameters)
            print("TEST!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        }
    }
}
