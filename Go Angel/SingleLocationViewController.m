//
//  SingleLocationViewController.m
//  Go Arch
//
//  Created by Jake Runzer on 3/18/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "SingleLocationViewController.h"

@implementation SingleLocationViewController {
  
  BOOL enableEdit;
}

- (void) viewDidLoad {
  
  self.mainCameraBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraButtonPressed:)];
  self.flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  self.toolbarItems = [NSArray arrayWithObjects:self.flexibleSpace, self.mainCameraBtn, self.flexibleSpace, nil];

  [self.navigationController setToolbarHidden:NO];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  NSString * segueName = segue.identifier;
  if ([segueName isEqualToString: @"location_page_embed"]) {
    _pageController = (SingleLocationPageViewController *) [segue destinationViewController];
    _pageController.segmentControl = _segmentControl;
  }
}

- (IBAction)segmentChanged:(id)sender {
  if (_pageController != nil) {
    [_pageController segmentChanged:sender];
  }
}

- (void) cameraButtonPressed:(id) sender {
  
}

@end
