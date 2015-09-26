//
//  MasterViewController.swift
//  xkcd
//
//  Created by Evan Salter on 2015-09-17.
//  Copyright (c) 2015 Evan Salter. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, NSXMLParserDelegate {
    
    
    // TODO: Check for network connectivity before attempting to download data
    
    // **************************
    // MARK: - Instance Variables
    // **************************
    
    // Array of Comic objects to list on main page
    var objects = [AnyObject]()
    
    // XML parser object to parse RSS feed
    var xmlParser: NSXMLParser!
    
    // Stores the comic that was searched for for passing to DetailViewController
    var searchComic: Comic = Comic()
    
    // List of new comics loaded from the RSS feed for updating the list
    var newComicsFromRSS = [Comic]()
    
    // Key for saving and loading to NSUserDefaults
    let kAllComics = "comics"

    // Progress bar
    @IBOutlet weak var progressView: UIProgressView!

    // ******************
    // MARK: - View Setup
    // ******************
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Initialize progress bar
        progressView.hidden = true
        progressView.setProgress(0.0, animated: false)
        
        // Show loading indicator
        //startLoading()
        
        // Load the comics from 
        self.loadComics()
        
        // parse RSS
        getRSS()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Shows a loading indicator to be used when downloading data
    func startLoading() {
        
        let alertView = UIAlertController(title: "Loading...", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        
        self.presentViewController(alertView, animated: true, completion: nil)
        
    }
    
    /// Removes the loading indicator presented by `startLoading()`
    func stopLoading() {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    // **************
    // MARK: - Search
    // **************
    
    /// UI to search for a particular comic by its comic number
    /// 
    /// Presents an alert with a text box to accept the comic number by the user
    @IBAction func searchButtonPressed(sender: AnyObject) {
        
        // initiallize the alert
        let alertController = UIAlertController(title: "Find Comic", message: "Enter the number of the comic to open:", preferredStyle: .Alert)
        
        // call searchForComicByNumber() when the text is submitted
        let submitAction = UIAlertAction(title: "Submit", style: .Default) { (_) in
            
            let comicField = alertController.textFields![0] 
            
            self.searchForComicByNumber(comicField.text!)
            
        }
        
        // disable the submit when there is no data in the text field
        submitAction.enabled = false
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        // add the text field
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            
            textField.placeholder = "Comic number"
            
            // when there is text in the text field...
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                // ...enable the submit button
                submitAction.enabled = textField.text != ""
            }
            
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        
        // present the alert
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    /// Performs the search for the comic with the number inputted by searchButtonPressed()
    ///
    /// - parameters:
    ///     - string: `String` containing the comic number
    func searchForComicByNumber(string: String) {
        
        
        let urlString = NSURL(string: "http://xkcd.com/" + string)
        let urlRequest = NSURLRequest(URL: urlString!)
        let queue = NSOperationQueue()
        
        // send an asynchronous request for the HTML data on the comic page
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: queue) {
            (response, data, error) -> Void in
            let stringData = NSString(data: data!, encoding: NSUTF8StringEncoding)

            // if the HTML for the page is less than 400 characters, it is an error page and there is no comic there
            if(stringData!.length < 400){
                // present an "invalid number" error
                self.invalidNumberError(string)
            }
            else {
                
                let comic = self.downloadComicWithNumber(string)
                
                // set the searchComic instance variable to the comic.
                // the DetailViewController will grab the comic from that variable after we do the segue
                self.searchComic = comic
            
                // perform the segue on the main queue
                let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                dispatch_async(dispatch_get_global_queue(priority, 0)) {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        self.performSegueWithIdentifier("showDetailManual", sender: self)
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    /// Presents an error when the comic number to search for is not valid
    ///
    /// - parameters:
    ///     - num: `String` containing the invalid number
    func invalidNumberError(num: String) {
        
        let alertView = UIAlertController(title: "Invalid Comic Number", message: "Comic " + num + " does not exist.", preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        alertView.addAction(OKAction)
        
        self.presentViewController(alertView, animated: true, completion: nil)
        
    }
    
    // ***************
    // MARK: - Storage
    // ***************
    
    /// Saves the comics that are currently in the list to user defaults
    func saveComics() {
        
        var dictionary:[NSDictionary] = []
        for var i = 0; i < self.objects.count; i++ {
            // use the dictionary() method in the Comic class to convert the Comic objects to NSDictionaries
            dictionary.append((objects[i] as! Comic).dictionary())
        }
        NSUserDefaults.standardUserDefaults().setObject(dictionary, forKey: kAllComics)
        
    }
    
    /// Loads the comics from user defaults to the list
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
    
    // **************************
    // MARK: - Downloading Comics
    // **************************
    
    func noNetworkErrorDialog() {
        
        let alertView = UIAlertController(title: "No Network Connection", message: "You are not connected to the internet.  Please connect to the internet and try again.", preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        alertView.addAction(OKAction)
        
        self.presentViewController(alertView, animated: true, completion: nil)
        
    }
    
    /// Downloads the RSS feed from xkcd.com and calls the XML parser to parse it, resulting in the 4 most recent comics.
    ///
    /// After parsing, the function checks which comics, if any, are new, and places them in the correct spot in the objects array.
    ///
    /// If there are comics missing in the list between the oldest one in the RSS feed, and the newest one in the list, it will load those.
    /// 
    /// For example, if objects=[1234, 1233, 1232, ...] and `getRSS()` returns [1240, 1239, 1238, 1237], then 1236 and 1235 will also be loaded
    func getRSS() {
        
        let reachability = Reachability.reachabilityForInternetConnection()
        if reachability?.isReachable() == false {
            noNetworkErrorDialog()
            return
        }
        
        self.startLoading()
        
        let urlString = NSURL(string: "http://xkcd.com/rss.xml")
        let rssUrlRequest:NSURLRequest = NSURLRequest(URL: urlString!)
        let queue:NSOperationQueue = NSOperationQueue()
        
        // perform an asynchronous request to download the RSS feed in XML form
        NSURLConnection.sendAsynchronousRequest(rssUrlRequest, queue: queue) {
            (response, data, error) -> Void in
            // parse the data.  This adds the new comics to an array of Comic called newComicsFromRSS
            self.xmlParser = NSXMLParser(data: data!)
            self.xmlParser.delegate = self
            self.xmlParser.parse()
            
            // if objects[] is not empty, we have to figure out which comics need to be added, and where
            if self.objects.count > 0 {
                // the number of the current newest comic in the list
                let latestComicNumber = Int((self.objects[0] as! Comic).number)

                // if the oldest comic from the RSS feed is newer than the newest comic in the list, then we add them all to the front
                if Int(self.newComicsFromRSS[3].number) > latestComicNumber {
                    self.objects.insert(self.newComicsFromRSS[3], atIndex: 0)
                    self.objects.insert(self.newComicsFromRSS[2], atIndex: 0)
                    self.objects.insert(self.newComicsFromRSS[1], atIndex: 0)
                    self.objects.insert(self.newComicsFromRSS[0], atIndex: 0)
                    
                    // check to see if there are any comics missing in the list between the new ones added and the pre-existing ones
                    if Int((self.objects[3] as! Comic).number)! - 1 > Int((self.objects[4] as! Comic).number)! {
                        
                        //find the numbers between objects[3] and objects[4] and load them in
                        let objects3num = Int((self.objects[3] as! Comic).number)
                        let objects4num = Int((self.objects[4] as! Comic).number)
                        
                        var numsToLoad = [Int]()
                        
                        // add each comic number to the array
                        for var i = objects3num! - 1; i > objects4num; i-- {
                            numsToLoad.append(i)
                        }
                        
                        // download the comics and add them to the array
                        var comicArray: [Comic] = self.loadComicsWithNumbers(numsToLoad)
                        
                        // perform UI updates on the main thread
                        dispatch_async(dispatch_get_main_queue(), {
                            
                            // insert the missing comics
                            for var i = 0; i < comicArray.count; i++ {
                                // insert at index 4 because that is between the new and old comics
                                self.objects.insert(comicArray[i], atIndex: 4)
                                let indexPath = NSIndexPath(forRow: self.objects.count-1, inSection: 0)
                                self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                                self.tableView.reloadData()
                            }
                            
                        })

                        
                    }
                    
                }
                // there is one overlapping comic, so add the 3 newest
                else if Int(self.newComicsFromRSS[2].number) > latestComicNumber {
                    self.objects.insert(self.newComicsFromRSS[2], atIndex: 0)
                    self.objects.insert(self.newComicsFromRSS[1], atIndex: 0)
                    self.objects.insert(self.newComicsFromRSS[0], atIndex: 0)
                }
                // there are two overlapping comics, so add the 2 newest
                else if Int(self.newComicsFromRSS[1].number) > latestComicNumber {
                    self.objects.insert(self.newComicsFromRSS[1], atIndex: 0)
                    self.objects.insert(self.newComicsFromRSS[0], atIndex: 0)
                }
                // there are 3 overlapping comics, so add the 1 newest
                else if Int(self.newComicsFromRSS[0].number) > latestComicNumber {
                    self.objects.insert(self.newComicsFromRSS[0], atIndex: 0)
                }
                
            }
            
            // objects[] is empty, so add all the new comics into the list
            else {
                for var i = 0; i < self.newComicsFromRSS.count; i++ {
                    self.objects.append(self.newComicsFromRSS[i])
                }
            }
            
            // save the comics list
            self.saveComics()
            
        }
        
    }
    
    /// Loads the comics with the specified comic numbers into the list
    ///
    /// - parameters:
    ///     - nums: `Int` array containing the numbers of the comics to load
    /// - returns: Array of `Comic` containing the downloaded comics
    func loadComicsWithNumbers(nums: [Int]) -> [Comic] {
        
        // array of Comic to return
        var returnArray = [Comic]()
        
        // download each Comic, parse it, and add it to the array
        for var i = 0; i < nums.count; i++ {
            
            let comic = downloadComicWithNumber(nums[i].description)
            
            returnArray.append(comic)
            
        }
        
        // return the Comic array
        return returnArray
        
    }
    
    /// Loads 10 more comics at the end of the list
    func loadMoreComics() {
        
        let reachability = Reachability.reachabilityForInternetConnection()
        if reachability?.isReachable() == false {
            self.noNetworkErrorDialog()
            return
        }
        
        if Int((self.objects[self.objects.count-1] as! Comic).number) == 1 {
            self.noMoreComicsError()
            return
        }
        
        // display the loading indicator
        self.startLoading()
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
        
            // find the lowest comic number in the list
            let lowestNumberString = (self.objects[self.objects.count-1] as! Comic).number
            let lowestNumberInt = Int(lowestNumberString)
            // array to hold the comic numbers to download
            var nums = [String]()
            
            // find the next 10 comic numbers and add them to the nums array
            for var i = lowestNumberInt! - 1; i >= lowestNumberInt! - 10 && i > 0; i-- {
                nums.append(i.description)
            }
            
            // for each number in the nums array, download that comic, parse it, and append it to objects[]
            for var i = 0; i < nums.count; i++ {
                
                let comic = self.downloadComicWithNumber(nums[i])
                
                // perform the UI updates on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    self.objects.append(comic)
                    let indexPath = NSIndexPath(forRow: self.objects.count-1, inSection: 0)
                    self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                    self.tableView.reloadData()
                })
                
            }
            
            // remove the loading indicator
            self.stopLoading()
            
            // save the comic list
            self.saveComics()
        
        }
        
    }
    
    func noMoreComicsError() {
        
        let alertView = UIAlertController(title: "No more comics", message: "Error: There are no more comics to download.", preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertView.addAction(OKAction)
        
        self.presentViewController(alertView, animated: true, completion: nil)
        
    }
    
    /// Checks for new comics to add to the list when pull-to-refresh is activated
    @IBAction func refresh(sender: UIRefreshControl) {
        
        // check for new comics
        self.getRSS()
        
        // stop the refreshControll spinner
        sender.endRefreshing()
        
    }
    
    @IBAction func downloadAllButtonPressed(sender: AnyObject) {
        
        let reachability = Reachability.reachabilityForInternetConnection()
        if reachability?.isReachable() == false {
            self.noNetworkErrorDialog()
            return
        }
        
        // confirmation alert
        let alertView = UIAlertController(title: "Download All Comics", message: "This action will download all comics.  Would you like to continue?", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let continueAction = UIAlertAction(title: "Continue", style: .Default) { (_) in
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            self.progressView.hidden = false
            self.title = "Downloading " + (Int((self.objects[self.objects.count-1] as! Comic).number)!-1).description +  " comics..."
            dispatch_async(dispatch_get_global_queue(priority, 0)){
                self.downloadAllComics()
            }
        }
        
        alertView.addAction(cancelAction)
        alertView.addAction(continueAction)
        
        self.presentViewController(alertView, animated: true, completion: nil)
        
    }
    
    func downloadAllComics() {
        
        let reachability = Reachability.reachabilityForInternetConnection()
        if reachability?.isReachable() == false {
            self.noNetworkErrorDialog()
            return
        }
        
        let refreshControlRef = self.refreshControl
        self.refreshControl = nil
        self.tableView.bounces = false
        
        let lowestComicNumber = Int((objects[objects.count-1] as! Comic).number);
        let currentComic = lowestComicNumber! - 1
        
        print(lowestComicNumber)
        print(currentComic)
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            for var i = currentComic; i > 0; i-- {
                if i == 1 {
                    self.progressView.setProgress(0.0, animated: false)
                }
                else{
                    let progress: Float = (Float(lowestComicNumber!) - Float(i)) / Float(lowestComicNumber!)
                    self.progressView.setProgress(progress, animated: true)
                }
                
                let comic = self.downloadComicWithNumber(i.description)
                
                // perform the UI updates on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    self.objects.append(comic)
                    let indexPath = NSIndexPath(forRow: self.objects.count-1, inSection: 0)
                    self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                    self.tableView.reloadData()
                    self.saveComics()
                    
                })

            }
            dispatch_async(dispatch_get_main_queue(), {
                self.progressView.hidden = true
                self.title = "xkcd"
                self.refreshControl = refreshControlRef
                self.tableView.bounces = true
            })
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self.refreshControl?.enabled = true
        })
    }
    
    func downloadComicWithNumber(number: String) -> Comic {
        
        let urlString = NSURL(string: "http://xkcd.com/" + number)
        let urlRequest = NSURLRequest(URL: urlString!)
        let data = try? NSURLConnection.sendSynchronousRequest(urlRequest, returningResponse: nil)
        let stringData = NSString(data: data!, encoding: NSUTF8StringEncoding)
        
        let comic = Comic()
        comic.link = urlString!.description
        comic.number = number
        let arrayOfImgSrc:[NSString] = (stringData?.componentsSeparatedByString("<img src=\"//"))! as [NSString]
        if arrayOfImgSrc.count >= 3 {
            let comicInfo = arrayOfImgSrc[2]
            let arrayOfComicInfo = comicInfo.componentsSeparatedByString("\"")
            comic.imageLink = "http://" + (arrayOfComicInfo[0] )
            comic.title = arrayOfComicInfo[4]
            comic.alt = arrayOfComicInfo[2]
        }
        comic.description = ""
        comic.date = ""
        
        return comic
        
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

    // **************
    // MARK: - Segues
    // **************

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

    // ******************
    // MARK: - Table View
    // ******************

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
