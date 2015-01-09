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
  
  // set hidden at start so 'home' doesn't show
  [self.lblName setHidden:YES];

  [self startStandardUpdates];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Location

- (void)startStandardUpdates {
  // Create the location manager if this object does not
  // already have one.
  if (nil == locationManager)
    locationManager = [[CLLocationManager alloc] init];

  locationManager.delegate = self;
  locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;

  // Set a movement threshold for new events.
  locationManager.distanceFilter = 100; // meters

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

                       [self.lblName setText:self.name];
                       [self.lblName setHidden:NO];
                     }
                 }];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 44;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView
cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView
dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#>
forIndexPath:indexPath];

    // Configure the cell...

    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath
*)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath]
withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the
array, and add a new row to the table view
    }
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath
*)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath
*)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little
preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
