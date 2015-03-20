//
//  OverviewViewController.m
//  Go Arch
//
//  Created by Jake Runzer on 3/19/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "OverviewViewController.h"

@implementation OverviewViewController

- (void) viewDidLoad {
  
  // init vars
  appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  
  [_lblAddress setText:_location.name];
  [_lblCityState setText:[NSString stringWithFormat:@"%@, %@", _location.city, _location.province]];
  [_lblCountry setText:_location.country];
  
  _photos = [self.dataWrapper getPhotosWithLocation:self.localDevice.remoteId location:self.location];
  [self setCoverPhoto];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setCoverPhoto) name:@"CoverPhotoChange" object:nil];
}

- (void) setCoverPhoto {
  if (self.photos.count != 0) {
    CSPhoto * coverPhoto = [self.dataWrapper getCoverPhoto:self.localDevice.remoteId location:self.location];
    if (coverPhoto == nil) {
      coverPhoto = [self.photos objectAtIndex:0];
    }
    
    [appDelegate.mediaLoader loadFullScreenImage:coverPhoto completionHandler:^(UIImage *image) {
      dispatch_async(dispatch_get_main_queue(), ^{
        _coverImageView.image = image;
      });
    }];
    
    [self.coinsorter updateMeta:coverPhoto entity:@"home" value:@"1"];
  }
}

- (void) viewWillAppear:(BOOL)animated {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"SetRightButtonText" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Edit", @"text", nil]];
}

@end
