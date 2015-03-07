//
//  LocationTableViewController.h
//  Go Arch
//
//  Created by Jake Runzer on 1/8/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>


@interface LocationTableViewController : UITableViewController <CLLocationManagerDelegate, UITextFieldDelegate, UIAlertViewDelegate> {
  CLLocationManager *locationManager;
  CLGeocoder *geocoder;
  
  // the number of sections currently visible in table view
  NSInteger numberSections;
  
  // whether or not we have turned on the location updates
  BOOL hasStartedUpdating;
  
  // whether or not the user has allowed location services to be used
  BOOL allowedLocation;
  
  // are you currently showing the alert view dialog box
  BOOL showingAlertView;
}

@property (nonatomic, strong) CLLocation *currentLocation;

@property (weak, nonatomic) IBOutlet UILabel *lblLatitude;
@property (weak, nonatomic) IBOutlet UILabel *lblLongitude;
@property (weak, nonatomic) IBOutlet UITextField *txtUnit;
@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UISwitch *toggleLocation;


@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *prov;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *unit;
@property (nonatomic) BOOL onLocation;

@end
