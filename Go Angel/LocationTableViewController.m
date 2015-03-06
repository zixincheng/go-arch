//
//  LocationTableViewController.m
//  Go Arch
//
//  Created by Jake Runzer on 1/8/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "LocationTableViewController.h"

#define NORMAL_SECTIONS_COUNT 4

@interface LocationTableViewController ()

@end

@implementation LocationTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(intoForeground)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  showingAlertView = NO;

  self.onLocation = [defaults boolForKey:CURR_LOC_ON];

  [self checkLocationAllowed];
  if (!allowedLocation) {
    NSLog(@"user has not allowed location services");
    [self.toggleLocation setEnabled:NO];
    [self showAlertView];
  }

  [self.toggleLocation setOn:(self.onLocation && allowedLocation)];

  // set hidden at start so 'home/lat/long' doesn't show
  [self.lblName setHidden:YES];
  [self.lblLatitude setHidden:YES];
  [self.lblLongitude setHidden:YES];

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
    [self.toggleLocation setEnabled:NO];
    [self showAlertView];
  }else {
    [self.toggleLocation setEnabled:YES];
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

// text field for unit # was changed
- (IBAction)unitChanged:(id)sender {
  self.unit = self.txtUnit.text;

  [self saveLocation];
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

  [self.toggleLocation setEnabled:NO];
  [self.toggleLocation setOn:NO];
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
                       self.country =
                           [p.addressDictionary objectForKey:@"Country"];
                       self.countryCode =
                           [p.addressDictionary objectForKey:@"CountryCode"];
                       self.city = [p.addressDictionary objectForKey:@"City"];
                       self.name = [p.addressDictionary objectForKey:@"Name"];
                       self.prov = [p.addressDictionary objectForKey:@"State"];

                       self.unit = self.txtUnit.text;

                       [self.lblName setText:self.name];
                       [self.lblName setHidden:NO];

                       [self saveLocation];
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
  [defaults setObject:self.name forKey:CURR_LOC_NAME];
  [defaults setObject:self.unit forKey:CURR_LOC_UNIT];
  [defaults setObject:self.country forKey:CURR_LOC_COUNTRY];
  [defaults setObject:self.countryCode forKey:CURR_LOC_COUN_CODE];
  [defaults setObject:self.prov forKey:CURR_LOC_PROV];
  [defaults setObject:self.city forKey:CURR_LOC_CITY];

  [defaults setBool:self.onLocation forKey:CURR_LOC_ON];

  // save defaults to disk
  [defaults synchronize];

  NSLog(@"saving location settings to defaults");
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return numberSections;
}

@end
