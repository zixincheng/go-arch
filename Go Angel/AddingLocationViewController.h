//
//  AddingLocationViewController.h
//  Go Arch
//
//  Created by zcheng on 2015-01-22.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "CSLocation.h"
#import "CoreDataWrapper.h"
#import "MyAnnotation.h"

@protocol AddingLocationViewControllerDelegate <NSObject>
@required

- (void)dataMapView:(CSLocation *)data;
@end

@interface AddingLocationViewController: UIViewController <CLLocationManagerDelegate, UITextFieldDelegate, UIAlertViewDelegate,MKMapViewDelegate> {
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
@property (nonatomic,retain) CSLocation *location;
@property (nonatomic,strong) CoreDataWrapper *datawrapper;
@property (nonatomic, strong) CLLocation *currentLocation;

@property (nonatomic, weak) id<AddingLocationViewControllerDelegate> delegate;


//@property (weak, nonatomic) IBOutlet UILabel *lblLatitude;
//@property (weak, nonatomic) IBOutlet UILabel *lblLongitude;
//@property (weak, nonatomic) IBOutlet UITextField *txtUnit;
//@property (weak, nonatomic) IBOutlet UITextField *streetName;

- (IBAction)AddBtn:(id)sender;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) MyAnnotation *point;

@property (nonatomic) BOOL onLocation;

@end
