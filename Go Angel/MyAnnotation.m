//
//  MyAnnotation.m
//  Go Arch
//
//  Created by zcheng on 2015-03-09.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "MyAnnotation.h"

@implementation MyAnnotation

@synthesize coordinate;
@synthesize title;
@synthesize subtitle;

- (NSString *)subtitle{
    return nil;
}

- (NSString *)title{
    return title;
}
-(id)init {
    return self;
}
-(id)initWithCoordinate:(CLLocationCoordinate2D)coord {
    coordinate=coord;
    return self;
}

-(CLLocationCoordinate2D)coord
{
    return coordinate;
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    coordinate = newCoordinate;
}
-(void) dealloc {
    title = nil;
    subtitle = nil;
}
@end
