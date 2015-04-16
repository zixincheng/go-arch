//
//  SingleLocationPageViewController.h
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
#import "OverviewViewController.h"
#import "DetailsViewController.h"
#import "PhotosViewController.h"

@interface SingleLocationPageViewController : UIPageViewController<UIPageViewControllerDataSource, UIPageViewControllerDelegate>

- (void) segmentChanged:(id)sender;

@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
//@property (nonatomic, strong) CSLocation *location;
@property (nonatomic, strong) CSAlbum *album;
@property (nonatomic, strong) CSDevice *localDevice;

@property (nonatomic, strong) OverviewViewController *overviewController;
@property (nonatomic, strong) DetailsViewController *detailsController;
@property (nonatomic, strong) PhotosViewController *photosController;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@end
