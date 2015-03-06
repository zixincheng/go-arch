//
//  SearchMapViewController.m
//  Go Arch
//
//  Created by zcheng on 2015-01-28.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "SearchMapViewController.h"

@interface SearchMapViewController ()

@end

@implementation SearchMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //init location auto-dectect
    
    self.locations = [self.dataWrapper getLocations];
    
    
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = 10;
    
    [self.locationManager startUpdatingLocation];
    
    if ([self.locationManager
         respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    // setup pins for each location in map
    self.points = [[NSMutableArray alloc]init];
    
    for (CSLocation *l in self.locations) {
        float latitude = [l.latitude floatValue];
        float longitude = [l.longitude floatValue];
        MKPointAnnotation *point = [[MKPointAnnotation alloc]init];
        point.coordinate =CLLocationCoordinate2DMake(latitude, longitude);
        point.title = l.name;
        if (![l.unit isEqualToString:@""]) {
            point.subtitle = [NSString stringWithFormat:@"Unit %@",l.unit];
        }
        [self.points addObject:point];
    }
    MKPointAnnotation *point1 = [[MKPointAnnotation alloc]init];
    point1.coordinate =CLLocationCoordinate2DMake(0, 0);
    [self.points addObject:point1];
    

    
    self.pins = [[NSArray alloc] initWithArray:self.points];
    [self.mapView addAnnotations:self.pins];
    
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];


    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    // If it's a relatively recent event, turn off updates to save power.
    self.currentLocation = [locations lastObject];
    
    //  NSLog(@"latitude %+.6f, longitude %+.6f\n",
    //        self.currentLocation.coordinate.latitude,
    //        self.currentLocation.coordinate.longitude);
    
}
/*
- (void) zoomToUserLocation : (MKUserLocation *) location {
    
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 1609.344, 1609.344);
    [self.mapView setRegion:viewRegion animated:YES];
}
*/

#pragma mark - mapView delegate

-(void) mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    
    //[self zoomToUserLocation:userLocation];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"Location";
    if (annotation == mapView.userLocation) return nil;
    MKPinAnnotationView *pin = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (pin == nil) {
            pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        } else {
            pin.annotation = annotation;
        }
    pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    pin.pinColor = MKPinAnnotationColorRed;
    pin.enabled = YES;
    pin.canShowCallout = YES;
    pin.animatesDrop = YES;
    
    return pin;

}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    //id <MKAnnotation> annotation = [view annotation];

    MKPointAnnotation *point  = view.annotation;
    NSUInteger index = [self.pins indexOfObject:point];
    self.selectedLocation = [self.locations objectAtIndex:index];
    
    [self performSegueWithIdentifier:@"locationSegue" sender:self];
}

- (void) searchResultPinAction: (NSMutableArray *) result {
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.points removeAllObjects];
    for (CSLocation *l in result) {
        float latitude = [l.latitude floatValue];
        float longitude = [l.longitude floatValue];
        MKPointAnnotation *point = [[MKPointAnnotation alloc]init];
        point.coordinate =CLLocationCoordinate2DMake(latitude, longitude);
        point.title = l.name;
        if (![l.unit isEqualToString:@""]) {
            point.subtitle = [NSString stringWithFormat:@"Unit %@",l.unit];
        }
        [self.points addObject:point];
    }
    
   // NSMutableArray * annotationsToRemove = [ self.mapView.annotations mutableCopy ] ;
   // [ annotationsToRemove removeObject:self.mapView.userLocation ] ;
    //[ self.mapView removeAnnotations:annotationsToRemove ] ;
    self.pins = [[NSArray alloc] initWithArray:self.points];
    NSLog(@"pins %@",self.pins);
    NSLog(@"points %@",self.points);
    [self.mapView addAnnotations:self.pins];
}

#pragma mark - navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"locationSegue"]) {
        
        IndividualEntryViewController *individualViewControll = (IndividualEntryViewController *)segue.destinationViewController;
        
        individualViewControll.dataWrapper = self.dataWrapper;
        individualViewControll.localDevice = self.localDevice;
        individualViewControll.location = self.selectedLocation;
        
        
    }
}

#pragma mark - searchbar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    self.searchResultLocations = [self.dataWrapper searchLocation:searchBar.text];
    NSLog(@"%@",self.searchResultLocations);
    
    [self searchResultPinAction: self.searchResultLocations];
    [searchBar resignFirstResponder];
}

- (void) searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    
    [searchBar resignFirstResponder];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    [searchBar resignFirstResponder];
}

@end
