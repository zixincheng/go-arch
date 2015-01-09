//
//  LocationTableViewController.h
//  Go Angel
//
//  Created by Jake Runzer on 1/8/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>


@interface LocationTableViewController : UITableViewController <CLLocationManagerDelegate> {
  CLLocationManager *locationManager;
  CLGeocoder *geocoder;
}

@property (nonatomic, strong) CLLocation *currentLocation;

@property (weak, nonatomic) IBOutlet UILabel *lblLatitude;
@property (weak, nonatomic) IBOutlet UILabel *lblLongitude;
@property (weak, nonatomic) IBOutlet UITextField *txtUnit;
@property (weak, nonatomic) IBOutlet UILabel *lblName;


@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *name;


@end
