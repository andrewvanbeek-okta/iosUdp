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
        let okta = self.getOkta()
        okta.signInWithBrowser(from: self) { stateManager, error in
            if let error = error {
                print(error)
                return
            }
            stateManager?.writeToSecureStorage()
            print(stateManager?.accessToken as Any)
            print(stateManager?.refreshToken as Any)
            stateManager?.writeToSecureStorage()
            DispatchQueue.main.async(){
                let keychain = self.getKeyChain()
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
        addBackground()
        setCustomLogo()
        let config = self.getConfig()
        guard OktaOidcStateManager.readFromSecureStorage(for: config) != nil else {
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
        let config = self.getConfig()
        guard OktaOidcStateManager.readFromSecureStorage(for: config) != nil else {
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
        let config = {
            return try! OktaOidcConfig(with: [
                "issuer": "https://pocrogers.okta.com/oauth2/default",
                "clientId": "0oanctypwoJ1xupFd356",
                "redirectUri": "com.okta.pocrogers:/callback",
                "logoutRedirectUri": "com.okta.pocrogers:/callback",
                "scopes": "openid profile offline_access"
                ])
        }()
        
        let oktaOidc = {
            return try! OktaOidc(configuration: config)
        }()
        return oktaOidc
    }
    
    func getKeyChain() -> Keychain {
        return Keychain(service: "com.avbGame.TwelveTest")
    }
    
    func getConfig() -> OktaOidcConfig {
        let config = {
            return try! OktaOidcConfig(with: [
                "issuer": "https://pocrogers.okta.com/oauth2/default",
                "clientId": "0oanctypwoJ1xupFd356",
                "redirectUri": "com.okta.pocrogers:/callback",
                "logoutRedirectUri": "com.okta.pocrogers:/callback",
                "scopes": "openid profile offline_access"
                ])
        }()
        return config
    }
    
    
}

