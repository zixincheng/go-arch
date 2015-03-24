//
//  LargePhotoViewContoller.m
//  Go Arch
//
//  Created by Jake Runzer on 3/23/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "LargePhotoViewContoller.h"

#define PHOTO_CELL @"LargePhotoCell"
#define IMAGE_TAG       1
#define ADDRESS_TAG     2
#define CITY_STATE_TAG  3
#define COUNT_TAG       4

@implementation LargePhotoViewContoller

- (void) viewDidLoad {
  appDelegate = [[UIApplication sharedApplication] delegate];
  account = appDelegate.account;
  self.dataWrapper = appDelegate.dataWrapper;
  self.localDevice = [self.dataWrapper getDevice:account.cid];
  
  [self loadLocations];
}

- (void) viewDidAppear:(BOOL)animated {
  
}

- (void) loadLocations {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    NSMutableArray *ls = [_dataWrapper getLocations];
    
    if (!_locations || ls.count != _locations.count) {
      _locations = ls;
      dispatch_async(dispatch_get_main_queue(), ^{
        [_tableView reloadData];
      });
    }
  });
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PHOTO_CELL];
  
  UIImageView *imageView  = (UIImageView *)[cell viewWithTag:IMAGE_TAG];
  UILabel *lblAddress     = (UILabel *)[cell viewWithTag:ADDRESS_TAG];
  UILabel *lblCityState   = (UILabel *)[cell viewWithTag:CITY_STATE_TAG];
  UILabel *lblCount       = (UILabel *)[cell viewWithTag:COUNT_TAG];
  
  CSLocation *l = [_locations objectAtIndex:indexPath.row];
  
  // load all photos for this locaiton to get count
  NSMutableArray *photos = [_dataWrapper getPhotosWithLocation:_localDevice.remoteId location:l];
  int count = photos.count;
  NSString *text = [NSString stringWithFormat:@"%d Photos", count];

  // get home photo from db
  CSPhoto *homePhoto = [_dataWrapper getCoverPhoto:_localDevice.remoteId location:l];
  
  if (!homePhoto && photos.count > 0) {
    homePhoto = [photos objectAtIndex:0];
  }

  // load the full screen image into the image view
  [appDelegate.mediaLoader loadFullScreenImage:homePhoto completionHandler:^(UIImage* image) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [imageView setImage:image];
    });
  }];

  [lblCount setText:text];
  
  [lblAddress setText:l.name];
  [lblCityState setText:[NSString stringWithFormat:@"%@, %@", l.city, l.province]];
  
  return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 200;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return _locations.count;
}

@end
