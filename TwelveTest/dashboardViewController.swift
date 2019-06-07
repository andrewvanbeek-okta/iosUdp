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
        var config = self.getConfig()
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            print("no go")
            return
        }
        if(stateManager != nil) {
            if(!(stateManager.accessToken != nil)) {
                stateManager.clear()
                var oktaOidc = self.getOkta()
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
                    $0.title = "refresh"
                    }.onCellSelection {cell, row in
                        self.refresh(form: self.form, stateManger: stateManager)
                }
                section <<< ButtonRow() {
                    $0.title = "Update Email"
                    }.onCellSelection { cell, row in
                        let alert = SCLAlertView()
                        let txt = alert.addTextField("Enter your name")
                        var button = alert.addButton("Edit Email") {
                            self.changeEmail(email: txt.text!)
                        }
                        button.backgroundColor = UIColor.red
                        
                        alert.showEdit("Edit Your Email", subTitle: "Change your email", colorStyle: 0xd64541)
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
            if let error = error {
                // Error
                return
            }
            print("refresh")
            stateManger.getUser { response, error in
                if let error = error {
                    // Error
                    return
                }
                print(response)
                if(stateManger != nil) {
                    if(stateManger.accessToken != nil) {
                        DispatchQueue.main.async {
                            var responseObject = JSON(response)
                            var userInfo = responseObject.dictionaryValue
                            var keys = Array(userInfo.keys)
                            keys.forEach { item in
                                var row = form.rowBy(tag: item) as! TextRow
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
        
        var config = self.getConfig()
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            print("no go")
            return
        }
        self.isThereAccessToken()
        var accessToken = stateManager.accessToken
        var token = accessToken as! String
        var defEmail = email as! String
        var parameters = ["token": token, "email": defEmail]
        Alamofire.request("https://reset-password-okta.glitch.me/updateEmail", method: .post,parameters: parameters).responseJSON { response in
            if let json = response.result.value {
                var jsonObject = JSON(json)
                let alert = SCLAlertView()
                var links = jsonObject["_links"]
                var activateLink = links["activate"]
                var codeHref = activateLink["href"].stringValue
                print(codeHref)
                print(activateLink)
                let txt = alert.addTextField("Enter Code")
                var button = alert.addButton("Submit Code") {
                    self.submitCode(code: txt.text!, href: codeHref, email: email)
                }
                button.backgroundColor = UIColor.red
                alert.showEdit("Edit Your Email", subTitle: "Change your email", colorStyle: 0xd64541)
            }
        }
        
    }
    
    func submitCode(code: String, href: String, email: String) {
        
        var config = self.getConfig()
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            print("no go")
            return
        }
        var accessToken = stateManager.accessToken
        var token = accessToken as! String
        var code = code as! String
        var url = href.trimmingCharacters(in: .whitespaces)
        var parameters = ["token": token, "emailCode": code, "reqCodeLink": url, "email": email]
        Alamofire.request("https://reset-password-okta.glitch.me/updateEmail", method: .post,parameters: parameters).responseJSON { response in
            if let json = response.result.value {
                var jsonObject = JSON(json)
                print(jsonObject)
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                var jsonObject = JSON(response.data)
                //print(jsonObject.arrayValue)
            }
        }
        
        
        
    }
    
    
}

