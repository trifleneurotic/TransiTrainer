//
//  FirstViewController.swift
//  TransiTrainer
//
//  Created by Stone, Gabe on 8/27/17.
//  Copyright © 2017 Tri-Met. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import MessageUI

class RailStop {
    var station:String = ""
    var line:String = ""
    var status:String = ""
    var type:String = ""
    var lat:Float = 0.0
    var lon:Float = 0.0
    
}


class MainlineViewController: UIViewController, MFMailComposeViewControllerDelegate {

    var locManager = CLLocationManager()
    var currentLocation: CLLocation!
    var svc: StudentsViewController = StudentsViewController()
    var ss = [UITableViewCell]()
    var currentStudent = UITableViewCell()
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var selectedStudent: UILabel!
    var inStation: Bool = false
    var inLine: Bool = false
    var inStatus: Bool = false
    var inType: Bool = false
    var railStops: [RailStop] = []
    var csvArray: [String] = []
    var previousStudent:String = ""
    var previousLocation:CLLocation = CLLocation()
    var previousTime:Date? = Date()

    func mailComposeController(controller: MFMailComposeViewController,
                               didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locManager.requestWhenInUseAuthorization()
        currentLocation = locManager.location
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            currentLocation = locManager.location
            NSLog(currentLocation.coordinate.latitude.description)
            NSLog(currentLocation.coordinate.longitude.description)
        }
        
        previousLocation = currentLocation
        csvArray.append("student,inlocation,intime,outlocation,outtime\n")
    
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if let viewControllers = UIApplication.shared.keyWindow?.rootViewController?.childViewControllers {
            for viewController in viewControllers {
                if (viewController is StudentsViewController) {
                    svc = viewController as! StudentsViewController
                    ss = svc.getSelectedStudents()
                }
            }
            
        }

    }
    
    @IBAction func csvSend(_ sender: Any) {
        var str: String = ""
        
        for row in csvArray {
            str.append(row)
        }
        let file = "file.csv" //this is the file. we will write to and read from it
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(file)
            do {
                try str.write(to: fileURL, atomically: false, encoding: .utf8)
            } catch {/* error handling here */}
        
            do {
        
           
                
                var csvdata: NSData = try NSData(contentsOf: fileURL, options: .alwaysMapped)
                var csvatt: Data = csvdata as Data
                
                
                
                if MFMailComposeViewController.canSendMail()
                {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self;
                mail.setCcRecipients(["one@two.com"])
                mail.setSubject("Training Subject")
                mail.setMessageBody("Training Body", isHTML: false)
                mail.addAttachmentData(csvatt, mimeType: "text/csv", fileName: "file.csv")
                self.present(mail, animated: true, completion: nil)
                } else {
                    let myAlert = UIAlertController(title: "Information", message: "Cannot send mail with this device.", preferredStyle: .alert);
                    myAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil));
                    show(myAlert, sender: self)

                }

            }
            catch {}
            
            
            //reading
            //do {
            //    let text2 = try String(contentsOf: fileURL, encoding: .utf8)
            //}
            //catch {/* error handling here */}
        }
        
                }
  
    
    
    @IBAction func actionAlert(_ sender: Any) {
        
        let currentDateTime = Date()
        
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .short
        
        
        //let myAlert = UIAlertController(title: "Alert", message: "This is an alert.", preferredStyle: .alert);
        //myAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil));
        //show(myAlert, sender: self)
        let filepath = Bundle.main.path(forResource: "tm_rail_stops", ofType: "kml")
        let u: URL = URL.init(fileURLWithPath: filepath!)
        let kp: KMLParser = KMLParser(url: u)
        kp.parseKML()
        
            for mkb in kp.placemarks {
            let rs: RailStop = RailStop()
            NSLog((mkb.point?.coordinate.latitude.description)! + " " + (mkb.point?.coordinate.longitude.description)!)
            rs.station = mkb.placemarkData[0]
            rs.line = mkb.placemarkData[1]
            rs.status = mkb.placemarkData[2]
            rs.type = mkb.placemarkData[3]
            rs.lat = Float((mkb.point?.coordinate.latitude.description)!)!
            rs.lon = Float((mkb.point?.coordinate.longitude.description)!)!
            railStops.append(rs)
            
        }
        
        self.timestamp.text = formatter.string(from: currentDateTime).replacingOccurrences(of: ",", with: "")
        locManager.requestWhenInUseAuthorization()
        currentLocation = locManager.location
        if (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            currentLocation = locManager.location
            
        }

        
                let popup = PopupDialog(title: "Students", message: "Please select student.")
        var studentButtons = [DefaultButton]()
        for ssc: UITableViewCell in ss {
            let btn = DefaultButton(title: (ssc.textLabel?.text)!) {
                self.currentStudent = ssc
                self.selectedStudent.text = ssc.textLabel?.text
                self.previousTime = currentDateTime
                self.previousStudent = (ssc.textLabel?.text)!
                let pls: String = self.previousLocation.coordinate.latitude.description + " " + self.previousLocation.coordinate.latitude.description
                let pts: String = formatter.string(from: self.previousTime!).replacingOccurrences(of: ",", with: "")
                let cls: String = self.currentLocation.coordinate.latitude.description + " " + self.currentLocation.coordinate.latitude.description
                let cts: String = formatter.string(from: currentDateTime).replacingOccurrences(of: ",", with: "")
                
                let str: String = self.previousStudent + "," + pls + "," + pts + "," + cls + "," + cts + "\n"
                self.csvArray.append(str)
                
                self.previousLocation = self.currentLocation
                self.previousTime = currentDateTime
                self.previousStudent = (self.selectedStudent.text)!
                
                self.location.text = cls
            
            }
            studentButtons.append(btn)
        }
        
        if( studentButtons.count > 0 ){
        popup.addButtons(studentButtons)
            
            
            
            self.present(popup, animated: true, completion: nil)
            
            
        } else {
            let myAlert = UIAlertController(title: "Information", message: "Please select students in current group.", preferredStyle: .alert);
            myAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil));
            show(myAlert, sender: self)
        }
        
        
        
    }}

