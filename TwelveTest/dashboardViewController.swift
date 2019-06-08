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
import SCLAlertView
import Alamofire

class OktaDashboardViewController: FormViewController {
    
    struct FormItems {
        static let name = "name"
        static let firstname = "firstname"
        static let lastname = "lastname"
        static let email = "email"
    }
    
    func isThereAccessToken() {
        print("TEST TEST")
        let config = self.getConfig()
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            print("no go")
            return
        }
        if(stateManager != nil) {
            if(!(stateManager.accessToken != nil)) {
                stateManager.clear()
                let oktaOidc = self.getOkta()
                oktaOidc.signOutOfOkta(stateManager, from: self) { error in
                    if let error = error {
                        print(error)
                        return
                    }
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.isThereAccessToken()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isThereAccessToken()
        let config = self.getConfig()
        config.clientId
        let okta = self.getOkta()
        print(okta)
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            print("no go")
            return
        }
        print(config)
        stateManager.getUser { response, error in
            if error != nil {
                // Error
                return
            }
            print(response as Any)
            DispatchQueue.main.async {
                var responsObject = JSON(response as Any)
                var userInfo = responsObject.dictionaryValue
                let keys = Array(userInfo.keys)
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
                    $0.title = "refresh"
                    }.onCellSelection {cell, row in
                        self.refresh(form: self.form, stateManger: stateManager)
                }
                section <<< ButtonRow() {
                    $0.title = "Update Email"
                    }.onCellSelection { cell, row in
                        let alert = SCLAlertView()
                        let txt = alert.addTextField("Enter your name")
                        let button = alert.addButton("Edit Email") {
                            self.changeEmail(email: txt.text!)
                        }
                        button.backgroundColor = UIColor.red
                        
                        alert.showEdit("Edit Your Email", subTitle: "Change your email", colorStyle: 0xd64541)
                }
                section <<< ButtonRow() {
                    $0.title = "Sign Out"
                    }.onCellSelection {  cell, row in
                        
                        let keychain = self.getKeyChain()
                        let isNative = keychain[string: "native"]
                        if(isNative != nil) {
                            self.performSegue(withIdentifier: "signOutFlow", sender: nil)
                        } else {
                            let oktaOidc = self.getOkta()
                            oktaOidc.signOutOfOkta(stateManager, from: self) { error in
                                if let error = error {
                                    print(error)
                                    return
                                }
                                print("GETS Here")
                                keychain["native"] = nil
                                DispatchQueue.main.async {
                                    let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                                    stateManager.clear()
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
    
    func refresh(form: Form, stateManger: OktaOidcStateManager) {
        stateManger.renew { newAccessToken, error in
            if error != nil {
                // Error
                return
            }
            print("refresh")
            stateManger.getUser { response, error in
                if error != nil {
                    // Error
                    return
                }
                print(response as Any)
                if(stateManger != nil) {
                    if(stateManger.accessToken != nil) {
                        DispatchQueue.main.async {
                            var responseObject = JSON(response as Any)
                            var userInfo = responseObject.dictionaryValue
                            let keys = Array(userInfo.keys)
                            keys.forEach { item in
                                let row = form.rowBy(tag: item) as! TextRow
                                row.value = userInfo[item]?.rawString()
                                row.reload()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func changeEmail(email: String) {
        
        let config = self.getConfig()
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            print("no go")
            return
        }
        self.isThereAccessToken()
        let accessToken = stateManager.accessToken
        let token = accessToken as! String
        let defEmail = email
        let parameters = ["token": token, "email": defEmail]
        Alamofire.request("https://reset-password-okta.glitch.me/updateEmail", method: .post,parameters: parameters).responseJSON { response in
            if let json = response.result.value {
                var jsonObject = JSON(json)
                let alert = SCLAlertView()
                var links = jsonObject["_links"]
                var activateLink = links["activate"]
                let codeHref = activateLink["href"].stringValue
                print(codeHref)
                print(activateLink)
                let txt = alert.addTextField("Enter Code")
                let button = alert.addButton("Submit Code") {
                    self.submitCode(code: txt.text!, href: codeHref, email: email)
                }
                button.backgroundColor = UIColor.red
                alert.showEdit("Edit Your Email", subTitle: "Change your email", colorStyle: 0xd64541)
            }
        }
        
    }
    
    func submitCode(code: String, href: String, email: String) {
        
        let config = self.getConfig()
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            print("no go")
            return
        }
        let accessToken = stateManager.accessToken
        let token = accessToken as! String
        let code = code as! String
        let url = href.trimmingCharacters(in: .whitespaces) as! String
        let parameters = ["token": token, "emailCode": code, "reqCodeLink": url, "email": email]
        Alamofire.request("https://reset-password-okta.glitch.me/updateEmail", method: .post,parameters: parameters as Parameters).responseJSON { response in
            if let json = response.result.value {
                let jsonObject = JSON(json)
                print(jsonObject)
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                _ = JSON(response.data as Any)
                //print(jsonObject.arrayValue)
            }
        }
        
        
        
    }
    
    
}

