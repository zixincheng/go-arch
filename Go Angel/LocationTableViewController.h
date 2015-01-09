//
//  LocationTableViewController.h
//  Go Angel
//
//  Created by Jake Runzer on 1/8/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>


@interface LocationTableViewController : UITableViewController <CLLocationManagerDelegate, UITextFieldDelegate> {
  CLLocationManager *locationManager;
  CLGeocoder *geocoder;
  
  NSInteger numberSections;
}

@property (nonatomic, strong) CLLocation *currentLocation;

@property (weak, nonatomic) IBOutlet UILabel *lblLatitude;
@property (weak, nonatomic) IBOutlet UILabel *lblLongitude;
@property (weak, nonatomic) IBOutlet UITextField *txtUnit;
@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UISwitch *toggleLocation;


@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *unit;
@property (nonatomic) BOOL onLocation;

@end
