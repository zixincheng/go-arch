//
//  AddingLocationViewController.m
//  Go Arch
//
//  Created by zcheng on 2015-01-22.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "AddingLocationViewController.h"
#import "AddNewEntryViewController.h"

#define NORMAL_SECTIONS_COUNT 2

@interface AddingLocationViewController ()

@end

@implementation AddingLocationViewController

@synthesize delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
     self.point = [[MyAnnotation alloc]init];
    self.point = [[MyAnnotation alloc] initWithCoordinate:self.mapView.centerCoordinate];
    //[self.navigationController setToolbarHidden:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(intoForeground)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    self.location = [[CSLocation alloc]init];
    self.datawrapper = [[CoreDataWrapper alloc]init];
    
    locationManager = [[CLLocationManager alloc]init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = 10;

    
    showingAlertView = NO;

    self.onLocation = YES;
    
    [self checkLocationAllowed];
    if (!allowedLocation) {
        NSLog(@"user has not allowed location services");
        //[self.toggleLocation setEnabled:NO];
        [self showAlertView];
    }
    
    //[self.toggleLocation setOn:(self.onLocation && allowedLocation)];
    
    // set hidden at start so 'home/lat/long' doesn't show
    
   // self.txtUnit.delegate = self;
    
    //[self updateTable];
    
    // only start updating location if onLocation is true
    if (self.onLocation) {
        [self startStandardUpdates];
    }
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(LongPressDropPin:)];
    lpgr.minimumPressDuration = 1.0;
    [self.mapView addGestureRecognizer:lpgr];
    UIButton *userLocationBtn = [[UIButton alloc]initWithFrame:CGRectMake(10, 10, 30, 30)];
    [userLocationBtn setImage:[UIImage imageNamed:@"paper-plane-7.png"]
                     forState:UIControlStateNormal];
    [userLocationBtn addTarget:self action:@selector(backToUserLocation) forControlEvents:UIControlEventTouchUpInside];

    [self.mapView addSubview:userLocationBtn];
}

