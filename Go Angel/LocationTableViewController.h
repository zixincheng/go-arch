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
}

@end
