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
    @IBOutlet weak var loadingLabel: UILabel!
    
    var detailItem: Comic? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        
        let detail: Comic = self.detailItem!
        let url = NSURL(string: detail.imageLink)
        let imageRequest: NSURLRequest = NSURLRequest(URL: url!)
        let queue: NSOperationQueue = NSOperationQueue.mainQueue()
        
        NSURLConnection.sendAsynchronousRequest(imageRequest, queue: queue, completionHandler: {_, imgData, _ in
            
                self.loadingLabel?.hidden = true
                let image = UIImage(data: imgData)
                self.imgView?.image = image
                    
            }
        )
        
        imgView?.contentMode = UIViewContentMode.ScaleAspectFit
        
        self.title = detailItem?.number
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        var gestureRecognizer = UILongPressGestureRecognizer(target: self, action: "imageLongPressed:")
        imgView.addGestureRecognizer(gestureRecognizer)
        
        self.configureView()
        
    }
    
    func imageLongPressed(img: AnyObject) {
        showAltText()
    }
    
    func showAltText() {
        
        let string = decodeString(detailItem!.alt)
        
        let alertView = UIAlertController(title: nil, message: string, preferredStyle: UIAlertControllerStyle.Alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        
        self.presentViewController(alertView, animated: true, completion: nil)
        
    }
    
    func decodeString(string: String) -> String {
        
        let encodedData = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let attributedOptions : [String: AnyObject] = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
        ]
        let attributedString = NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil, error: nil)
        let decodedString = attributedString!.string
        
        return decodedString
        
    }
    
    @IBAction func infoButtonPressed(sender: AnyObject) {
                
        let url = detailItem?.link
        
        let message = "This image is used under CC BY-NC 2.5 and is taken from " + url!
        
        let alertView = UIAlertController(title: "Attribution", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        let URLAction = UIAlertAction(title: "Visit Website", style: UIAlertActionStyle.Default) { value in
            UIApplication.sharedApplication().openURL(NSURL(string: url!)!)
        }
        
        alertView.addAction(OKAction)
        alertView.addAction(URLAction)
        
        self.presentViewController(alertView, animated: true, completion: nil)
        
    }
    
    @IBAction func shareButtonPressed(sender: AnyObject) {
        
        let websiteToShare = NSURL(string: detailItem!.link)
        let imageToShare:UIImage = imgView.image!
        let title = detailItem?.title
        let alt = decodeString(detailItem!.alt)
        let textToShare = "\"" + title! + "\".  Alt-text: " + alt
        
        var objectsToShare = [AnyObject]()
        
        objectsToShare.append(imageToShare)
        objectsToShare.append(textToShare)
        objectsToShare.append(websiteToShare!)
        
        let shareSheet = UIActivityViewController(activityItems:objectsToShare, applicationActivities: nil)
        
        self.presentViewController(shareSheet, animated: true, completion: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

