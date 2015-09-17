//
//  DetailViewController.swift
//  xkcd
//
//  Created by Evan Salter on 2015-09-17.
//  Copyright (c) 2015 Evan Salter. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var imgView: UIImageView!
    
    var detailItem: Comic? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail: Comic = self.detailItem {
            if let url = NSURL(string: detail.imageLink) {
                if let data = NSData(contentsOfURL: url) {
                    if let image = UIImage(data: data) {
                        imgView?.image = image
                    }
                }
            }
        }
        
        imgView?.contentMode = UIViewContentMode.ScaleAspectFit
        
        self.title = detailItem?.number
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

