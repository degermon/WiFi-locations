//
//  ViewController.swift
//  WiFi Locations
//
//  Created by Daniel Suskevic on 01/12/2017.
//  Copyright © 2017 Daniel Suskevic. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class ViewController: UIViewController{
    
    @IBOutlet weak var tableView: UITableView!
    
    let locationManager = CLLocationManager()
    var coordinatesArrayLatitude: [String] = []
    var coordinatesArrayLongitude: [String] = []
    var locationCoordinates: [NSManagedObject] = []
    var numberUseToFindDecimals : Int = 100  // 100 for 2 decimals, 1000 for 3 decimals and so on

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupLocationManagerFeatures()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stopLocationManager()
    }

}

//MARK: CLLocation
extension ViewController: CLLocationManagerDelegate {
    func setupLocationManagerFeatures() {
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 1 // neveikia?
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationManager() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { // triggers when coordinates are changed
        checkLocationRepeatance(newLocation: (locations.last)!)
    }
    
    func checkLocationRepeatance(newLocation: CLLocation) { // checks if recieved coordinates already exist/are saved into array
        var newLocCheck : Bool = false
        let coordinates2DecimalsTouple : (Double, Double) = toDecimals(latitude: newLocation, longitude: newLocation)
        
        if let _ = coordinatesArrayLatitude.index(of: String(coordinates2DecimalsTouple.0)), let _ = coordinatesArrayLongitude.index(of: String(coordinates2DecimalsTouple.1)) {
            newLocCheck = true  // there is a dublicate
        }
        
        if newLocCheck == false { // if there is no dublicate
            coordinatesArrayLatitude.append(String(describing: coordinates2DecimalsTouple.0))
            coordinatesArrayLongitude.append(String(describing: coordinates2DecimalsTouple.1))
            intermidiaryData(latitude: String(describing: coordinates2DecimalsTouple.0), longitude: String(describing: coordinates2DecimalsTouple.1))
            self.tableView.reloadData()
            fetchData()
        }
    }
    
    func toDecimals(latitude: CLLocation, longitude: CLLocation) -> (Double, Double) { // func to rond numbers to specified number of desimal points
        
        let latitude2Decimal : Double = Double((latitude.coordinate.latitude * 100).rounded() / 100)
        let longitude2Decimal : Double = Double((longitude.coordinate.longitude * 100).rounded() / 100)
        //print(latitude.coordinate.latitude, longitude.coordinate.longitude)
        //print(latitude2Decimal, longitude2Decimal)
        
        return (latitude2Decimal, longitude2Decimal)
    }
}

//MARK: Table View
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coordinatesArrayLatitude.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell : UITableViewCell = UITableViewCell(style: .default, reuseIdentifier: "MyCell")
        tableViewCell.textLabel?.text = "\(coordinatesArrayLatitude[indexPath.row]) and \(coordinatesArrayLongitude[indexPath.row])"
        
        return tableViewCell
    }
}

//MARK: CoreData actions
extension ViewController {
    
    func save(latitude: String, longitude: String) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity =
            NSEntityDescription.entity(forEntityName: "Locations",
                                       in: managedContext)!
        let loc = NSManagedObject(entity: entity,
                                       insertInto: managedContext)
        
        loc.setValue(latitude, forKey: "latitude")
        loc.setValue(longitude, forKey: "longitude")
        
        savePermanently(loc: loc, managedContext: managedContext)
    }
    
    func fetchData(){
        var dictionary = [String:String]()
        let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Locations")
        do {
            locationCoordinates = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        for loc in locationCoordinates {
            if let latitude = loc.value(forKey: "latitude") as! String?, let longitude = loc.value(forKey: "longitude") as! String? {
                dictionary[latitude] = longitude
            }
        }
        
        print(dictionary)
    }
    
    func update(lat: String, long: String) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        for loc in locationCoordinates {
            if let latitude = loc.value(forKey: "latitude") as! String?, let longitude = loc.value(forKey: "longitude") as! String? {
                
                if latitude == lat || longitude == long {
                    loc.setValue(lat, forKey: "latitude")
                    
                    if longitude == long {
                        loc.setValue(long, forKey: "longitude")
                    }
                    
                    savePermanently(loc: loc, managedContext: managedContext)
                }
            }
        }
    }
    
    func savePermanently(loc: NSManagedObject, managedContext: NSManagedObjectContext) {
        do {
            try managedContext.save()
            locationCoordinates.append(loc)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func intermidiaryData(latitude: String, longitude: String) {
        //update(lat: latitude, long: longitude)
        save(latitude: latitude, longitude: longitude)
    }
}

