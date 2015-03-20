//
//  DetailsViewController.m
//  Go Arch
//
//  Created by Jake Runzer on 3/19/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "DetailsViewController.h"

@implementation DetailsViewController {
  BOOL hasCover;
}

- (void) viewDidLoad {
  
  appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  
  [self setCoverPhoto];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setCoverPhoto) name:@"CoverPhotoChange" object:nil];
}

// set the cover photo that is displayed
- (void) setCoverPhoto {
    CSPhoto * coverPhoto = [self.dataWrapper getCoverPhoto:self.localDevice.remoteId location:self.location];
    if (coverPhoto == nil) {
      hasCover = NO;
      return;
    }
  
  hasCover = YES;
  [appDelegate.mediaLoader loadFullScreenImage:coverPhoto completionHandler:^(UIImage *image) {
    dispatch_async(dispatch_get_main_queue(), ^{
      _coverImageView.image = image;
    });
  }];
}

- (void) viewWillAppear:(BOOL)animated {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"SetRightButtonText" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"", @"text", nil]];
  
  if (!hasCover) {
    [self setCoverPhoto];
  }
}

# pragma mark - table view methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 1;
}

@end
