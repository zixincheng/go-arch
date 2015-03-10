//
//  MyAnnotation.h
//  Go Arch
//
//  Created by zcheng on 2015-03-09.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <MapKit/MKShape.h>
#import <MapKit/MKFoundation.h>
#import <CoreLocation/CLLocation.h>

@interface MyAnnotation : NSObject <MKAnnotation>{
    
    CLLocationCoordinate2D coordinate;
}

- (id)initWithCoordinate:(CLLocationCoordinate2D)coord;
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;

@end
