//
//  ViewController.swift
//  TwelveTest
//
//  Created by Andrew Vanbeek on 5/10/19.
//  Copyright © 2019 Andrew Vanbeek. All rights reserved.
//

import UIKit
import SwiftVideoBackground
import OktaOidc
import KeychainAccess
import Kingfisher
import Alamofire
import SwiftyJSON
import SCLAlertView

class ViewController: UIViewController {
    

    @IBOutlet weak var nativeSignIn: UIButton!
    @IBOutlet weak var logo: UIImageView!
    @IBAction func login(_ sender: Any) {
        var okta = self.getOkta()
        okta.signInWithBrowser(from: self) { stateManager, error in
            if let error = error {
                print(error)
                return
            }
           
            stateManager?.writeToSecureStorage()
            print(stateManager?.accessToken)
            print(stateManager?.idToken)
            print(stateManager?.refreshToken)
            DispatchQueue.main.async(){
                var keychain = self.getKeyChain()
                var sso = keychain["sso"] = "trueß"
                keychain["native"] = nil
                let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "dataTab") as? UITabBarController {
                    self.present(viewController, animated: true, completion: nil)
                }
            }
            
        }
    }
    
 
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        let keychain = self.getKeyChain()
        let config = self.getConfig()
        var sso = keychain["sso"]
        if(sso != nil) {
            guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
                return
            }
            print(stateManager.accessToken as Any)
            print(stateManager.idToken as Any)
            print(stateManager.refreshToken as Any)
            DispatchQueue.main.async(){
                let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "dataTab") as? UITabBarController {
                    self.present(viewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    
    @IBOutlet weak var signIn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        signIn.layer.cornerRadius = 4
        nativeSignIn.layer.cornerRadius = 4
        videoBackground()
        setCustomLogo()
        setCustomColor()
    }
    
    func setCustomLogo() {
        DispatchQueue.main.async(){
            let keychain = self.getKeyChain()
            print(keychain["image"] as Any)
            if(keychain["image"] != nil) {
                let url = URL(string: keychain["image"]!)
                self.logo.kf.setImage(with: url, placeholder: UIImage(named: "vanbeeklabs.png"))
                if(keychain["logoroundness"] != nil) {
                    self.logo.layer.masksToBounds = true
                    self.logo.layer.cornerRadius = CGFloat(Int(keychain["logoroundness"]!)! * 10)
                }
            } else {
                let url = URL(string: "https://www.okta.com/sites/all/themes/Okta/images/logos/developer/Dev_Logo-02_Large.png")
                self.logo.kf.setImage(with: url, placeholder: UIImage(named: "vanbeeklabs.png"))
                if(keychain["logoroundness"] != nil) {
                    self.logo.layer.masksToBounds = true
                    self.logo.layer.cornerRadius = CGFloat(Int(keychain["logoroundness"]!)! * 10)
                }
            }
        }
    }
    
    func setCustomColor() {
        DispatchQueue.main.async(){
            var keychain = self.getKeyChain()
            if(keychain["customcolor"] != nil) {
                self.signIn.backgroundColor = self.hexStringToUIColor(hex: keychain["customcolor"]!)
                self.nativeSignIn.backgroundColor = self.hexStringToUIColor(hex: keychain["customcolor"]!)
            }
        }
    }
    
    
}

extension UIViewController {
    func videoBackground() {
        var keychain = self.getKeyChain()
        if(keychain["theme"] == "Default") {
            let url = URL(string: "https://s3-us-west-2.amazonaws.com/appauth-mobile-app-media/city.mp4")!
            VideoBackground.shared.play(view: view, url: url)
        } else if(keychain["theme"] == "avbstyle") {
            let url = URL(string: "https://cdn.glitch.com/55304711-9aab-4c43-821d-f5cd02214e8c%2Fneon.mp4?1557543110884")!
            VideoBackground.shared.play(view: view, url: url)
        } else {
            self.addBackground()
        }
    }
    
