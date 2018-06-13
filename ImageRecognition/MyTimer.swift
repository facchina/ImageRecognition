//
//  Timer.swift
//  ImageRecognition
//
//  Created by Magno Augusto Ferreira Ruivo on 10/06/2018.
//  Copyright © 2018 facchina. All rights reserved.
//

import Foundation
import UIKit

class MyTimer: UIViewController {
    
    var array = ["pedra", "papel", "tesoura"]
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var button: UIButton!
    
    var myTimer = Timer()
    var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func Play(sender: AnyObject){
        myTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(increment), userInfo: nil, repeats: true)

        
    }
    
    @objc func increment(){
        count += 1
        label.text = String(count)
        check()
        
    }
    
    func check (){
        if(count == 3){
            myTimer.invalidate()
            count = 0
            label2.text = array[Int(arc4random_uniform(UInt32(array.count)))]
        }
    }
}
