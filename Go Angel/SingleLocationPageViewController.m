//
//  SingleLocationPageViewController.m
//  Go Arch
//
//  Created by Jake Runzer on 3/19/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "SingleLocationPageViewController.h"

#define OVERVIEW @"single_location_overview"
#define DETAILS  @"single_location_details"
#define PHOTOS   @"single_location_photos"

@implementation SingleLocationPageViewController

- (void) viewDidLoad {
  self.dataSource = self;
  self.delegate = self;
  
  [self setViewControllers:@[[self prepareOverview]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
  
  // load other view after first one loaded
  [self prepareDetails];
  [self preparePhotos];
}

# pragma mark - prepare and init all custom views

- (OverviewViewController *) prepareOverview {
  if (_overviewController == nil) {
    _overviewController = (OverviewViewController *)[self.storyboard instantiateViewControllerWithIdentifier:OVERVIEW];
    _overviewController.coinsorter = _coinsorter;
    _overviewController.dataWrapper = _dataWrapper;
    _overviewController.localDevice = _localDevice;
    _overviewController.album = _album;
  }
  return _overviewController;
}

- (DetailsViewController *) prepareDetails {
  if (_detailsController == nil) {
    _detailsController = (DetailsViewController *)[self.storyboard instantiateViewControllerWithIdentifier:DETAILS];
    _detailsController.coinsorter = _coinsorter;
    _detailsController.dataWrapper = _dataWrapper;
    _detailsController.localDevice = _localDevice;
    _detailsController.album = _album;
  }
  return _detailsController;
}

- (PhotosViewController *) preparePhotos {
  if (_photosController == nil) {
    _photosController = (PhotosViewController *)[self.storyboard instantiateViewControllerWithIdentifier:PHOTOS];
    _photosController.coinsorter = _coinsorter;
    _photosController.dataWrapper = _dataWrapper;
    _photosController.localDevice = _localDevice;
    _photosController.album = _album;
  }
  return _photosController;
}

- (void) pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
  UIViewController *currentController = [[pageViewController viewControllers] objectAtIndex:0];
  int index = 0;
  if ([currentController isKindOfClass:[OverviewViewController class]]) {
    index = 0;
  } else if ([currentController isKindOfClass:[DetailsViewController class]]) {
    index = 1;
  } else if ([currentController isKindOfClass:[PhotosViewController class]]) {
    index = 2;
  }
  [_segmentControl setSelectedSegmentIndex:index];
  [_pageControl setCurrentPage:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
  if ([viewController isKindOfClass:[OverviewViewController class]]) {
    return nil;
  } else if ([viewController isKindOfClass:[DetailsViewController class]]) {
    return [self prepareOverview];
  } else if ([viewController isKindOfClass:[PhotosViewController class]]) {
    return [self prepareDetails];
  }
  return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
  if ([viewController isKindOfClass:[OverviewViewController class]]) {
    return [self prepareDetails];
  } else if ([viewController isKindOfClass:[DetailsViewController class]]) {
    return [self preparePhotos];
  } else if ([viewController isKindOfClass:[PhotosViewController class]]) {
    return nil;
  }
  return nil;
}

- (void) segmentChanged:(id)sender {
  
  int clickedSegment = [sender selectedSegmentIndex];

  UIViewController *con;
  if (clickedSegment == 0) {
    con = [self prepareOverview];
  } else if (clickedSegment == 1) {
    con = [self prepareDetails];
  } else if (clickedSegment == 2) {
    con = [self preparePhotos];
  }
  [self setViewControllers:@[con] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}

@end