    func addBackground() {
        var keychain = self.getKeyChain()
        if(keychain["theme"] != nil && keychain["theme"] != "Default") {
            var theme = keychain["theme"]! + ".jpg"
            print(theme)
            let width = UIScreen.main.bounds.size.width
            let height = UIScreen.main.bounds.size.height
            let imageViewBackground = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            imageViewBackground.image = UIImage(named: theme)
            print("HERE")
            imageViewBackground.contentMode = UIView.ContentMode.scaleAspectFill
            self.view.addSubview(imageViewBackground)
            self.view.sendSubviewToBack(imageViewBackground)
            
        } else {
            var theme = "travel.jpg"
            print(theme)
            let width = UIScreen.main.bounds.size.width
            let height = UIScreen.main.bounds.size.height
            let imageViewBackground = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            imageViewBackground.image = UIImage(named: theme)
            print("HERE")
            imageViewBackground.contentMode = UIView.ContentMode.scaleAspectFill
            self.view.addSubview(imageViewBackground)
            self.view.sendSubviewToBack(imageViewBackground)
            
        }
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
  
    
    func getOkta() -> OktaOidc {
        var config = {
            return try! OktaOidcConfig(with: [
                "issuer": "s",
                "clientId": "0oakkch04alb3cucj0h7",
                "redirectUri": "com.oktapreview.avb:/callback",
                "logoutRedirectUri": "com.oktapreview.avb:/callback",
                "scopes": "openid profile offline_access"
                ])
        }()
        var keychain = self.getKeyChain()
        if(keychain["url"] != nil) {
            config = {
                return try! OktaOidcConfig(with: [
                    "issuer": keychain["url"]!,
                    "clientId": keychain["clientId"]!,
                    "redirectUri": keychain["redirectUri"]!,
                    "logoutRedirectUri": keychain["logout"]!,
                    "scopes": "openid profile offline_access"
                    ])
            }()
        }
        
        var oktaOidc = {
            return try! OktaOidc(configuration: config)
        }()
        return oktaOidc
    }
    
    func getOktaWithIdp() -> OktaOidc {
        var keychain = self.getKeyChain()
        var config = {
            return try! OktaOidcConfig(with: [
                "issuer": "s",
                "clientId": "0oakkch04alb3cucj0h7",
                "redirectUri": "com.oktapreview.avb:/callback",
                "logoutRedirectUri": "com.oktapreview.avb:/callback",
                "scopes": "openid profile offline_access"
                ])
        }()
        if(keychain["url"] != nil && keychain["idp"] != nil) {
            config = {
                return try! OktaOidcConfig(with: [
                    "issuer": keychain["url"]!,
                    "clientId": keychain["clientId"]!,
                    "redirectUri": keychain["redirectUri"]!,
                    "logoutRedirectUri": keychain["logout"]!,
                    "scopes": "openid profile offline_access",
                    "idp": keychain["idp"]!
                    ])
            }()
        }
        
        var oktaOidc = {
            return try! OktaOidc(configuration: config)
        }()
        return oktaOidc
    }
    
    func getKeyChain() -> Keychain {
        return Keychain(service: "com.avbGame.TwelveTest")
    }
    
    func submitData(params: Dictionary<String, Any>) {
        var url = "https://vanbeeklabs-mobile.herokuapp.com"
        let parameters: Parameters = [
            "resource": "doctors"
        ]
        
        Alamofire.request(url,
                          method: .post,
                          parameters: params,
                          encoding: URLEncoding(destination: .queryString))
    }
    
    //get scratched
    func getApi() -> String {
        var keychain = self.getKeyChain()
        switch keychain["theme"] {
        case "travel":
            return "flights"
        case "healthcare":
            return "doctors"
        case "automative":
            return "cars"
        case .none:
            return "avb"
        case .some(_):
            return "avb"
        }
    }
    
    func getSecondConfig() -> OktaOidcConfig {
        var keychain = self.getKeyChain()
        var config = {
            return try! OktaOidcConfig(with: [
                "issuer": keychain["url"]!,
                "clientId": keychain["clientId"]!,
                "redirectUri": keychain["webappurl"] ?? "https://avb.oktapreview.com/home/salesforce/0oajpukin5uziKspL0h7/24?fromHome=true",
                "logoutRedirectUri": keychain["logout"]!,
                "scopes": "openid profile offline_access"
                ])
        }()
           return config
    }
    
    
    
    func ssoWebApp() {
        var config = self.getSecondConfig()
        var oktaOidc = {
            return try! OktaOidc(configuration: config)
        }()
        oktaOidc.signInWithBrowser(from: self) { stateManager, error in
            if let error = error {
                print(error)
                return
            }
        }
    }
    
    
    
    func getConfig() -> OktaOidcConfig {
        print("TEST")
        var config = {
            return try! OktaOidcConfig(with: [
                "issuer": "https://avb.oktapreview.com/oauth2/auskkfitx0l6SNY6R0h7",
                "clientId": "0oakkch04alb3cucj0h7",
                "redirectUri": "com.oktapreview.avb:/callback",
                "logoutRedirectUri": "com.oktapreview.avb:/callback",
                "scopes": "openid profile offline_access"
                ])
        }()
        var keychain = self.getKeyChain()
        if(keychain["url"] != nil) {
            config = {
                return try! OktaOidcConfig(with: [
                    "issuer": keychain["url"]!,
                    "clientId": keychain["clientId"]!,
                    "redirectUri": keychain["redirectUri"]!,
                    "logoutRedirectUri": keychain["logout"]!,
                    "scopes": "openid profile offline_access"
                    ])
            }()
            print(config)
            return config
        } else {
            print(config)
            return config
        }
        
    }
    
    
}



