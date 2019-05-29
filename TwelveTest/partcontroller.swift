//
//  partcontroller.swift
//  TwelveTest
//
//  Created by Andrew Vanbeek on 5/25/19.
//  Copyright © 2019 Andrew Vanbeek. All rights reserved.
//

import UIKit
import Cards
import Alamofire
import SwiftyJSON
import Kingfisher
import OktaOidc

class CardsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CardDelegate {
    
    var myArray = Array<Any>()
    var myTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height
        
        myTableView = UITableView(frame: CGRect(x: 0, y: barHeight, width: displayWidth, height: displayHeight - barHeight))
        myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
        myTableView.dataSource = self
        myTableView.delegate = self
        self.getData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.getData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Num: \(indexPath.row)")
        print("Value: \(myArray[indexPath.row])")
        self.getData()
        
    }
    
    func scrollToBottom(){
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.myArray.count-1, section: 0)
            self.myTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath as IndexPath)
        var height = self.view.frame.height / 4
        let card = CardHighlight(frame: CGRect(x: 10, y: 30, width: self.view.frame.width , height: height))
        card.shadowOpacity = 0
        card.cardRadius = 1
        card.buttonText = nil
        var data = JSON(myArray[indexPath.row])
        let url = URL(string: data["image_url"].stringValue.trimmingCharacters(in: .whitespaces))
        print(data.rawString())
        var imageView = UIImageView()
        imageView.kf.setImage(with: url!)
        card.icon = imageView.image
        card.backgroundColor = UIColor(red: 0, green: 94/255, blue: 112/255, alpha: 1)
        var keychain = self.getKeyChain()
        card.textColor = UIColor.white
        if(keychain["theme"] != nil) {
            var image = keychain["theme"]! + ".jpg"
            card.backgroundImage = UIImage(named: image)
        }
        card.title = data["slug"].stringValue
        card.hasParallax = true
        let cardContentVC = FullCardViewController()
        var trueObject = data.dictionaryValue
        cardContentVC.summaryObject = trueObject
        card.shouldPresent(cardContentVC, from: self, fullscreen: false)
        cell.addSubview(card)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         var height = self.view.frame.height / 3.5
        return height
    }
    
    func cardHighlightDidTapButton(_ card: CardHighlight, button: UIButton) {
        print("yaaaaa")
    }
    
    func getData() {
        var resource = self.getApi()
        Alamofire.request("https://vanbeeklabs-mobile.herokuapp.com/" + resource).responseJSON { response in
            print("Request: \(String(describing: response.request))")   // original url request
            print("Response: \(String(describing: response.response))") // http url response
            print("Result: \(response.result)")                         // response serialization result
            
            if let json = response.result.value {
                //print("JSON: \(json)") // serialized json response
                var jsonObject = JSON(json)
                var doctorArray = jsonObject.arrayValue
                DispatchQueue.main.async {
                self.myArray = doctorArray
                self.myTableView.reloadData()
                self.view.addSubview(self.myTableView)
                self.scrollToBottom()
                }
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                 var jsonObject = JSON(response.data)
                //print(jsonObject.arrayValue)
            }
        }
    }
}
