//
//  SearchMapViewController.h
//  Go Arch
//
//  Created by zcheng on 2015-01-28.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "CoreDataWrapper.h"
#import "CSDevice.h"
#import "CSLocation.h"
#import "IndividualEntryViewController.h"
#import "SingleLocationViewController.h"
#import "MyAnnotationView.h"
#import "MyAnnotation.h"
#import "CalloutViewCell.h"

@protocol SearchMapViewController;
@interface SearchMapViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate,UISearchBarDelegate,NSFetchedResultsControllerDelegate,MyAnnotationViewDelegate> {
    AccountDataWrapper *account;
}

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) CSDevice *localDevice;
@property (nonatomic, strong) CSLocation *selectedLocation;
@property (nonatomic, strong) CSAlbum *selectedAlbum;
@property (nonatomic, strong) MyAnnotation *callOutAnnotation;

@property(nonatomic,assign)id<SearchMapViewController> delegate;

//@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) NSMutableArray *albums;
@property (nonatomic, strong) NSMutableArray *searchResultLocations;
@property (nonatomic, strong) NSArray *pins;
@property (nonatomic, strong) NSMutableArray *points;

@end
