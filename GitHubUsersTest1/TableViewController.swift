//
//  TableViewController.swift
//  GitHubUsersTest1
//
//  Created by Ник on 02.03.16.
//  Copyright © 2016 Ник. All rights reserved.
//

import UIKit
import Alamofire

extension String {
    func replace(string:String, replacement:String) -> String {
        return self.stringByReplacingOccurrencesOfString(string, withString: replacement, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
    
    func removeWhitespace() -> String {
        return self.replace(" ", replacement: "")
    }
}


class TableViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userNameTextField: UITextField! {
        didSet {
            userNameTextField.text = searchName //один раз вызывается
        }
    }

    
    
    
    var searchName = "" {
        didSet {
            userNameTextField.text = searchName
            getData({ URLString, D in
                
                self.getRepos(URLString, success: { R in
                    self.dataSource = R
                    

                    
                    self.tableView.reloadData()
                    }, error: { E in
                        
                })
                
                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                  //self.userImage.contentMode = UIViewContentMode.ScaleAspectFit
                    self.userImage.image = UIImage(data: D)
                }
                
                }) { E in
                    UIAlertView(title: E, message: nil, delegate: nil, cancelButtonTitle: "Cancel").show()
                    
                    self.userImage.image = nil
                    self.userNameTextField.text = ""
                    self.userNameTextField.placeholder = E
                    self.dataSource = [""]
                    self.tableView.reloadData()
                    
            }
        }
    }
    
    var dataSource = [String]()

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        userImage.layer.cornerRadius = userImage.frame.height / 2 // У тебя фрейм и так статичкен, перенести в сториборд
        userImage.layer.masksToBounds = true // аналогично
    }
    
    func getData(success: (String, NSData) -> Void, error: String -> Void) {
        Alamofire.request(.GET, "https://api.github.com/users/" + searchName.removeWhitespace()).responseJSON { response in
            // print(response.request)  // original URL request
            // print(response.response) // URL response
            // print(response.data)     // server data
            // print(response.result)   // result of response serialization
            
            switch response.result {
            case .Success(let R):
            guard let repos = R["repos_url"] as? String,
                     avatar = R["avatar_url"] as? String,
                        url = NSURL(string: avatar),
                       data = NSData(contentsOfURL: url) else { error("Validation error"); return }
                print(R)
            
                success(repos, data)
                
            case .Failure(let E):
                error(E.localizedDescription)
            }
        }
    }
    
    func getRepos(url: String, success: [String] -> Void, error: String -> Void) {
         Alamofire.request(.GET, url).responseJSON { response in
            switch response.result {
            case .Success(let R):
                print(R)
                if let rawList = R as? [[String:AnyObject]] {
                    success(rawList.flatMap { $0["name"] as? String })
                    return
                }
                error("Is not a list")
            case .Failure(let E):
                error(E.localizedDescription)
            }
        }
    }
    
    func getReadme(url: String, success: String -> Void, error: String -> Void) {
        Alamofire.request(.GET, url).responseJSON { response in
            switch response.result {
            case .Success(let R):
                if let readmeUrl = R["download_url"] as? String {
                    Alamofire.request(.GET, readmeUrl).responseString { response in
                        switch response.result {
                            case .Success(let readme):
                                guard let readmeText = readme as? String else { error("Validation error"); return }
                                
                                self.performSegueWithIdentifier("showDetail", sender: readmeText)
                                
                                    success(readmeText)
                            case .Failure(let E):
                                error(E.localizedDescription)
                            
                        }
                    }
                    
                    // success(readmeUrl)
                }

                else { error("Validation error"); UIAlertView(title: "no readme file", message: nil, delegate: nil, cancelButtonTitle: "Cancel").show(); return }
                print(R)

                
            case .Failure(let E):
                error(E.localizedDescription)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Repo", forIndexPath: indexPath) as! TableViewCell
            cell.repoName.text = dataSource[indexPath.item]
        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // indexRepo = indexPath.row
        
        let urlReadme = "https://api.github.com/repos/" + searchName + "/" + dataSource[indexPath.item] + "/" + "readme"
        getReadme(urlReadme, success: { R in
            print(R)
            }) { (E) -> Void in
                
        }
    }
    
    
    //MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == userNameTextField {
            textField.resignFirstResponder()
            searchName = textField.text?.removeWhitespace() ?? ""
        }
        return true
    }
    
    // ••••••••••••••••••••••••••••••
    // MARK: - Refreshing
    
    
//    
//    @IBAction private func refresh(sender: UIRefreshControl?) {
//        if let request = nextRequestToAttempt {
//            request.fetchTweets { (newTweets) -> Void in
//                dispatch_async(dispatch_get_main_queue()) { () -> Void in
//                    if newTweets.count > 0 {
//                        self.lastSuccessfulRequest = request // oops, forgot this line in lecture
//                        self.tweets.insert(newTweets, atIndex: 0)
//                        self.tableView.reloadData()
//                    }
//                    sender?.endRefreshing()
//                }
//            }
//        } else {
//            sender?.endRefreshing()
//        }
//    }
//    
//    func refresh() {
//        refreshControl?.beginRefreshing()
//        refresh(refreshControl)
//    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? DetailViewController, text = sender as? String {
            destination.text = text
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}
