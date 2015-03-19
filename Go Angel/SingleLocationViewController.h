//
//  SingleLocationViewController.h
//  Go Arch
//
//  Created by Jake Runzer on 3/18/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "CSLocation.h"
#import "CoreDataWrapper.h"
#import "CSDevice.h"
#import "SingleLocationPageViewController.h"

@interface SingleLocationViewController : UIViewController {
}

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) CSLocation *location;
@property (nonatomic, strong) CSDevice *localDevice;

@property (nonatomic, strong) UIBarButtonItem *flexibleSpace;
@property (nonatomic, strong) UIBarButtonItem *mainCameraBtn;
@property (nonatomic, strong) UIBarButtonItem *deleteBtn;
@property (nonatomic, strong) UIBarButtonItem *shareBtn;

@property (nonatomic, assign) BOOL loadCamera;
@property (nonatomic, assign) BOOL saveInAlbum;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic, strong) SingleLocationPageViewController *pageController;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *rightButton;

@end