-(void)backToUserLocation {
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}
- (void)LongPressDropPin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    [self stopStandardUpdates];
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate =
    [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];

    [self.point setCoordinate:touchMapCoordinate];
    CLLocation *newlocation = [[CLLocation alloc] initWithLatitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];
    [self geocodeLocation:newlocation];
    self.point.title = self.location.sublocation;
    //[self.streetName setText:self.location.name];
    [self.mapView addAnnotation:self.point];
}
-(void) viewDidAppear:(BOOL)animated {
    //self.point = [[MyAnnotation alloc]init];
    //[self startStandardUpdates];
    //[self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}


-(void)dismissKeyboard {
    //[self.streetName resignFirstResponder];
    //[self.txtUnit resignFirstResponder];
}

- (void) intoForeground {
    [self checkLocationAllowed];
    if (!allowedLocation) {
        NSLog(@"user has not allowed location services");
        //[self.toggleLocation setEnabled:NO];
        [self showAlertView];
    }else {
        //[self.toggleLocation setEnabled:YES];
        [self updateTable];
    }
}

- (void)checkLocationAllowed {
    // if location services is enabled or has yet to be determined
    CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
    if (authStatus == kCLAuthorizationStatusAuthorizedWhenInUse ||
        authStatus == kCLAuthorizationStatusNotDetermined) {
        allowedLocation = YES;
    } else {
        allowedLocation = NO;
    }
}

- (void)showAlertView {
    if (!showingAlertView) {
        showingAlertView = YES;
        
        NSString *message = @"You disabled location services for this app. Do you "
        @"want to re-enable?";
        NSString *title = @"Location Services Disabled";
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Open Settings", nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView
didDismissWithButtonIndex:(NSInteger)buttonIndex {
    showingAlertView = NO;
    if (buttonIndex == 0) { // Cancel Tapped
        [self.navigationController popViewControllerAnimated:YES];
    } else if (buttonIndex == 1) { // YES tapped
        [[UIApplication sharedApplication]
         openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.mapView removeAnnotation:self.point];
    [self stopStandardUpdates];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// text field for unit # was changed
- (IBAction)unitChanged:(id)sender {
    //self.location.unit = self.txtUnit.text;
   // [self saveLocation];
    //NSLog(@"%@",self.txtUnit.text);
}

// text field for name was changed
- (IBAction)nameChanged:(id)sender {
    //[self geocodeAddress];
    //self.location.name = self.streetName.text;
    //[self saveLocation];

}

-(void) textFieldDidBeginEditing:(UITextField *)textField {
    
    [self stopStandardUpdates];
}

// when return button pressed, hide keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Location

// start updating location using location services
- (void)startStandardUpdates {
    hasStartedUpdating = YES;
    
    // Create the location manager if this object does not
    // already have one.
    if (nil == locationManager)
        locationManager = [[CLLocationManager alloc] init];
    
    locationManager.delegate = self;
    
    // use best accuracy because the only time we are checking the location
    // is on this page, so it shouldn't be using to much power
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // Set a movement threshold for new events.
    // we want to be really accurate here as distance between houses
    // is not that much
    locationManager.distanceFilter = 10; // meters
    
    // Check for iOS 8. Without this guard the code will crash with "unknown
    // selector" on iOS 7.
    if ([locationManager
         respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    }
    
    NSLog(@"starting location updates");
    [locationManager startUpdatingLocation];
}

// called if the user does not allow location services
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    allowedLocation = NO;
    NSLog(@"user has not allowed location services");
    
    //[self.toggleLocation setEnabled:NO];
    //[self.toggleLocation setOn:NO];
    self.onLocation = NO;
    
    [self updateTable];
    [self saveLocation];
}

// stop updating location
- (void)stopStandardUpdates {
    if (locationManager != nil) {
        [locationManager stopUpdatingLocation];
    }
}

// delegate method for location manager
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    // If it's a relatively recent event, turn off updates to save power.
    self.currentLocation = [locations lastObject];
    //  NSLog(@"latitude %+.6f, longitude %+.6f\n",
    //        self.currentLocation.coordinate.latitude,
    //        self.currentLocation.coordinate.longitude);
    
    //[self updateLocationLabels];
    [self geocodeLocation:self.currentLocation];

}

// update the latitude and longitude labels on page
/*
- (void)updateLocationLabels {
    [self.lblLatitude
     setText:[NSString stringWithFormat:@"%f", self.currentLocation.coordinate
              .latitude]];
    [self.lblLongitude
     setText:[NSString stringWithFormat:@"%f", self.currentLocation.coordinate
              .longitude]];
    
    [self.lblLatitude setHidden:NO];
    [self.lblLongitude setHidden:NO];
}
*/
// update table to use the correct amount of sections
// depending if location is on
- (void)updateTable {
    numberSections = NORMAL_SECTIONS_COUNT;
    
    if (!self.onLocation || !allowedLocation) {
        numberSections = 1;
    }
    
   // dispatch_async(dispatch_get_main_queue(), ^{ [self.tableView reloadData]; });
}

// reverse lookup lat/long to get human readable address
- (void)geocodeLocation:(CLLocation *)location {
    if (!geocoder)
        geocoder = [[CLGeocoder alloc] init];
    
    [geocoder reverseGeocodeLocation:location
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       if ([placemarks count] > 0) {
                           
                           // get address properties of location
                           CLPlacemark *p = [placemarks lastObject];
                           self.location.postCode = [p.addressDictionary objectForKey:@"ZIP"];
                           self.location.country =
                           [p.addressDictionary objectForKey:@"Country"];
                           self.location.countryCode =
                           [p.addressDictionary objectForKey:@"CountryCode"];
                           self.location.city = [p.addressDictionary objectForKey:@"City"];
                           self.location.sublocation = [p.addressDictionary objectForKey:@"Name"];
                           self.location.province = [p.addressDictionary objectForKey:@"State"];
                           self.location.longitude = [NSString stringWithFormat:@"%f", location.coordinate
                                                       .longitude];
                           self.location.latitude = [NSString stringWithFormat:@"%f", location.coordinate
                                                      .latitude];
                           
                           self.location.altitude = [NSString stringWithFormat:@"%f",location.altitude];
                          // self.location.unit = self.txtUnit.text;
                           
                           //[self.streetName setText:self.location.name];
                           //[self.streetName setHidden:NO];
                           //[//self saveLocation];
                           //generate pins on map
                           self.point.coordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
                           self.point.title = self.location.sublocation;
                           [self.mapView addAnnotation:self.point];
                           NSLog(@"altitude %@",self.location.altitude  );
                       }
                   }];
}
/*
-(void) geocodeAddress {
    
    geocoder = [[CLGeocoder alloc]init];
    [geocoder geocodeAddressString:self.streetName.text completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
            CLPlacemark *placemark = [placemarks lastObject];
            [NSString stringWithFormat:@"%f", placemark.location.coordinate.latitude];
            self.location.longitude = [NSString stringWithFormat:@"%f", placemark.location.coordinate.longitude];
            self.location.latitude = [NSString stringWithFormat:@"%f", placemark.location.coordinate.latitude];


            //self.lblLatitude.text = self.location.longitude;
            //self.lblLongitude.text = self.location.latitude;
        }
    }];
}
*/
// save the current location in the user defaults
- (void)saveLocation {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults
     setObject:self.location.latitude
     forKey:CURR_LOC_LAT];
    [defaults
     setObject:self.location.longitude
     forKey:CURR_LOC_LONG];
    [defaults setObject:self.location.sublocation forKey:CURR_LOC_NAME];
    [defaults setObject:self.location.unit forKey:CURR_LOC_UNIT];
    [defaults setObject:self.location.country forKey:CURR_LOC_COUNTRY];
    [defaults setObject:self.location.countryCode forKey:CURR_LOC_COUN_CODE];
    [defaults setObject:self.location.province forKey:CURR_LOC_PROV];
    [defaults setObject:self.location.city forKey:CURR_LOC_CITY];
    
    [defaults setBool:self.onLocation forKey:CURR_LOC_ON];
    
    // save defaults to disk
    [defaults synchronize];
    NSLog(@"location %@",self.location.sublocation);
    NSLog(@"saving location settings to defaults");
}

//save the current location into coredata
-(void) saveLocationToCoredata {
    
    //[self.datawrapper addLocation:self.location];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return numberSections;
}
- (IBAction)AddBtn:(id)sender {
    if (self.location.sublocation !=nil) {
        if ([delegate respondsToSelector:@selector(dataMapView:)]) {
            [delegate dataMapView:self.location];
        }
        //[[self delegate] done:self.location];
        //[self.tabBarController setSelectedIndex:0];
        //[self saveLocationToCoredata];
        //NSArray *objects =
        //[NSArray arrayWithObjects:self.location,nil];
        //NSArray *keys = [NSArray
                         //arrayWithObjects:LOCATION, nil];
        //NSDictionary *locationDic =
        //[NSDictionary dictionaryWithObjects:objects forKeys:keys];
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"AddLocationSegue" object:nil userInfo:locationDic];
        [self.navigationController popViewControllerAnimated:NO];
    }
}

#pragma mark - mapView delegate

-(void) mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    
    //[self zoomToUserLocation:userLocation];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"Location";
    if (annotation == mapView.userLocation) return nil;
    MKPinAnnotationView *pin = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    if (pin == nil) {
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
    } else {
        pin.annotation = annotation;
    }
    pin.pinColor = MKPinAnnotationColorRed;
    pin.enabled = YES;
    pin.canShowCallout = YES;
    pin.animatesDrop = YES;
    pin.draggable = YES;
    
    return pin;
    
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    //id <MKAnnotation> annotation = [view annotation];
    
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    [self stopStandardUpdates];
    [self.point setCoordinate:annotationView.annotation.coordinate];
    CLLocation *newlocation = [[CLLocation alloc] initWithLatitude:annotationView.annotation.coordinate.latitude longitude:annotationView.annotation.coordinate.longitude];
    [self geocodeLocation:newlocation];
    self.point.title = self.location.sublocation;
    //[self.streetName setText:self.location.name];
    if (newState == MKAnnotationViewDragStateEnding)
    {
        CLLocationCoordinate2D droppedAt = annotationView.annotation.coordinate;
        NSLog(@"Pin dropped at %f,%f", droppedAt.latitude, droppedAt.longitude);
    }
}
/*
-(void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    MKAnnotationView *ulv = [mapView viewForAnnotation:mapView.userLocation];
    ulv.hidden = YES;
}

*/


@end
