
//
//  DetailsViewController.h
//  Go Arch
//
//  Created by Jake Runzer on 3/19/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Coinsorter.h"
#import "CoreDataWrapper.h"
#import "CSDevice.h"
#import "CSLocation.h"
#import "AppDelegate.h"
#import "CSPhoto.h"

@interface DetailsViewController : UIViewController

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) CSLocation *location;
@property (nonatomic, strong) CSDevice *localDevice;

@end
