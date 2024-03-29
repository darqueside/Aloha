//
//  MapController.swift
//  Aloha
//
//  Created by Medien on 10.11.14.
//  Copyright (c) 2014 Medien. All rights reserved.
//

import Foundation

import UIKit



class MapController: UIViewController,  CLLocationManagerDelegate,  GMSMapViewDelegate, SurfSpotMarkerDelegate, SpotFilterDelegate { //MapToLocationViewDelegate,
    
    
    @IBOutlet weak var mapView: GMSMapView! // zeigt die Google Map
    
    
    var marker = GMSMarker() // zeigt die aktuelle Suchposition - Suchpin
    var surfPlaces: [GMSMarker] = [] // sammelt die gespeicherten Surfspots
    var tempCoord: CLLocationCoordinate2D! // speichert die temporäre Koordinate
    var sidebar:Sidebar = Sidebar()
    
    var addressText:String = "Adresse von Map"
    
    let locationManager = CLLocationManager() // sammelt Information der GPS-Daten der eigenen Position
  //  let dataProvider = GoogleDataProvider() // Daten die zur Nutzung von Gmaps nötig sind
    
    
    @IBOutlet weak var searchMarkerSwitch: UISwitch! // kontrolle über aktivierung von Suchpin und Adresslabel
    
    @IBOutlet weak var adressLabel: UILabel! // zeigt die aktuelle Adresse vom Suchpin an
    
   
    override func viewDidLoad() {
        
        super.viewDidLoad()

        //Lädt direkt am Anfang alle Locations
        //FIXME: möglicherweise früher notwendig!
        Vault.loadLocations()
       
        mapView.delegate = self
        mapView.myLocationEnabled = true
//        mapView.settings.rotateGestures = false
        mapView.settings.compassButton = true
        // erfragt den Zugriff auf Lokalisierung
        
        mapView.settings.consumesGesturesInView = false // Andere Gesten werden nich mehr abgefangen
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapView.myLocationEnabled = true
        adressLabel.hidden = true
        // erzeugt Marker
        marker.position = CLLocationCoordinate2DMake(-33.86, 151.20)
        marker.snippet = "New Surfspot"
        marker.appearAnimation = kGMSMarkerAnimationPop
        marker.map = nil
        
        //erzeugt die Sidebar
        sidebar = Sidebar(sourceView: self.view)
        sidebar.filterDelegate = self
        loadSurfSpots()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    // Filter Daten
    let _dataDifficulty = difficulty()
    let _dataCoastproperties = coastproperties()
    let _dataWaterDepth = waterdepth()
    let _dataWaterTemp = watertemperature()

    
    
    // Funktion zum Filtern der Locations
    func showSpotsWithSpecificFilter(filterNames:[String], filterState:[Int], isSwitchActive: Bool){
        
        // Holt die benötigten Index
        
        
        // Alle Spots löschen
        for spot in  surfPlaces {
            spot.map = nil
        }
        
        // Holt alle Locations
        var localLocations = Vault.getLocations()
        
        // Leeres Location Array. Locations werden nach dem Filtern hinzugefügt
        var filteredLocations = [Location]()

        
        for var i:Int = 0; i < localLocations.count; i++ {
            
            
            // Index der Locations
            var locationDifficultyIndex: Int = localLocations[i]._difficulty as Int
            var locationCoastpropertiesIndex: Int = localLocations[i]._coastproperties as Int
            var locationWaterDepthIndex: Int = localLocations[i]._waterdepth as Int
            var locationWaterTempIndex: Int = localLocations[i]._watertemperature as Int
            
           
            var filterCounter = 0
            var locationState = false
            
            // Filter werden angewandt
            for filterName in filterNames {
                
                if (filterName == "Ja" && filterState[filterCounter] == 1 && localLocations[i].favorite == true){
                    locationState = true
                } else if (filterName == "Ja" && filterState[filterCounter] == 0 && localLocations[i].favorite == false){
                    locationState = false
                    break
                }
                

                if (filterState[filterCounter] == 1 && find(_dataDifficulty.difficulty, filterName) == locationDifficultyIndex ){
                    locationState = true
                } else if (filterState[filterCounter] == 0 && find(_dataDifficulty.difficulty, filterName) == locationDifficultyIndex){
                    locationState = false
                    break
                }
                
                if (filterState[filterCounter] == 1 && find(_dataCoastproperties.coastproperties, filterName) == locationCoastpropertiesIndex){
                    locationState = true
                } else if (filterState[filterCounter] == 0 && find(_dataCoastproperties.coastproperties, filterName) == locationCoastpropertiesIndex){
                    locationState = false
                    break
                }
                
                if (filterState[filterCounter] == 1 && find(_dataWaterDepth.waterdepth, filterName) == locationWaterDepthIndex){
                    locationState = true
                } else if (filterState[filterCounter] == 0 && find(_dataWaterDepth.waterdepth, filterName) == locationWaterDepthIndex){
                    locationState = false
                    break
                }
                
                if (filterState[filterCounter] == 1 && find(_dataWaterTemp.watertemperature, filterName) == locationWaterTempIndex){
                    locationState = true
                } else if (filterState[filterCounter] == 0 && find(_dataWaterTemp.watertemperature, filterName) == locationWaterTempIndex){
                    locationState = false
                    break
                }
                
                filterCounter++
            }
            
            // gefilterte Locations werden aufgenommen
            if locationState == true {
                filteredLocations.append(localLocations[i])
            }

        }
        
        // gefilterte Locations werden ausgegeben
        for var i:Int = 0; i < filteredLocations.count; i++ {
            for spot in  surfPlaces {
                if(spot.position.latitude == filteredLocations[i].lat && spot.position.longitude == filteredLocations[i].long){
                    spot.map = mapView
                }
                
            }
        }

        
    }
    
    func loadSurfSpots() {
        surfPlaces.removeAll(keepCapacity: false)
        var localLocations = Vault.getLocations()
        for var i:Int = 0; i < localLocations.count; i++ {
            let spot = GMSMarker()
            
            spot.position = CLLocationCoordinate2DMake(localLocations[i].lat.doubleValue, localLocations[i].long.doubleValue)
            spot.snippet = localLocations[i].name
            
            if(!localLocations[i].favorite){
                spot.icon = UIImage(named: "Pin_normal")
            }
            else{
                 spot.icon = UIImage(named: "Pin_Fav")
            }
            
            spot.appearAnimation = kGMSMarkerAnimationPop
            spot.map = self.mapView
            surfPlaces.append(spot)
            
        }
    }
    
    // aktualisiert die Adresse im Label sobald sich die map bewegt und gestoppt hat
    func mapView(mapView: GMSMapView!, idleAtCameraPosition position: GMSCameraPosition!) {
        reverseGeocodeCoordinate(position.target)
    }
    
    
    @IBAction func showSearchMarker(sender: UISwitch) {
        if(searchMarkerSwitch.on){
            self.marker.map = mapView
           
            adressLabel.hidden = false
        }
        else{
            self.marker.map = nil
           
            adressLabel.hidden = true
        }
    }
    
    
    // aktualisiert die Marker auf der Map
    @IBAction func refreshPlaces(sender: UIBarButtonItem) {
        loadSurfSpots()
        refreshMap(mapView.camera.target)
    }
    
    // Ändert die Map Ansicht
    @IBAction func mapTypeChoice(sender: AnyObject) {
        let segmentedControl = sender as UISegmentedControl
        
        switch segmentedControl.selectedSegmentIndex {
        case 0: mapView.mapType = kGMSTypeNormal
            
        case 1:
            mapView.mapType = kGMSTypeSatellite
            
        case 2: mapView.mapType = kGMSTypeHybrid
            
        default: mapView.mapType = mapView.mapType
        }
    }
    
    // Wandelt Latitude und Longitude Koordinaten in eine normale Adresse
    func reverseGeocodeCoordinate(coordinate: CLLocationCoordinate2D) {
        
       
        let geocoder = GMSGeocoder()
        
        // Anfrage und Überprüfung ob es zu den Koordinaten auch eine Adresse gibt
       
        geocoder.reverseGeocodeCoordinate(coordinate) { response , error in
            
        
            
            if let address = response?.firstResult() {
                
                // empfangene Adresse wird als String gespeichert und dem Label hinzugefügt
                let lines = address.lines as [String]
                self.adressLabel.text = join("\n", lines)
                
                let labelHeight = self.adressLabel.intrinsicContentSize().height
                self.mapView.padding = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: labelHeight, right: 0)
                
                // zeigt die Ändererung im Label an
                UIView.animateWithDuration(0.25) {
                    
                    self.marker.position = self.mapView.camera.target
                    self.view.layoutIfNeeded()
                }
            }
        }

        
    }
        
