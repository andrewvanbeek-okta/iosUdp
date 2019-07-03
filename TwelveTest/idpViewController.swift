//
//  idpViewController.swift
//  TwelveTest
//
//  Created by Andrew Vanbeek on 7/2/19.
//  Copyright © 2019 Andrew Vanbeek. All rights reserved.
//

import Foundation
import UIKit

class IdpController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let myArray: NSArray = ["SignInWithAppleButton.png","SignInWithGoogleButton.png","SignInWithFacebookButton.png", "SignInWithGithubButton.png"]
    private var myTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height
        
        myTableView = UITableView(frame: CGRect(x: 0, y: barHeight, width: displayWidth, height: displayHeight - barHeight))
        myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
        myTableView.dataSource = self
        myTableView.delegate = self
        self.view.addSubview(myTableView)
        myTableView.backgroundColor = UIColor.clear
        self.addBackground()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Num: \(indexPath.row)")
        print("Value: \(myArray[indexPath.row])")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath as IndexPath)
        cell.layer.backgroundColor = UIColor.clear.cgColor
        cell.backgroundColor = UIColor.clear
        var buttonImage = myArray[indexPath.row]
        let button = ButtonWithImage(frame: CGRect(x: cell.contentView.center.x, y: cell.contentView.center.y, width: cell.contentView.frame.width / 2, height: cell.contentView.frame.height * 0.5))
        button.center = cell.contentView.center
        var height = cell.contentView.frame.height
        var width = cell.contentView.frame.width
        let imageViewBackground = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        button.setImage(UIImage(named: buttonImage as! String), for: .normal)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width
        cell.contentView.addSubview(button)
        return cell
    }
}

class ButtonWithImage: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        if imageView != nil {
//            imageEdgeInsets = UIEdgeInsets(top: 5, left: (bounds.width - 35), bottom: 5, right: 5)
//            titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: (imageView?.frame.width)!)
//        }
    }
}
