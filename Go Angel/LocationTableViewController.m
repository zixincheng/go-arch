//
//  LocationTableViewController.m
//  Go Angel
//
//  Created by Jake Runzer on 1/8/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "LocationTableViewController.h"

@interface LocationTableViewController ()

@end

@implementation LocationTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  self.onLocation = [defaults boolForKey:CURR_LOC_ON];
  
  numberSections = 3;
  if (!self.onLocation) numberSections = 1;
  
  // set hidden at start so 'home' doesn't show
  [self.lblName setHidden:YES];
  
  self.txtUnit.delegate = self;

  [self startStandardUpdates];
}

- (void)viewDidDisappear:(BOOL)animated {
  [self stopStandardUpdates];
  NSLog(@"stopped watching location");
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)toggleLocationTagging:(id)sender {
  self.onLocation = [self.toggleLocation isOn];
  
  if (self.onLocation) {
    numberSections = 3;
  }else {
    numberSections = 1;
  }
  
  [self.tableView reloadData];
  
  [self saveLocation];
}

- (IBAction)unitChanged:(id)sender {
  self.unit = self.txtUnit.text;
  
  [self saveLocation];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  
  return YES;
}


#pragma mark - Location

- (void)startStandardUpdates {
  // Create the location manager if this object does not
  // already have one.
  if (nil == locationManager)
    locationManager = [[CLLocationManager alloc] init];

  locationManager.delegate = self;
  locationManager.desiredAccuracy = kCLLocationAccuracyBest;

  // Set a movement threshold for new events.
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

- (void)updateLocationLabels {
  [self.lblLatitude
      setText:[NSString stringWithFormat:@"%f", self.currentLocation.coordinate
                                                    .latitude]];
  [self.lblLongitude
      setText:[NSString stringWithFormat:@"%f", self.currentLocation.coordinate
                                                    .longitude]];
}

- (void)geocodeLocation:(CLLocation *)location {
  if (!geocoder)
    geocoder = [[CLGeocoder alloc] init];

  [geocoder reverseGeocodeLocation:location
                 completionHandler:^(NSArray *placemarks, NSError *error) {
                     if ([placemarks count] > 0) {
                       CLPlacemark *p = [placemarks lastObject];
                       self.country =
                           [p.addressDictionary objectForKey:@"Country"];
                       self.city = [p.addressDictionary objectForKey:@"City"];
                       self.name = [p.addressDictionary objectForKey:@"Name"];
                       
                       self.unit = self.txtUnit.text;

                       [self.lblName setText:self.name];
                       [self.lblName setHidden:NO];
                       
                       [self saveLocation];
                     }
                 }];
}

- (void) saveLocation {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  [defaults setObject:[NSString stringWithFormat:@"%f", self.currentLocation.coordinate.latitude] forKey:CURR_LOC_LAT];
  [defaults setObject:[NSString stringWithFormat:@"%f", self.currentLocation.coordinate.longitude] forKey:CURR_LOC_LONG];
  [defaults setObject:self.name forKey:CURR_LOC_NAME];
  [defaults setObject:self.unit forKey:CURR_LOC_UNIT];
  [defaults setBool:self.onLocation forKey:CURR_LOC_ON];
  
  [defaults synchronize];
  
  NSLog(@"saving location settings to defaults");
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return numberSections;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 44;
}

@end