    // registriert langes drücken zum erzeugen eines neuen Markers
    func mapView(mapView: GMSMapView!, didLongPressAtCoordinate longPressCoordinate: CLLocationCoordinate2D){
        
        //speichert die gedrückte Koordinate und bereitet die Verbindung zur LocationEditorView vor
       
        tempCoord = longPressCoordinate
        performSegueWithIdentifier("MapToLocSegue", sender: self)
       
        
    }
    
    // Übergang zum nächsten ViewController mittels Segue
    // damit das Surfspot-Icon nachdem Speichern auf der Map angezeigt wird
    // erfolgt der Übergang mittels einer Segue. Der Datentransfer erfolgt über
    // ein Delegate, das in der LocationEditorView ausgelöst wird.
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "MapToLocSegue"){
            
//            println("ok segue")
            let vc = segue.destinationViewController as LocationEditorView
            vc.currentCoordinate = tempCoord
            vc.delegate = self

        }
    }
    // öffnet die LocationView nach drücken des Markers und überträgt die dazugehörigen Koordinaten
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        
        //FIXME: aus Locations die Koordinate wieder fischen & dem LocationEditorView den Punkt zum anzeigen übergeben
        tempCoord = marker.position
        performSegueWithIdentifier("MapToLocSegue", sender: self)

        
        return true
    }
    
    // gehört zum Delegate-Vorgang. Nachdem in der LocationEditorView gespeichert wurde
    // wird diese Funktion ausgeführt die letztendlich das Anzeigen des Surfspots an der entsprechenden 
    // Koordinate übernimmt
    func createNewSurfSpotDidFinish(controller: LocationEditorView, coords: CLLocationCoordinate2D, isFavActive: Bool) {
       
        // entferne die LocationEditorView
        controller.navigationController?.popViewControllerAnimated(true)
        // erstelle neuen Surfspotmarker
        if(!surfPlaces.isEmpty){
            for( var i:Int = 0; i < surfPlaces.count; i++){
                if(surfPlaces[i].position.latitude == coords.latitude && surfPlaces[i].position.longitude == coords.longitude){
//                    println("SurfSpot Icon an dieser Stelle schon vorhanden")
                }
                else{
                    var surfMarker = GMSMarker()
                    surfMarker.position = coords
                    
                    surfMarker.snippet = "Surf_Spot"
          
                    if(!isFavActive){
                        surfMarker.icon = UIImage(named: "Pin_normal")
                    }
                    else{
                        surfMarker.icon = UIImage(named: "Pin_Fav")
                    }
                    surfMarker.appearAnimation = kGMSMarkerAnimationPop
                    surfMarker.map = self.mapView
                    surfPlaces.append(surfMarker)
//                    println("neue Surfspotlocation: \(coords.latitude, coords.longitude)")
                              }
            }
        }
        else{
            var surfMarker = GMSMarker()
            surfMarker.position = coords
            surfMarker.snippet = "Surf_Spot"
            
                       if(!isFavActive){
                surfMarker.icon = UIImage(named: "Pin_normal")
            }
            else{
                surfMarker.icon = UIImage(named: "Pin_Fav")
            }

            
            surfMarker.appearAnimation = kGMSMarkerAnimationPop
            surfMarker.map = self.mapView
            surfPlaces.append(surfMarker)
//            println("neue Surfspotlocation: \(coords.latitude, coords.longitude)")
        

        }
    
    }
    // wird ausgeführt wenn in der Editorview auf Löschen gedrückt wurde
    func deleteSurfSpotDidFinish(controller: LocationEditorView, coords: CLLocationCoordinate2D) {
        
            // entferne die LocationEditorView
            controller.navigationController?.popViewControllerAnimated(true)
            // erstelle neuen Surfspotmarker
            if(!surfPlaces.isEmpty){
                for( var i:Int = 0; i < surfPlaces.count; i++){
                    if (surfPlaces[i].position.latitude == coords.latitude && surfPlaces[i].position.longitude == coords.longitude) {
                       
                        surfPlaces.removeAtIndex(i)
                        loadSurfSpots()
                        refreshMap(coords)
                        return
                    }
                }
            }
        }

    // wird aufgerufen wenn der User die Anfrage zur Erlaubnis der Lokalisierung beantwortet hat
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if status == .AuthorizedWhenInUse {
            

            locationManager.startUpdatingLocation()
            
            mapView.myLocationEnabled = true // erzeugt einen blauen Punkt, wo sich der User befindet
            mapView.settings.myLocationButton = true // erzeugt einen Button auf der Map zum zentrieren der Location
        }
    }
    
    // wird aufgerufen wenn LocationManager neue Lokalisierungsdaten erhalten hat
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let location = locations.first as? CLLocation {
            
            // Kamera nach neuen Daten ausrichten
            mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 1, bearing: 0, viewingAngle: 0)
            marker.position = mapView.camera.target
            
//            println("lokalisierung abgschlossen")
            locationManager.stopUpdatingLocation()
            refreshMap(location.coordinate)
        }

    }
    
   
    func refreshMap(coordinate: CLLocationCoordinate2D) {
        // lösche aller Marker
        mapView.clear()
        marker.map = nil
        searchMarkerSwitch.setOn(false, animated: true)
        for spot: GMSMarker in surfPlaces{
            spot.map = mapView
        }
         }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
   }
