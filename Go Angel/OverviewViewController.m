//
//  OverviewViewController.m
//  Go Arch
//
//  Created by Jake Runzer on 3/19/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "OverviewViewController.h"

@implementation OverviewViewController {
  BOOL hasCover;
}

- (void) viewDidLoad {
  
  // init vars
  appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  
  [self setValues];
  
  // set current properties of view
  [self updateCount];
  [self setCoverPhoto];
  
  // register for notifications from parent controller
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setCoverPhoto) name:@"CoverPhotoChange" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoAdded) name:@"addNewPhoto" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoDeleted) name:@"PhotoDeleted" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setValues) name:@"LocationMetadataUpdate" object:nil];
}

- (void) setValues {
  NSString *cityState = [NSString stringWithFormat:@"%@, %@", self.album.entry.location.city, self.album.entry.location.province];
  NSString *price = [self.album.entry formatPrice:self.album.entry.price];
  NSString *buildingSqft = [NSString stringWithFormat:@"%@ sq. ft.", self.album.entry.buildingSqft.stringValue];
  NSString *landSqft = [NSString stringWithFormat:@"%@ sq. ft.", self.album.entry.landSqft.stringValue];
  NSString *beds = [NSString stringWithFormat:@"%@", self.album.entry.bed];
  NSString *baths = [NSString stringWithFormat:@"%@", self.album.entry.bath];
  
  if (!self.album.entry.bed) {
    beds = @"";
  }
  if (!self.album.entry.bath) {
    baths = @"";
  }
  if (!self.album.entry.buildingSqft) {
    buildingSqft = @"";
  }
  if (!self.album.entry.landSqft) {
    landSqft = @"";
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [_lblAddress setText:self.album.entry.location.sublocation];
    [_lblCityState setText:cityState];
    [_lblCountry setText:self.album.entry.location.countryCode];
    [_lblPrice setText:price];
    [_lblFloor setText:buildingSqft];
    [_lblLot setText:landSqft];
    [_lblBed setText:beds];
    [_lblBath setText:baths];
    
  });
}

// update photo count labels
- (void) updateCount {
  _photos = [self.dataWrapper getPhotosWithAlbum:self.localDevice.remoteId album:self.album];
  dispatch_async(dispatch_get_main_queue(), ^{
    [_lblPhotosTotal setText:[NSString stringWithFormat:@"%lu Photos", (unsigned long)_photos.count]];
  });
}

// when photo is deleted, just update the photo count from db
- (void) photoDeleted {
  [self updateCount];
}

//if new photo added and we don't have a cover photo yet, set one
- (void) photoAdded {
  [self updateCount];
  if (!hasCover) {
    hasCover = YES;
    [self setCoverPhoto];
  }
}

// set the cover photo that is displayed
- (void) setCoverPhoto {
  if (self.photos.count != 0) {
    hasCover = YES;
    CSPhoto * coverPhoto = [self.dataWrapper getCoverPhoto:self.localDevice.remoteId album:self.album];
    if (coverPhoto == nil) {
      coverPhoto = [self.photos objectAtIndex:0];
    }
    
    [appDelegate.mediaLoader loadFullScreenImage:coverPhoto completionHandler:^(UIImage *image) {
      dispatch_async(dispatch_get_main_queue(), ^{
        _coverImageView.image = image;
      });
    }];
    
   // [self.coinsorter updateMeta:coverPhoto entity:@"home" value:@"1"];
  } else {
    hasCover = NO;
  }
}

- (void) viewWillAppear:(BOOL)animated {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"SetRightButtonText" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"", @"text", nil]];
}

@end
