//
//  AddingLocationViewController.m
//  Go Angel
//
//  Created by zcheng on 2015-01-22.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "AddingLocationViewController.h"

#define NORMAL_SECTIONS_COUNT 4

@interface AddingLocationViewController ()

@end

@implementation AddingLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(intoForeground)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    self.location = [[CSLocation alloc]init];
    self.datawrapper = [[CoreDataWrapper alloc]init];
    
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
    
    self.txtUnit.delegate = self;
    
    [self updateTable];
    
    // only start updating location if onLocation is true
    if (self.onLocation) {
        [self startStandardUpdates];
    }
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
    [self stopStandardUpdates];
    NSLog(@"stopped watching location");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// switch for location tagging was toggled
/*
- (IBAction)toggleLocationTagging:(id)sender {
    self.onLocation = [self.toggleLocation isOn];
    
    if (self.onLocation) {
        // if we haven't started updating location (because it was
        // first set to false when entering page), then start updating it now
        if (!hasStartedUpdating) {
            [self startStandardUpdates];
        }
    }
    
    [self updateTable];
    
    [self saveLocation];
}
*/
// text field for unit # was changed
- (IBAction)unitChanged:(id)sender {
    self.location.unit = self.txtUnit.text;
    [self saveLocation];
    NSLog(@"%@",self.txtUnit.text);
}

// text field for name was changed
- (IBAction)nameChanged:(id)sender {
    [self geocodeAddress];
    self.location.name = self.streetName.text;
    [self saveLocation];

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
    
    [self updateLocationLabels];
    [self geocodeLocation:self.currentLocation];
}

// update the latitude and longitude labels on page
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

// update table to use the correct amount of sections
// depending if location is on
- (void)updateTable {
    numberSections = NORMAL_SECTIONS_COUNT;
    
    if (!self.onLocation || !allowedLocation) {
        numberSections = 1;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{ [self.tableView reloadData]; });
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
                           self.location.country =
                           [p.addressDictionary objectForKey:@"Country"];
                           self.location.countryCode =
                           [p.addressDictionary objectForKey:@"CountryCode"];
                           self.location.city = [p.addressDictionary objectForKey:@"City"];
                           self.location.name = [p.addressDictionary objectForKey:@"Name"];
                           self.location.province = [p.addressDictionary objectForKey:@"State"];
                           self.location.longitude = [NSString stringWithFormat:@"%f", self.currentLocation.coordinate
                                                       .longitude];
                           self.location.latitude = [NSString stringWithFormat:@"%f", self.currentLocation.coordinate
                                                      .latitude];
                           self.location.unit = self.txtUnit.text;
                           
                           [self.streetName setText:self.location.name];
                           [self.streetName setHidden:NO];
                           
                           [self saveLocation];
                       }
                   }];
}

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


            self.lblLatitude.text = self.location.longitude;
            self.lblLongitude.text = self.location.latitude;
        }
    }];
}

// save the current location in the user defaults
- (void)saveLocation {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults
     setObject:[NSString stringWithFormat:@"%f", self.currentLocation
                .coordinate.latitude]
     forKey:CURR_LOC_LAT];
    [defaults
     setObject:[NSString stringWithFormat:@"%f", self.currentLocation
                .coordinate.longitude]
     forKey:CURR_LOC_LONG];
    [defaults setObject:self.location.name forKey:CURR_LOC_NAME];
    [defaults setObject:self.location.unit forKey:CURR_LOC_UNIT];
    [defaults setObject:self.location.country forKey:CURR_LOC_COUNTRY];
    [defaults setObject:self.location.countryCode forKey:CURR_LOC_COUN_CODE];
    [defaults setObject:self.location.province forKey:CURR_LOC_PROV];
    [defaults setObject:self.location.city forKey:CURR_LOC_CITY];
    
    [defaults setBool:self.onLocation forKey:CURR_LOC_ON];
    
    // save defaults to disk
    [defaults synchronize];
    
    NSLog(@"saving location settings to defaults");
}

//save the current location into coredata
-(void) saveLocationToCoredata {
    
    [self.datawrapper addLocation:self.location];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return numberSections;
}
- (IBAction)AddBtn:(id)sender {
    [self saveLocationToCoredata];
    [self.navigationController popToRootViewControllerAnimated:YES];
}
@end
