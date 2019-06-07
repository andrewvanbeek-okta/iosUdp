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

class ViewController: UIViewController {
    
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
            print(stateManager?.refreshToken)
            stateManager?.writeToSecureStorage()
            DispatchQueue.main.async(){
                var keychain = self.getKeyChain()
                keychain["native"] = nil
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
        videoBackground()
        setCustomLogo()
        var config = self.getConfig()
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            return
        }
        DispatchQueue.main.async(){
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "dataTab") as? UITabBarController {
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        var config = self.getConfig()
        guard let stateManager = OktaOidcStateManager.readFromSecureStorage(for: config) else {
            return
        }
        DispatchQueue.main.async(){
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "dataTab") as? UITabBarController {
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }
    
   
    
    func setCustomLogo() {
        DispatchQueue.main.async(){
            self.logo.image = nil
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
            let width = UIScreen.main.bounds.size.width
            let height = UIScreen.main.bounds.size.height
            let imageViewBackground = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            let url = URL(string: "https://cdn.glitch.com/55304711-9aab-4c43-821d-f5cd02214e8c%2Fmyrogers.png")
            imageViewBackground.kf.setImage(with: url, placeholder: UIImage(named: "automative.jpg"))
            imageViewBackground.contentMode = UIView.ContentMode.scaleAspectFill
            self.view.addSubview(imageViewBackground)
            self.view.sendSubviewToBack(imageViewBackground)
        
    }
    
    
    func getOkta() -> OktaOidc {
        var config = {
            return try! OktaOidcConfig(with: [
                "issuer": "https://esfdevapi.rogers-poc.com/oauth2/ausnwvaq3hnainCu3356",
                "clientId": "0oanctypwoJ1xupFd356",
                "redirectUri": "com.okta.pocrogers:/callback",
                "logoutRedirectUri": "com.okta.pocrogers:/callback",
                "scopes": "openid profile offline_access"
                ])
        }()
        
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
    
    
    
    
    
    func getConfig() -> OktaOidcConfig {
        var config = {
            return try! OktaOidcConfig(with: [
                "issuer": "https://esfdevapi.rogers-poc.com/oauth2/ausnwvaq3hnainCu3356",
                "clientId": "0oanctypwoJ1xupFd356",
                "redirectUri": "com.okta.pocrogers:/callback",
                "logoutRedirectUri": "com.okta.pocrogers:/callback",
                "scopes": "openid profile offline_access"
                ])
        }()
        return config
    }
    
    
}

