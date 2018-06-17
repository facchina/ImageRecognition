//
//  FinalViewController.swift
//  ImageRecognition
//
//  Created by Mariana Facchina on 15/06/2018.
//  Copyright © 2018 facchina. All rights reserved.
//

import Foundation
import UIKit
class FinalViewController : UIViewController {
    var winner : Int!
    
    @IBOutlet weak var winnerLbl: UILabel!
    
    override func viewDidLoad() {
        switch winner {
        case 1:
            winnerLbl.text = "Player Victory"
        case -1:
            winnerLbl.text = "Computer Victory"
        default:
            winnerLbl.text = "Draw Game"
        }
    }
}
