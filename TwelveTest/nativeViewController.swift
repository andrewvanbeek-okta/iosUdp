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
import SceneKit
import SCLAlertView
import Alamofire
import SwiftyJSON

class NativeViewController: UIViewController {
    
    @IBOutlet weak var loginBackDrop: UIView!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var username: MDCTextField!
    @IBOutlet weak var password: MDCTextField!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    var currentStatus: OktaAuthStatus?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoBackground()
        setCustomLogo()
        setCustomColor()
        self.username.textColor = UIColor.white
        self.username.font = UIFont(name: self.username.font!.fontName, size: 24)
        self.username.textAlignment = .center
        self.password.textColor = UIColor.white
        self.password.textAlignment = .center
        self.password.font = UIFont(name: self.username.font!.fontName, size: 24)
        self.username.placeholderLabel.textColor = UIColor.white
        self.username.placeholderLabel.highlightedTextColor = UIColor.white
        self.password.placeholderLabel.textColor = UIColor.white
        self.password.placeholderLabel.highlightedTextColor = UIColor.white
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
        
        OktaAuthSdk.authenticate(with: URL(string: url)!,
                                 username: username,
                                 password: password,
                                 onStatusChange: { authStatus in
                                    self.handleStatus(status: authStatus)
        },
                                 onError: { error in
                                    self.handleError(error)
        })
        
        
    }
    
    @IBOutlet weak var nativeSignInButton: UIButton!
    
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
                self.loginBackDrop.backgroundColor = self.hexStringToUIColor(hex: keychain["customcolor"]!)
                self.nativeSignInButton.backgroundColor = self.hexStringToUIColor(hex: keychain["customcolor"]!)
            }
        }
    }
    
    func handleStatus(status: OktaAuthStatus) {
        self.updateStatus(status: status)
        currentStatus = status
        
        switch status.statusType {
            
        case .success:
            let successState: OktaAuthStatusSuccess = status as! OktaAuthStatusSuccess
            print("GETS HERE")
        
            print("TEST")
            guard let sessionToken = successState.model.sessionToken else {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                print("here")
                self.handleSuccessStatus(sessionToken: sessionToken)
            }
            
        case .passwordWarning:
            let warningPasswordStatus: OktaAuthStatusPasswordWarning = status as! OktaAuthStatusPasswordWarning
            warningPasswordStatus.skipPasswordChange(onStatusChange: { status in
                self.handleStatus(status: status)
            }) { error in
                self.handleError(error)
            }
            
        case .passwordExpired:
            let expiredPasswordStatus: OktaAuthStatusPasswordExpired = status as! OktaAuthStatusPasswordExpired
            self.handleChangePassword(passwordExpiredStatus: expiredPasswordStatus)
            
        case .MFAEnroll:
            let mfaEnroll: OktaAuthStatusFactorEnroll = status as! OktaAuthStatusFactorEnroll
            self.handleEnrollment(enrollmentStatus: mfaEnroll)
            
        case .MFAEnrollActivate:
            let mfaEnrollActivate: OktaAuthStatusFactorEnrollActivate = status as! OktaAuthStatusFactorEnrollActivate
            self.handleActivateEnrollment(status: mfaEnrollActivate)
            
        case .MFARequired:
            let mfaRequired: OktaAuthStatusFactorRequired = status as! OktaAuthStatusFactorRequired
            self.handleFactorRequired(factorRequiredStatus: mfaRequired)
            
        case .MFAChallenge:
            let mfaChallenge: OktaAuthStatusFactorChallenge = status as! OktaAuthStatusFactorChallenge
            let factor = mfaChallenge.factor
            switch factor.type {
            case .sms:
                let smsFactor = factor as! OktaFactorSms
                self.handleSmsChallenge(factor: smsFactor, stateToken: mfaChallenge.stateToken)
            case .TOTP:
                let totpFactor = factor as! OktaFactorTotp
                self.handleTotpChallenge(factor: totpFactor)
            case .question:
                print("GETS HERE for Question")
                let questionFactor = factor as! OktaFactorQuestion
                self.handleQuestionChallenge(factor: questionFactor)
            case .push:
                let pushFactor = factor as! OktaFactorPush
                self.handlePushChallenge(factor: pushFactor)
            default:
                let alert = UIAlertController(title: "Error", message: "Recieved challenge for unsupported factor", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
                self.cancelTransaction()
            }
            
        case .recovery,
             .recoveryChallenge,
             .passwordReset,
             .lockedOut,
             .unauthenticated:
            let alert = UIAlertController(title: "Error", message: "No handler for \(status.statusType.rawValue)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            self.cancelTransaction()
            
        case .unknown(_):
            let alert = UIAlertController(title: "Error", message: "Recieved unknown status", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            self.cancelTransaction()
        }
    }
    
    
    func updateStatus(status: OktaAuthStatus?, factorResult: OktaAPISuccessResponse.FactorResult? = nil) {
        guard let status = status else {
            print("Unauthenticated")
            return
        }
        
        if let factorResult = factorResult {
           print("\(status.statusType.rawValue) \(factorResult.rawValue)")
        } else {
            print(status.statusType.rawValue)
        }
    }
    
    func handleSuccessStatus(sessionToken: String) {
        //UIActivityIndicatorView.stopAnimating()
        var oktaOidc = self.getOkta()
        oktaOidc.authenticate(withSessionToken: sessionToken) { stateManager, error in
            if let error = error {
                print(error)
                // Error
                return
            }
            print(stateManager?.accessToken)
            //stateManager.accessToken
            // stateManager.idToken
            // stateManager.refreshToken
            stateManager?.writeToSecureStorage()
            DispatchQueue.main.async(){
                var keychain = self.getKeyChain()
                keychain["native"] = "true"
                let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                if let viewController = mainStoryboard.instantiateViewController(withIdentifier: "dataTab") as? UITabBarController {
                    self.present(viewController, animated: true, completion: nil)
                }
            }
            
        
        }
    }
    
    func handleError(_ error: OktaError) {
       // UIActivityIndicatorView.stopAnimating()
        
        let alert = UIAlertController(title: "Error", message: error.description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func handleChangePassword(passwordExpiredStatus: OktaAuthStatusPasswordExpired) {
        let alert = UIAlertController(title: "Change Password", message: "Please choose new password", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Old Password" }
        alert.addTextField { $0.placeholder = "New Password" }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            guard let old = alert.textFields?[0].text,
                let new = alert.textFields?[1].text else { return }
            passwordExpiredStatus.changePassword(oldPassword: old,
                                                 newPassword: new,
                                                 onStatusChange: { status in
                                                    self.handleStatus(status: status)
            },
                                                 onError: { error in
                                                    self.handleError(error)
            })
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.cancelTransaction()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func handleFactorRequired(factorRequiredStatus: OktaAuthStatusFactorRequired) {
        updateStatus(status: factorRequiredStatus)
        
        let alert = UIAlertController(title: "Select verification factor", message: nil, preferredStyle: .actionSheet)
        print(factorRequiredStatus)
        let alertview = SCLAlertView()
        factorRequiredStatus.availableFactors.forEach { factor in
//            alert.addAction(UIAlertAction(title: factor.type.description, style: .default, handler: { _ in
//                factorRequiredStatus.selectFactor(factor,
//                                                  onStatusChange: { status in          print("#########")
//                                                    print(status)
//                                                    print("#########")
//
//                                                    self.handleStatus(status: status)
//                },
//                                                  onError: { error in
//                                                    print("#########")
//                                                    print(error)
//                                                    print("#########")
//                                                    self.handleError(error)
//                })
//            }))
         
            alertview.addButton(factor.type.rawValue) {
               print(factorRequiredStatus.stateToken)
              
                if(factor.type == .sms) {
                    var smsFactor = factor as! OktaFactorSms
                    smsFactor.select(onStatusChange: { status in
                        print("_______")
                        print(status)
                         print("_______")
                    }, onError: { error in
                        print(error)
                    })
                    self.handleSmsChallenge(factor: smsFactor, stateToken: factorRequiredStatus.stateToken)
                } else {
        
                    factor.select(onStatusChange: { status in
                        print(status)
                        self.handleStatus(status: status)
                    }, onError: { error in
                        print(error)
                    })
                }
           }
         
        }
        alertview.showEdit("Edit View", subTitle: "This alert view shows a text box")
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
//            self.cancelTransaction()
//        }))
//        present(alert, animated: true, completion: nil)
    }
    
    func handleEnrollment(enrollmentStatus: OktaAuthStatusFactorEnroll) {
        if enrollmentStatus.canSkipEnrollment() {
            enrollmentStatus.skipEnrollment(onStatusChange: { status in
                self.handleStatus(status: status)
            }) { error in
                self.handleError(error)
            }
            return
        }
        
        let alert = UIAlertController(title: "Select factor to enroll", message: nil, preferredStyle: .actionSheet)
        let factors = enrollmentStatus.availableFactors
        factors.forEach { factor in
            var title = factor.type.description
            if let factorStatus = factor.status {
                title = title + " - " + "(\(factorStatus))"
            }
            alert.addAction(UIAlertAction(title: title, style: .default, handler: { _ in
                if factor.type == .sms {
                    let smsFactor = factor as! OktaFactorSms
                    let alert = UIAlertController(title: "MFA Enroll", message: "Please enter phone number", preferredStyle: .alert)
                    alert.addTextField { $0.placeholder = "Phone" }
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        guard let phone = alert.textFields?[0].text else { return }
                        smsFactor.enroll(phoneNumber: phone,
                                         onStatusChange: { status in
                                            self.handleStatus(status: status)
                        },
                                         onError: { error in
                                            self.handleError(error)
                        })
                    }))
                    self.present(alert, animated: true, completion: nil)
                } else if factor.type == .push {
                    let pushFactor = factor as! OktaFactorPush
                    pushFactor.enroll(questionId: nil, answer: nil, credentialId: nil, passCode: nil, phoneNumber: nil, onStatusChange: { status in
                        self.handleStatus(status: status)
                    }, onError: { error in
                        self.handleError(error)
                    })
                } else {
                    let alert = UIAlertController(title: "Error", message: "No handler for \(factor.type.description) factor", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    self.cancelTransaction()
                }
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.cancelTransaction()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func handleActivateEnrollment(status: OktaAuthStatusFactorEnrollActivate) {
        let factor = status.factor
        guard factor.type == .sms ||
            factor.type == .push else {
                let alert = UIAlertController(title: "Error", message: "No handler for \(factor.type.description) factor", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                self.cancelTransaction()
                return
        }
        
        if factor.type == .sms {
            let smsFactor = factor as! OktaFactorSms
            
            let alert = UIAlertController(title: "MFA Activate", message: "Please enter code from SMS on \(smsFactor.phoneNumber ?? "?")", preferredStyle: .alert)
            alert.addTextField { $0.placeholder = "Code" }
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                guard let code = alert.textFields?[0].text else { return }
                status.activateFactor(passCode: code,
                                      onStatusChange: { status in
                                        self.handleStatus(status: status)
                },
                                      onError: { error in
                                        self.handleError(error)
                },
                                      onFactorStatusUpdate: { factorResult in
                                        self.updateStatus(status: self.currentStatus, factorResult: factorResult)
                })
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.cancelTransaction()
            }))
            present(alert, animated: true, completion: nil)
        }
        else {
            if status.factorResult == nil || status.factorResult == .waiting {
                status.activateFactor(passCode: nil, onStatusChange: { status in
                    self.handleStatus(status: status)
                }, onError: { error in
                    self.handleError(error)
                }) { factorResult in
                    self.updateStatus(status: status, factorResult: factorResult)
                }
            }
        }
    }
    
    func handleTotpChallenge(factor: OktaFactorTotp) {
        let alert = UIAlertController(title: "MFA", message: "Please enter TOTP code", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Code" }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak factor] action in
            guard let code = alert.textFields?[0].text else { return }
            factor?.verify(passCode: code,
                           onStatusChange: { status in
                            self.handleStatus(status: status)
            },
                           onError: { error in
                            self.handleError(error)
            },
                           onFactorStatusUpdate: { factorResult in
                            self.updateStatus(status: self.currentStatus, factorResult: factorResult)
            })
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.cancelTransaction()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func handleSmsChallenge(factor: OktaFactorSms, stateToken: String) {
            let alertview = SCLAlertView()
        let txt = alertview.addTextField("Enter Code")
        print(stateToken)
        alertview.addButton("Submit") {
            if(factor.links?.verify != nil) {
                var parameters = ["passCode": txt.text!, "stateToken": stateToken] as [String: String]
                var url = factor.links?.verify?.href.absoluteString as! String
                print(url)
                print(txt.text!)
                print(parameters)
                var headers = ["Accept": "application/json", "Content-Type": "application/json", "User-Agent": self.buildUserAgent()]
                Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                  print(response.result.value)
                    var fullResponse = JSON(response.result.value)
                    var sessionToken = fullResponse["sessionToken"].stringValue
                    self.handleSuccessStatus(sessionToken: sessionToken)
                }
                
            }
        }
        alertview.showEdit("Submit Code", subTitle: "This alert view shows a text box")
    }
    
    func handleQuestionChallenge(factor: OktaFactorQuestion) {
        let alert = UIAlertController(title: "MFA", message: "Please answer security question: \(factor.factorQuestionText ?? "?")", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Answer" }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak factor] action in
            guard let answer = alert.textFields?[0].text else { return }
            factor?.verify(answerToSecurityQuestion: answer,
                           onStatusChange: { status in
                            self.handleStatus(status: status)
            },
                           onError: { error in
                            self.handleError(error)
            },
                           onFactorStatusUpdate: { factorResult in
                            self.updateStatus(status: self.currentStatus, factorResult: factorResult)
            })
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.cancelTransaction()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func handlePushChallenge(factor: OktaFactorPush) {
        
        factor.verify(onStatusChange: { (status) in
            self.handleStatus(status: status)
        }, onError: { (error) in
            self.handleError(error)
        }) { _ in
            self.updateStatus(status: self.currentStatus)
        }
    }
    
    func cancelTransaction() {
        guard let status = currentStatus else {
            return
        }
        
        if status.canCancel() {
            status.cancel(onSuccess: {
                //self.activityIndicator.stopAnimating()
                //self.loginButton.isEnabled = true
                self.currentStatus = nil
                self.updateStatus(status: nil)
            }, onError: { error in
                self.handleError(error)
            })
        }
    }
    
    func buildUserAgent() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "?"
        let device = "Device/\(deviceModel())"
        #if os(iOS)
        let os = "iOS/\(UIDevice.current.systemVersion)"
        #elseif os(watchOS)
        let os = "watchOS/\(UIDevice.current.systemVersion)"
        #elseif os(tvOS)
        let os = "tvOS/\(UIDevice.current.systemVersion)"
        #elseif os(macOS)
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let os = "macOS/\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        #endif
        let string = "okta-auth-swift/\(version) \(os) \(device)"
        return string
    }
    
    func deviceModel() -> String {
        var system = utsname()
        uname(&system)
        let model = withUnsafePointer(to: &system.machine.0) { ptr in
            return String(cString: ptr)
        }
        return model
    }
    
}
