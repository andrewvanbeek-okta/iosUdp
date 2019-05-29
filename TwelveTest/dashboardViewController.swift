//
//  oktaConfigForm.swift
//  TwelveTest
//
//  Created by Andrew Vanbeek on 5/14/19.
//  Copyright © 2019 Andrew Vanbeek. All rights reserved.
//

import Foundation
import Eureka
import KeychainAccess
import OktaOidc
import SwiftyJSON

class OktaDashboardViewController: FormViewController {
    
    struct FormItems {
        static let name = "name"
        static let firstname = "firstname"
        static let lastname = "lastname"
        static let email = "email"
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var config = self.getConfig()
        config.clientId
        var okta = self.getOkta()
        print(okta)
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            print("no go")
            return
        }
        print(config)
        stateManager.getUser { response, error in
            if let error = error {
                // Error
                return
            }
            print(response)
            DispatchQueue.main.async {
                var responsObject = JSON(response)
                var userInfo = responsObject.dictionaryValue
                var keys = Array(userInfo.keys)
                let section = Section()
                var header = HeaderFooterView<UIView>(.class)
                header.height = {300}
                header.onSetupView = { view, _ in
                    view.backgroundColor = .red
                    view.backgroundColor = UIColor(patternImage: UIImage(named: "userImage.png")!)
                }
                section.header = header
                self.form +++
                section
                keys.forEach { item in
                    section <<< TextRow(item) {
                        $0.title = item
                        $0.value = userInfo[item]?.rawString()
                    }
                }
                section <<< ButtonRow() {
                    $0.title = "Sign Out"
                    }.onCellSelection {  cell, row in
                        
                        var keychain = self.getKeyChain()
                        var isNative = keychain[string: "native"]
                        if(isNative != nil) {
                            self.performSegue(withIdentifier: "signOutFlow", sender: nil)
                        } else {
                            var oktaOidc = self.getOkta()
                            oktaOidc.signOutOfOkta(stateManager, from: self) { error in
                                print("NJANJSHBSHJNSJANJ")
                                if let error = error {
                                    print(error)
                                    return
                                }
                                print("GETS Here")
                                keychain["native"] = nil
                                DispatchQueue.main.async {
                                    let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                                    if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "MainVc") as? UIViewController {
                                        self.present(viewController, animated: true, completion: nil)
                                    }
                                }
                            }
                        }
                   
                }
            }
        }
    }
}

