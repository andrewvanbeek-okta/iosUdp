//
//  nativeViewController.swift
//  TwelveTest
//
//  Created by Andrew Vanbeek on 5/11/19.
//  Copyright © 2019 Andrew Vanbeek. All rights reserved.
//

import Foundation
import UIKit
import OktaAuthSdk
import OktaOidc
import MaterialComponents
import KeychainAccess

class NativeViewController: UIViewController {
    
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var username: MDCTextField!
    @IBOutlet weak var password: MDCTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoBackground()
        setCustomLogo()
    }
    
    @IBAction func login(_ sender: Any) {
        var username = self.username.text
        var password = self.password.text
        nativeLogin(username: username ?? "username", password: password ?? "password")
    }
    
    func nativeLogin(username: String, password: String) {
        print(self.username.text)
        print(self.password.text)
        var keychain = self.getKeyChain()
        var url = keychain["oktaurl"] as! String
        var authObject = OktaAuthSdk.authenticate(with: URL(string: url)!,
                                                  username: username,
                                                  password: password,
                                                  onStatusChange: { OktaAuthStatus in
                                                    print(OktaAuthStatus.statusType.rawValue)
                                                    if(OktaAuthStatus.statusType.rawValue == "SUCCESS") {
                                                        print("gets here")
                                                        var okta = self.getOkta()
                                                        okta.authenticate(withSessionToken: OktaAuthStatus.model.sessionToken!) { stateManager, error in
                                                            if let error = error {
                                                                print(error)
                                                                return
                                                            }
                                                            print(OktaAuthStatus)
                                                            stateManager?.writeToSecureStorage()
                                                            print(stateManager?.accessToken)
                                                            print(stateManager?.idToken)
                                                            print(stateManager?.refreshToken)
                                                            var keychain = self.getKeyChain()
                                                            keychain["native"] = "yes"
                                                            self.performSegue(withIdentifier: "nativeSignIn", sender: nil)
                                                        }
                                                    } else {
                                                        var mfaStatus = OktaAuthStatus as! OktaAuthStatusFactorRequired
                                                        mfaStatus.selectFactor(mfaStatus.availableFactors[0], onStatusChange: { OktaAuthStatus in
                                                        
                                                        }, onError: { OktaError in
                                                            
                                                        })
                                                        var id = mfaStatus.availableFactors[0].factor.id as! String
                                                        var stateToken = mfaStatus.stateToken as String
                                                        OktaAuthStatus.restApi.verifyFactor(factorId: id, stateToken: stateToken)
                                                        
                                                    }
                                                
                                                    //print(OktaAuthStatus.model.sessionToken!)
                                                    
        },
                                                  onError: { error in
                                                    print(error)
        })
        
    }
    
    func setCustomLogo() {
        DispatchQueue.main.async(){
            var keychain = self.getKeyChain()
            print(keychain["image"])
            if(keychain["image"] != nil) {
                let url = URL(string: keychain["image"]!)
                self.logo.kf.setImage(with: url, placeholder: UIImage(named: "vanbeeklabs.png"))
            }
        }
    }
}
