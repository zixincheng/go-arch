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
  self.deleteBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteBtnPressed)];
  self.shareBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareAction)];
  self.toolbarItems = [NSArray arrayWithObjects:self.flexibleSpace, self.mainCameraBtn, self.flexibleSpace, nil];

  [self.navigationController setToolbarHidden:NO];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRightButtonText:) name:@"SetRightButtonText" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showShareDelete:) name:@"ShowShareDelete" object:nil];
}

- (void) showShareDelete: (NSNotification *)n {
  if ([n userInfo] && [n.userInfo objectForKey:@"show"]) {
    NSString *show = [n.userInfo objectForKey:@"show"];
      self.toolbarItems = [NSArray arrayWithObjects:self.shareBtn, self.flexibleSpace, self.deleteBtn, nil];
    if ([show isEqualToString:@"yes"]) {
    } else {
      self.toolbarItems = [NSArray arrayWithObjects:self.flexibleSpace, self.mainCameraBtn, self.flexibleSpace, nil];
    }
  }
}

- (void) setRightButtonText: (NSNotification *)n {
  if ([n userInfo] && [n.userInfo objectForKey:@"text"]) {
    NSString *text = [n.userInfo objectForKey:@"text"];
    _rightButton.title = text;
  }
}

- (void) deleteBtnPressed {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"DeleteButtonPressed" object:nil];
}

- (void) shareAction {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ShareButtonPressed" object:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  NSString * segueName = segue.identifier;
  if ([segueName isEqualToString: @"location_page_embed"]) {
    _pageController = (SingleLocationPageViewController *) [segue destinationViewController];
    _pageController.segmentControl = _segmentControl;
    _pageController.coinsorter = _coinsorter;
    _pageController.dataWrapper = _dataWrapper;
    _pageController.localDevice = _localDevice;
    _pageController.location = _location;
  }
}

- (IBAction)segmentChanged:(id)sender {
  if (_pageController != nil) {
    [_pageController segmentChanged:sender];
  }
}

- (void) cameraButtonPressed:(id) sender {
  
}

- (IBAction)rightButtonPressed:(id)sender {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"RightButtonPressed" object:nil];
}

@end
