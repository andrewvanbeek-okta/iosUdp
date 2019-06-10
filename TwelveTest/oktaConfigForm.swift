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

class OktaFormViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var keychain = self.getKeyChain()
        form +++ Section("Section1")
            <<< TextRow("url"){ row in
                row.title = "full okta issuer url"
                row.placeholder = "Enter url here"
                row.add(rule: RuleRequired())
            }
            <<< TextRow("clientId"){ row in
                row.title = "client id"
                row.placeholder = "Enter client id"
                row.add(rule: RuleRequired())
            }
            <<< TextRow("redirectUri"){ row in
                row.title = "enter the redirect uri"
                row.placeholder = "Enter the redirect uri"
                row.add(rule: RuleRequired())
            }
            <<< TextRow("logoutUri"){ row in
                row.title = "enter the logout uri"
                row.placeholder = "Enter the redirect uri"
                row.add(rule: RuleRequired())
            }
            <<< TextRow("oktaurl"){ row in
                row.title = "url of your okta"
                row.add(rule: RuleRequired())
                row.placeholder = "Enter url"
            }
            <<< TextRow("customScopes"){ row in
                row.title = "custom scopes"
                row.placeholder = "Enter custom scopes"
            }
            <<< TextRow("customlogo"){ row in
                row.title = "custom logo url"
                row.placeholder = "Enter image url"
            }
            <<< TextRow("custombackground"){ row in
                row.title = "custom background url"
                row.placeholder = "Enter image url"
            }
            <<< TextRow("customcolor"){ row in
                row.title = "custom color hex"
                row.placeholder = "Enter color hex"
            }
            <<< ActionSheetRow<String>("theme") {
                $0.title = "Theme"
                $0.selectorTitle = "Pick a number"
                $0.options = ["healthcare","automative", "travel", "Default", "avbstyle"]
                $0.value = "Default"    // initially selected
            }
        <<< SliderRow("logoroundness") { row in      // initializer
            row.title = "Slider Row"
            row.value = 10.0
            }.onChange { row in
                var intValue = Int(row.value!)
                keychain["logoroundness"] = String(intValue)
            }
            <<< ButtonRow(){
                $0.title = "Set"
                }.onCellSelection {  cell, row in
                    print("TEST")
                    var validate = self.form.validate()
                    if(validate.count > 0) {
                        let emptyAlert = UIAlertController(title: nil, message: "Fill all fields!", preferredStyle: .alert)
                        emptyAlert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default,handler: nil))
                        self.present(emptyAlert, animated: true, completion: nil)
                    } else {
                        self.updateKeychain()
                    }
        }
        self.updateOktaValues()
    }
    
    func checkConfig() {
        
    }
    
    func updateKeychain() {
        if let urlRow = self.form.rowBy(tag: "url") as? RowOf<String>,
            let clientIdRow = self.form.rowBy(tag: "clientId") as? RowOf<String>,
            let redirectRow = self.form.rowBy(tag: "redirectUri") as? RowOf<String>,
            let logoutRow = self.form.rowBy(tag: "logoutUri") as? RowOf<String>,
            let oktaUrlRow = self.form.rowBy(tag: "oktaurl") as? RowOf<String>,
            let imageUrlRow = self.form.rowBy(tag: "customlogo") as? RowOf<String>,
            let themeRow = self.form.rowBy(tag: "theme") as? RowOf<String>,
            let backgroundRow = self.form.rowBy(tag: "custombackground") as? RowOf<String>,
            let colorRow = self.form.rowBy(tag: "customcolor") as? RowOf<String>
        {
            var keychain = self.getKeyChain()
            keychain["url"] = urlRow.value!.trimmingCharacters(in: .whitespaces)
            keychain["clientId"] = clientIdRow.value!.trimmingCharacters(in: .whitespaces)
            keychain["oktaurl"] = oktaUrlRow.value!.trimmingCharacters(in: .whitespaces)
            keychain["redirectUri"] = redirectRow.value!.trimmingCharacters(in: .whitespaces)
            keychain["logout"] = logoutRow.value!.trimmingCharacters(in: .whitespaces)
            if(imageUrlRow.value != nil) {
                keychain["image"] = imageUrlRow.value!.trimmingCharacters(in: .whitespaces)
            }
            if(themeRow.value != nil) {
                keychain["theme"] = themeRow.value
            }
            if(backgroundRow.value != nil) {
                keychain["custombackground"] = backgroundRow.value!.trimmingCharacters(in: .whitespaces)
            }
            if(colorRow.value != nil) {
                keychain["customcolor"] = colorRow.value!.trimmingCharacters(in: .whitespaces)
            }
        }
    }
    
    func updateOktaValues() {
        if let urlRow = self.form.rowBy(tag: "url") as? RowOf<String>,
            let clientIdRow = self.form.rowBy(tag: "clientId") as? RowOf<String>,
            let redirectRow = self.form.rowBy(tag: "redirectUri") as? RowOf<String>,
            let logoutRow = self.form.rowBy(tag: "logoutUri") as? RowOf<String>,
            let oktaUrlRow = self.form.rowBy(tag: "oktaurl") as? RowOf<String>,
            let imageUrlRow = self.form.rowBy(tag: "customlogo") as? RowOf<String>,
            let themeRow = self.form.rowBy(tag: "theme") as? RowOf<String>,
            let backgroundRow = self.form.rowBy(tag: "custombackground") as? RowOf<String>,
            let colorRow = self.form.rowBy(tag: "customcolor") as? RowOf<String>,
            let roundnessRow = self.form.rowBy(tag: "logoroundness") as? SliderRow
        {
            
            var keychain = self.getKeyChain()
            if(keychain["url"] != nil) {
                urlRow.value = keychain["url"] as! String
                clientIdRow.value = keychain["clientId"] as! String
                redirectRow.value = keychain["redirectUri"] as! String
                logoutRow.value = keychain["logout"] as! String
                if(keychain["oktaurl"] != nil) {
                    oktaUrlRow.value = keychain["oktaurl"] as! String
                }
                if(keychain["image"] != nil) {
                    imageUrlRow.value = keychain["image"]!.trimmingCharacters(in: .whitespaces)
                }
                if(keychain["theme"] != nil) {
                    themeRow.value = keychain["theme"] as! String
                }
                if(keychain["custombackground"] != nil) {
                    backgroundRow.value = keychain["custombackground"] as! String
                }
                if(keychain["customcolor"] != nil) {
                    colorRow.value = keychain["customcolor"] as! String
                }
                if(keychain["logoroundness"] != nil) {
                    var int = Int(keychain["logoroundness"]!)
                    var float = Float(int!)
                    roundnessRow.value = float
                }
                urlRow.reload()
                clientIdRow.reload()
                redirectRow.reload()
                logoutRow.reload()
                oktaUrlRow.reload()
                backgroundRow.reload()
                //colorRow.reload()
                
            }
        }
    }
}
