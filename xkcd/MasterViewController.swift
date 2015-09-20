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
    
    var newComicsFromRSS = [Comic]()
    
    let kAllComics = "comics"


    // ******************
    // MARK: - View Setup
    // ******************
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        startLoading()
        
        self.loadComics()
        
        // parse RSS
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
            
            let comicField = alertController.textFields![0] 
            
            self.searchForComicByNumber(comicField.text!)
            
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
            let stringData = NSString(data: data!, encoding: NSUTF8StringEncoding)

            if(stringData!.length < 400){
                self.invalidNumberError(string)
            }
            else {
                let comic = Comic()
                comic.link = urlString!.description
                comic.number = string
                let arrayOfImgSrc:[NSString] = (stringData?.componentsSeparatedByString("<img src=\"//"))! as [NSString]
                let comicInfo = arrayOfImgSrc[2]
                let arrayOfComicInfo = comicInfo.componentsSeparatedByString("\"")
                comic.imageLink = "http://" + (arrayOfComicInfo[0] )
                comic.title = arrayOfComicInfo[4] 
                comic.alt = arrayOfComicInfo[2] 
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
    
    func saveComics() {
        
        var dictionary:[NSDictionary] = []
        for var i = 0; i < self.objects.count; i++ {
            dictionary.append((objects[i] as! Comic).dictionary())
        }
        NSUserDefaults.standardUserDefaults().setObject(dictionary, forKey: kAllComics)
        
    }
    
    func loadComics() {
        
        let defaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        let savedData:[NSDictionary]? = defaults.objectForKey(kAllComics) as? [NSDictionary]
        if let data:[NSDictionary] = savedData {
            for var i = 0; i < data.count; i++ {
                let c:Comic = Comic()
                c.title = data[i].valueForKey("title") as! String
                c.link = data[i].valueForKey("link") as! String
                c.description = data[i].valueForKey("description") as! String
                c.date = data[i].valueForKey("date") as! String
                c.imageLink = data[i].valueForKey("imageLink") as! String
                c.alt = data[i].valueForKey("alt") as! String
                c.number = data[i].valueForKey("number") as! String
                
                objects.append(c)
            }
        }
        
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
            self.xmlParser = NSXMLParser(data: data!)
            self.xmlParser.delegate = self
            self.xmlParser.parse()
            
            if self.objects.count > 0 {
                let latestComicNumber = Int((self.objects[0] as! Comic).number)

                if Int(self.newComicsFromRSS[3].number) > latestComicNumber {
                    self.objects.insert(self.newComicsFromRSS[3], atIndex: 0)
                    self.objects.insert(self.newComicsFromRSS[2], atIndex: 0)
                    self.objects.insert(self.newComicsFromRSS[1], atIndex: 0)
                    self.objects.insert(self.newComicsFromRSS[0], atIndex: 0)
                    
                    if Int((self.objects[3] as! Comic).number)! - 1 > Int((self.objects[4] as! Comic).number)! {
                        
                        //find the numbers between objects[3] and objects[4] and load them in
                        let objects3num = Int((self.objects[3] as! Comic).number)
                        let objects4num = Int((self.objects[4] as! Comic).number)
                        
                        var numsToLoad = [Int]()
                        
                        for var i = objects3num! - 1; i > objects4num; i-- {
                            numsToLoad.append(i)
                        }
                        
                        var comicArray: [Comic] = self.loadComicsWithNumbers(numsToLoad)
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            
                            for var i = 0; i < comicArray.count; i++ {
                                self.objects.insert(comicArray[i], atIndex: 4)
                                let indexPath = NSIndexPath(forRow: self.objects.count-1, inSection: 0)
                                self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                                self.tableView.reloadData()
                            }
                            
                        })

                        
                    }
                    
                }
                else if Int(self.newComicsFromRSS[2].number) > latestComicNumber {
                    self.objects.insert(self.newComicsFromRSS[2], atIndex: 0)
                    self.objects.insert(self.newComicsFromRSS[1], atIndex: 0)
                    self.objects.insert(self.newComicsFromRSS[0], atIndex: 0)
                }
                else if Int(self.newComicsFromRSS[1].number) > latestComicNumber {
                    self.objects.insert(self.newComicsFromRSS[1], atIndex: 0)
                    self.objects.insert(self.newComicsFromRSS[0], atIndex: 0)
                }
                else if Int(self.newComicsFromRSS[0].number) > latestComicNumber {
                    self.objects.insert(self.newComicsFromRSS[0], atIndex: 0)
                }
                
            }
            
            else {
                for var i = 0; i < self.newComicsFromRSS.count; i++ {
                    self.objects.append(self.newComicsFromRSS[i])
                }
            }
            
            self.saveComics()
            
        }
        
    }
    
    func startLoading() {
        
        let alertView = UIAlertController(title: "Loading...", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        self.presentViewController(alertView, animated: true, completion: nil)
        
    }
    
    func stopLoading() {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func loadComicsWithNumbers(nums: [Int]) -> [Comic] {
        
        var returnArray = [Comic]()
        
        for var i = 0; i < nums.count; i++ {
            
            let urlString = NSURL(string: "http://xkcd.com/" + nums[i].description)
            let urlRequest = NSURLRequest(URL: urlString!)
            let data = try? NSURLConnection.sendSynchronousRequest(urlRequest, returningResponse: nil)
            let stringData = NSString(data: data!, encoding: NSUTF8StringEncoding)
            
            let comic = Comic()
            comic.link = urlString!.description
            comic.number = nums[i].description
            let arrayOfImgSrc:[NSString] = (stringData?.componentsSeparatedByString("<img src=\"//"))! as [NSString]
            let comicInfo = arrayOfImgSrc[2]
            let arrayOfComicInfo = comicInfo.componentsSeparatedByString("\"")
            comic.imageLink = "http://" + (arrayOfComicInfo[0] )
            comic.title = arrayOfComicInfo[4]
            comic.alt = arrayOfComicInfo[2]
            comic.description = ""
            comic.date = ""
            
            returnArray.append(comic)
            
        }
        
        return returnArray
        
    }
    
    func loadMoreComics() {
        
        self.startLoading()
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
        
            let lowestNumberString = (self.objects[self.objects.count-1] as! Comic).number
            let lowestNumberInt = Int(lowestNumberString)
            var nums = [String]()
            
            for var i = lowestNumberInt! - 1; i >= lowestNumberInt! - 10; i-- {
                nums.append(i.description)
            }
            
            for var i = 0; i < nums.count; i++ {
                
                let urlString = NSURL(string: "http://xkcd.com/" + nums[i])
                let urlRequest = NSURLRequest(URL: urlString!)
                let data = try? NSURLConnection.sendSynchronousRequest(urlRequest, returningResponse: nil)
                let stringData = NSString(data: data!, encoding: NSUTF8StringEncoding)
                
                let comic = Comic()
                comic.link = urlString!.description
                comic.number = nums[i]
                let arrayOfImgSrc:[NSString] = (stringData?.componentsSeparatedByString("<img src=\"//"))! as [NSString]
                let comicInfo = arrayOfImgSrc[2]
                let arrayOfComicInfo = comicInfo.componentsSeparatedByString("\"")
                comic.imageLink = "http://" + (arrayOfComicInfo[0] )
                comic.title = arrayOfComicInfo[4] 
                comic.alt = arrayOfComicInfo[2] 
                comic.description = ""
                comic.date = ""
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.objects.append(comic)
                    let indexPath = NSIndexPath(forRow: self.objects.count-1, inSection: 0)
                    self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                    self.tableView.reloadData()
                })
                
            }
            
            self.stopLoading()
            
            self.saveComics()
        
        }
        
    }
    
    @IBAction func refresh(sender: UIRefreshControl) {
        
        self.getRSS()
        
        sender.endRefreshing()
        
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
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
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
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if weAreInsideAnItem {
            switch currentParsedElement {
            case "title":
                self.entryTitle = self.entryTitle + string
            case "link":
                self.entryLink = self.entryLink + string
            case "description":
                self.entryDescription = self.entryDescription + string
            case "pubDate":
                self.entryDate = self.entryDate + string
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
            let entryItem = Comic()
            entryItem.title = entryTitle
            entryItem.link = entryLink
            var linkArr = entryLink.componentsSeparatedByString("/")
            entryItem.number = linkArr[3]
            entryItem.description = entryDescription
            var descriptionArr = entryItem.description.componentsSeparatedByString("\"")
            var dateArr = entryDate.componentsSeparatedByString(" ")
            entryItem.date = dateArr[0] + " " + dateArr[1] + " " + dateArr[2] + " " + dateArr[3]
            entryItem.imageLink = descriptionArr[1]
            entryItem.alt = descriptionArr[3]
            newComicsFromRSS.append(entryItem)
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
        
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
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
        return 2
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.cellForRowAtIndexPath(indexPath)?.selected = false
        
        if indexPath.section == 1 {
            self.loadMoreComics()
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return objects.count
        }
        else {
            return 1
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 

            let object = objects[indexPath.row] as! Comic
            cell.textLabel!.text = object.title
            if object.date == "" {
                cell.detailTextLabel?.text = object.number
            }
            else {
                cell.detailTextLabel?.text = object.number + " | " + object.date
            }
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell2", forIndexPath: indexPath) 
            return cell
        }
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

