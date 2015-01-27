//
//  AddingLocationViewController.h
//  Go Angel
//
//  Created by zcheng on 2015-01-22.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "CSLocation.h"
#import "CoreDataWrapper.h"

@interface AddingLocationViewController: UITableViewController <CLLocationManagerDelegate, UITextFieldDelegate, UIAlertViewDelegate> {
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
@property (nonatomic,strong) CSLocation *location;
@property (nonatomic,strong) CoreDataWrapper *datawrapper;
@property (nonatomic, strong) CLLocation *currentLocation;

@property (weak, nonatomic) IBOutlet UILabel *lblLatitude;
@property (weak, nonatomic) IBOutlet UILabel *lblLongitude;
@property (weak, nonatomic) IBOutlet UITextField *txtUnit;
@property (weak, nonatomic) IBOutlet UITextField *streetName;

- (IBAction)AddBtn:(id)sender;




@property (nonatomic) BOOL onLocation;

@end
