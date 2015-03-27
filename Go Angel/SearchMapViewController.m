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

@synthesize delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // setup objects
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    account = appDelegate.account;
    self.dataWrapper = appDelegate.dataWrapper;
    self.localDevice = [self.dataWrapper getDevice:account.cid];

    //init location auto-dectect
    
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = 10;
    
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];

    // Do any additional setup after loading the view.
}
- (void)viewWillAppear:(BOOL)animated {
    //[self.navigationController setToolbarHidden:YES animated:NO];
}

-(void) viewDidAppear:(BOOL)animated {
    // setup pins for each location in map
    self.locations = [self.dataWrapper getLocations];
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
    
    self.pins = [[NSArray alloc] initWithArray:self.points];
    [self.locationManager startUpdatingLocation];
    
    if ([self.locationManager
         respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.mapView addAnnotations:self.pins];
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
}
-(void) viewDidDisappear:(BOOL)animated {
    [self.mapView removeAnnotations:self.pins];
    [self stopStandardUpdates];
     NSLog(@"stopped watching location");
}

-(void)dismissKeyboard {
    [self.searchBar resignFirstResponder];
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

// stop updating location
- (void)stopStandardUpdates {
    if (self.locationManager != nil) {
        [self.locationManager stopUpdatingLocation];
    }
}
/*
- (void) zoomToUserLocation : (MKUserLocation *) location {
    
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 1609.344, 1609.344);
    [self.mapView setRegion:viewRegion animated:YES];
}
*/

#pragma mark - mapView delegate

-(void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    MKPointAnnotation *point  = view.annotation;
    NSInteger index = [self.pins indexOfObject:point];
    self.selectedLocation = [self.locations objectAtIndex:index];
    if ([view.annotation isKindOfClass:[MKPointAnnotation class]]) {
        self.callOutAnnotation = [[MyAnnotation alloc]initWithCoordinate:view.annotation.coordinate];
        [self.mapView addAnnotation:self.callOutAnnotation];
        [self.mapView setCenterCoordinate:self.callOutAnnotation.coordinate animated:YES];
    } else {
        NSLog(@"click here ");
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if (self.callOutAnnotation) {
        if (self.callOutAnnotation.coordinate.latitude == view.annotation.coordinate.latitude&&
            self.callOutAnnotation.coordinate.longitude == view.annotation.coordinate.longitude) {
            [mapView removeAnnotation:self.callOutAnnotation];
            self.callOutAnnotation = nil;
        }
    }
}

-(void) mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    
    //[self zoomToUserLocation:userLocation];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"Location";
    
    
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
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
        pin.canShowCallout = NO;
        pin.animatesDrop = YES;
        
        return pin;


    } else if ([annotation isKindOfClass:[MyAnnotation class]]){
        MyAnnotationView *annotationView = (MyAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"CalloutView"];
        annotationView = [[MyAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CalloutView" delegate:self];
        
        CalloutViewCell *cell = [[[NSBundle mainBundle] loadNibNamed:@"CalloutViewCell" owner:self options:nil] objectAtIndex:0];
        cell.priceLabel.text = [self.selectedLocation formatPrice:self.selectedLocation.locationMeta.price];
        cell.addressLabel.text = [NSString stringWithFormat:@"%@, %@, %@, %@", self.selectedLocation.name,self.selectedLocation.city,self.selectedLocation.province,self.selectedLocation.countryCode];
        if (self.selectedLocation.locationMeta.bed != nil) {
                    cell.bedLabel.text = [NSString stringWithFormat:@"%@ BD",self.selectedLocation.locationMeta.bed];
        }
        if (self.selectedLocation.locationMeta.bath != nil) {
            cell.bathLabel.text = [NSString stringWithFormat:@"%@ BD",self.selectedLocation.locationMeta.bath];
        }
        if (self.selectedLocation.locationMeta.buildingSqft != nil) {
            cell.buildingSQFT.text = [NSString stringWithFormat:@"%@ sq. ft.", self.selectedLocation.locationMeta.buildingSqft.stringValue];
        }
        if (self.selectedLocation.locationMeta.landSqft != nil) {
            cell.landSQFT.text = [NSString stringWithFormat:@"%@ sq. ft.", self.selectedLocation.locationMeta.landSqft.stringValue];
        }
        CSPhoto *p = [self.dataWrapper getCoverPhoto:self.localDevice.remoteId location:self.selectedLocation];
        if (p !=nil) {
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            [appDelegate.mediaLoader loadThumbnail:p completionHandler:^(UIImage *image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImage *newImage = [self resizeImage:image];
                    UIView *imgView = [[UIImageView alloc]initWithImage:newImage];
                    [cell.coverImage addSubview:imgView];
                });
            }];
            
        }
        
        [annotationView.contentView addSubview:cell];
        return annotationView;
    }
    return nil;
}

- (void)didSelectAnnotationView:(MyAnnotationView *)view
{
    //MyAnnotationView *annotation = (MyAnnotationView *)view.annotation;
    [self performSegueWithIdentifier:@"locationSegue" sender:self];
    
    [self mapView:_mapView didDeselectAnnotationView:view];
}

-(UIImage *)resizeImage: (UIImage *) image{
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0, 0, 93, 77)];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    // free the context
    UIGraphicsEndImageContext();
    return image;
    
}

-(void)mapView:(MKMapView *)mapView annotationView:(MyAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
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

      SingleLocationViewController *singleLocContoller = (SingleLocationViewController *)segue.destinationViewController;
      singleLocContoller.dataWrapper = self.dataWrapper;
      singleLocContoller.localDevice = self.localDevice;
      singleLocContoller.location = self.selectedLocation;
      singleLocContoller.coinsorter = [[Coinsorter alloc] initWithWrapper:self.dataWrapper];
      [singleLocContoller setHidesBottomBarWhenPushed:YES];
      
      NSString *title;
      if (self.selectedLocation.unit !=nil) {
        title = [NSString stringWithFormat:@"%@ - %@",self.selectedLocation.unit, self.selectedLocation.name];
      } else {
        title = [NSString stringWithFormat:@"%@", self.selectedLocation.name];
      }
      singleLocContoller.title = title;
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
