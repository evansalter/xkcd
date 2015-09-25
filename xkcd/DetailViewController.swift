//
//  DetailViewController.swift
//  xkcd
//
//  Created by Evan Salter on 2015-09-17.
//  Copyright (c) 2015 Evan Salter. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    // UIImageView to display the comic image
    @IBOutlet weak var imgView: UIImageView!
    // loading message to display when the view is loaded, while the comic downloads
    @IBOutlet weak var loadingLabel: UILabel!
    
    var detailItem: Comic? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        
        // prepare to download the image
        let detail: Comic = self.detailItem!
        let url = NSURL(string: detail.imageLink)
        let imageRequest: NSURLRequest = NSURLRequest(URL: url!)
        let queue: NSOperationQueue = NSOperationQueue.mainQueue()
        
        let reachability = Reachability.reachabilityForInternetConnection()
        if reachability?.isReachable() == true {
        
            // perform an asynchronous request for the image
            NSURLConnection.sendAsynchronousRequest(imageRequest, queue: queue, completionHandler: {response, imgData, error in
                
                if error == nil {
                    // once the image has loaded, hide the loading message
                    self.loadingLabel?.hidden = true
                    // present the image in the image view
                    let image = UIImage(data: imgData!)
                    self.imgView?.image = image
                }
                
                }
            )
            
            // scale the image up/down to fill as much of the screen as possible, without overlapping, while mainting the aspect ratio
            imgView?.contentMode = UIViewContentMode.ScaleAspectFit
            
            // set the title of the view to the comic number
            self.title = detailItem?.number
            
        }
        else {
            self.loadingLabel?.text = "No network connection..."
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // add a gestrure recognizer for a long press on the image view
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: "imageLongPressed:")
        imgView.addGestureRecognizer(gestureRecognizer)
        
        self.configureView()
        
    }
    
    /// Called when the image has been long-pressed
    func imageLongPressed(img: AnyObject) {
        // show the alt-text
        showAltText()
    }
    
    /// Presents an alert containing the comics alt-text
    func showAltText() {
        
        // conver the string to UTF8Encoding to ensure proper display
        let string = decodeString(detailItem!.alt)
        
        // initiate and present the alert
        let alertView = UIAlertController(title: nil, message: string, preferredStyle: UIAlertControllerStyle.Alert)
        alertView.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        
        self.presentViewController(alertView, animated: true, completion: nil)
        
    }
    
    /// Converts a given string to UTF8 encoding.
    /// 
    /// Useful when presenting data parsed from XML or HTML
    ///
    /// Prevents issues like quotation marks showing up as "&quot"
    /// 
    /// - parameters:
    ///     - string: `String` containing the message to be decoded
    /// - returns: `String` containing the decoded message
    func decodeString(string: String) -> String {
        
        let encodedData = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let attributedOptions : [String: AnyObject] = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
        ]
        let attributedString = try? NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
        let decodedString = attributedString!.string
        
        return decodedString
        
    }
    
    /// Presents the explainxkcd.com page for the current comic when the "Explain" button is pressed
    @IBAction func explainButtonPressed(sender: AnyObject) {
        
        let url = NSURL(string: "http://explainxkcd.com/wiki/index.php/" + (detailItem?.number)!)
        UIApplication.sharedApplication().openURL(url!)
        
    }
    
    /// Presents the attribution for the image when the "i" button is pressed
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
    
    /// Presents a share sheet when the share button is pressed
    @IBAction func shareButtonPressed(sender: AnyObject) {
        
        // share the URL, image, title, and alt-text
        let websiteToShare = NSURL(string: detailItem!.link)
        let imageToShare:UIImage = imgView.image!
        let title = detailItem?.title
        let alt = decodeString(detailItem!.alt)
        let textToShare = "\"" + title! + "\".  Alt-text: " + alt
        
        var objectsToShare = [AnyObject]()
        
        // add the share items to the array
        objectsToShare.append(imageToShare)
        objectsToShare.append(textToShare)
        objectsToShare.append(websiteToShare!)
        
        // initiate the present the share sheet
        let shareSheet = UIActivityViewController(activityItems:objectsToShare, applicationActivities: nil)
        
        self.presentViewController(shareSheet, animated: true, completion: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

