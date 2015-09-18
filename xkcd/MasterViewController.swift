//
//  MasterViewController.swift
//  xkcd
//
//  Created by Evan Salter on 2015-09-17.
//  Copyright (c) 2015 Evan Salter. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, NSXMLParserDelegate {
    
    // **************************
    // MARK: - Instance Variables
    // **************************
    
    var objects = [AnyObject]()
    
    // XML parser object to parse RSS feed
    var xmlParser: NSXMLParser!
    
    var searchComic: Comic = Comic()


    // ******************
    // MARK: - View Setup
    // ******************
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        var refreshControl = UIRefreshControl()
        
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        startLoading()
        
        // parse RSS
        getRSS()
        
    }
    
    func refresh(sender: AnyObject) {
        
        self.objects.removeAll(keepCapacity: true)

        self.refreshControl?.endRefreshing()
        self.startLoading()
        getRSS()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        objects.insert(NSDate(), atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    @IBAction func searchButtonPressed(sender: AnyObject) {
        
        let alertController = UIAlertController(title: "Find Comic", message: "Enter the number of the comic to open:", preferredStyle: .Alert)
        
        let submitAction = UIAlertAction(title: "Submit", style: .Default) { (_) in
            
            let comicField = alertController.textFields![0] as! UITextField
            
            self.searchForComicByNumber(comicField.text)
            
        }
        
        submitAction.enabled = false
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            
            textField.placeholder = "Comic number"
            
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                submitAction.enabled = textField.text != ""
            }
            
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    func searchForComicByNumber(string: String) {
        
        let urlString = NSURL(string: "http://xkcd.com/" + string)
        let urlRequest = NSURLRequest(URL: urlString!)
        let queue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: queue) {
            (response, data, error) -> Void in
            let stringData = NSString(data: data, encoding: NSUTF8StringEncoding)

            if(stringData!.length < 400){
                self.invalidNumberError(string)
            }
            else {
                let comic = Comic()
                comic.link = urlString!.description
                comic.number = string
                let arrayOfImgSrc:[NSString] = stringData?.componentsSeparatedByString("<img src=\"//") as! [NSString]
                let comicInfo = arrayOfImgSrc[2]
                let arrayOfComicInfo = comicInfo.componentsSeparatedByString("\"")
                comic.imageLink = "http://" + (arrayOfComicInfo[0] as! String)
                comic.title = arrayOfComicInfo[4] as! String
                comic.alt = arrayOfComicInfo[2] as! String
                comic.description = ""
                comic.date = ""
                
                self.searchComic = comic
            
                let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                dispatch_async(dispatch_get_global_queue(priority, 0)) {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        self.performSegueWithIdentifier("showDetailManual", sender: self)
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func invalidNumberError(num: String) {
        
        let alertView = UIAlertController(title: "Invalid Comic Number", message: "Comic " + num + " does not exist.", preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        alertView.addAction(OKAction)
        
        self.presentViewController(alertView, animated: true, completion: nil)
        
    }
    
    /**
        getRSS()
        Downloads the RSS feed in XML form and calls the parser
    */
    func getRSS() {
        
        let urlString = NSURL(string: "http://xkcd.com/rss.xml")
        let rssUrlRequest:NSURLRequest = NSURLRequest(URL: urlString!)
        let queue:NSOperationQueue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(rssUrlRequest, queue: queue) {
            (response, data, error) -> Void in
            self.xmlParser = NSXMLParser(data: data)
            self.xmlParser.delegate = self
            self.xmlParser.parse()
        }
        
    }
    
    func startLoading() {
        
        let alertView = UIAlertController(title: "Loading...", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        self.presentViewController(alertView, animated: true, completion: nil)
        
    }
    
    func stopLoading() {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    // *****************
    // MARK: - XMLParser
    // *****************
    
    var entryTitle: String!
    var entryLink: String!
    var entryDescription: String!
    var entryDate: String!
    
    var currentParsedElement = String()
    var weAreInsideAnItem = false
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
        
        if elementName == "item" {
            weAreInsideAnItem = true
        }
        if weAreInsideAnItem {
            switch elementName{
            case "title":
                entryTitle = String()
                currentParsedElement = "title"
            case "link":
                entryLink = String()
                currentParsedElement = "link"
            case "description":
                entryDescription = String()
                currentParsedElement = "description"
            case "pubDate":
                entryDate = String()
                currentParsedElement = "pubDate"
            default: break
            }
        }
        
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        if weAreInsideAnItem {
            switch currentParsedElement {
            case "title":
                self.entryTitle = self.entryTitle + string!
            case "link":
                self.entryLink = self.entryLink + string!
            case "description":
                self.entryDescription = self.entryDescription + string!
            case "pubDate":
                self.entryDate = self.entryDate + string!
            default: break
            }
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if weAreInsideAnItem {
            switch elementName {
                case "title":
                    currentParsedElement = ""
                case "link":
                    currentParsedElement = ""
                case "description":
                    currentParsedElement = ""
                case "pubDate":
                    currentParsedElement = ""
                default: break
            }
        }
        if elementName == "item" {
            var entryItem = Comic()
            entryItem.title = entryTitle
            entryItem.link = entryLink
            var linkArr = entryLink.componentsSeparatedByString("/")
            entryItem.number = linkArr[3]
            entryItem.description = entryDescription
            var descriptionArr = entryItem.description.componentsSeparatedByString("\"")
            var dateArr = entryDate.componentsSeparatedByString(" ")
            entryItem.date = entryItem.number + " | " + dateArr[0] + " " + dateArr[1] + " " + dateArr[2] + " " + dateArr[3]
            entryItem.imageLink = descriptionArr[1]
            entryItem.alt = descriptionArr[3]
            objects.append(entryItem)
            weAreInsideAnItem = false
        }
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            dispatch_async(dispatch_get_main_queue()) {
                
                self.tableView.reloadData()
                
                self.stopLoading()
                
            }
            
        }
        
        
//        self.tableView.reloadData()
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = objects[indexPath.row] as! Comic
            (segue.destinationViewController as! DetailViewController).detailItem = object
            }
        }
        else if segue.identifier == "showDetailManual" {
            (segue.destinationViewController as! DetailViewController).detailItem = searchComic
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.cellForRowAtIndexPath(indexPath)?.selected = false
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell

        let object = objects[indexPath.row] as! Comic
        cell.textLabel!.text = object.title
        cell.detailTextLabel?.text = object.date
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

