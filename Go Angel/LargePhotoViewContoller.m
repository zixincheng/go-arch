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
#define SCROLL_VEW      5
#define NAME_TAG        6

#define ROW_HEIGHT      220

@implementation LargePhotoViewContoller

- (void) viewDidLoad {
  appDelegate = [[UIApplication sharedApplication] delegate];
  account = appDelegate.account;
  self.dataWrapper = appDelegate.dataWrapper;
  self.localDevice = [self.dataWrapper getDevice:account.cid];
  
  //[self loadLocations];
}

- (void) viewDidAppear:(BOOL)animated {
  [self.navigationController setToolbarHidden:NO animated:NO];
}

- (void) loadLocations {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    NSMutableArray *ls = [_dataWrapper getAllAlbums];
    
    if (!self.albums || ls.count != self.albums.count) {
      self.albums = ls;
      dispatch_async(dispatch_get_main_queue(), ^{
        [_tableView reloadData];
      });
    }
  });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"singleLocationSegue"]) {
    SingleLocationViewController *singleLocContoller = (SingleLocationViewController *)segue.destinationViewController;
    singleLocContoller.dataWrapper = self.dataWrapper;
    singleLocContoller.localDevice = self.localDevice;
    singleLocContoller.album = self.selectedAlbum;
    singleLocContoller.coinsorter = [[Coinsorter alloc] initWithWrapper:_dataWrapper];
    [singleLocContoller setHidesBottomBarWhenPushed:YES];
    
    NSString *title = [NSString stringWithFormat:@"%@", self.selectedAlbum.entry.location.sublocation];
    singleLocContoller.title = title;
    
  }
}

- (void) singleTap:(UITapGestureRecognizer*)sender {
  UIView *view = sender.view;
//  _selectedLocation = _locations[view.tag];
//  [self performSegueWithIdentifier:@"singleLocationSegue" sender:self];
}

# pragma mark - table view delegate/data source methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PHOTO_CELL];
  
  // get all the views by tag
  UIScrollView *scrollView      = (UIScrollView *)[cell viewWithTag:SCROLL_VEW];
  UIImageView *coverImageView   = (UIImageView *)[cell viewWithTag:IMAGE_TAG];
  UILabel *lblAddress           = (UILabel *)[cell viewWithTag:ADDRESS_TAG];
  UILabel *lblCityState         = (UILabel *)[cell viewWithTag:CITY_STATE_TAG];
  UILabel *lblCount             = (UILabel *)[cell viewWithTag:COUNT_TAG];
  UILabel *lblname             = (UILabel *)[cell viewWithTag:NAME_TAG];
  
  // disalbe tap on scroll view and set pan gesture on cell instead
  [scrollView setUserInteractionEnabled:NO];
  [cell addGestureRecognizer:scrollView.panGestureRecognizer];
  
  // get location
  CSAlbum *a = [self.albums objectAtIndex:indexPath.row];
  
  // load all photos for this locaiton to get count
  NSMutableArray *photos = [_dataWrapper getPhotosWithAlbum:_localDevice.remoteId album:a];
  int count = photos.count;
  NSString *text = [NSString stringWithFormat:@"%d Photos", count];
  
  // get home photo from db
  CSPhoto *homePhoto = [_dataWrapper getCoverPhoto:_localDevice.remoteId album:a];
  
  if (!homePhoto && photos.count > 0) {
    homePhoto = [photos objectAtIndex:0];
  }
  
  // readjust frame of cover image based on size of scroll view
  // do this because scroll view is what is used to determine page size
  CGRect adjustedFrame = coverImageView.frame;
  adjustedFrame.size.width = scrollView.frame.size.width;
  adjustedFrame.origin.x = 0;
  [coverImageView setFrame:adjustedFrame];
  coverImageView.image = nil;
  // load the full screen image into the image view
  [appDelegate.mediaLoader loadThumbnail:homePhoto completionHandler:^(UIImage* image) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [coverImageView setImage:image];
    });
  }];
  
  // loop through all photos
  int index = 0;
  for (CSPhoto *p in photos) {
    
    // don't display home photo twice
    if ([p.imageURL isEqualToString:homePhoto.imageURL]) {
      continue;
    }
    
    // create new frame based on cover view (the front image)
    CGRect newFrame = coverImageView.frame;
    newFrame.origin.x = newFrame.origin.x + ((index + 1) * newFrame.size.width);
    
//    NSLog(@"cover frame x: %f, cover frame width: %f", coverImageView.frame.origin.x, coverImageView.frame.size.width);
    
    UIImageView *view = [[UIImageView alloc] initWithFrame:newFrame];
    [view setContentMode:UIViewContentModeScaleAspectFill];
    [view setClipsToBounds:YES];
    [appDelegate.mediaLoader loadThumbnail:p completionHandler:^(UIImage* image) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [view setImage:image];
      });
    }];
    
    [scrollView addSubview:view];
//    NSLog(@"view width: %f, x: %f", view.frame.size.width, view.frame.origin.x);
    index += 1;
  }
  
  // set scroll view content size based on how many images are in album
  int totalWidth = coverImageView.frame.size.width + (coverImageView.frame.size.width * index);
//  NSLog(@"index: %d, total width: %d", index, totalWidth);
  [scrollView setContentSize:CGSizeMake(totalWidth, coverImageView.frame.size.height)];
  
  [lblCount setText:text];
  [lblname setText:a.name];
  [lblAddress setText:a.entry.location.sublocation];
  [lblCityState setText:[NSString stringWithFormat:@"%@, %@", a.entry.location.city, a.entry.location.province]];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  self.selectedAlbum = _albums[[indexPath row]];
  [self performSegueWithIdentifier:@"singleLocationSegue" sender:self];
  
  // Deselect
  [_tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return ROW_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return _albums.count;
}

@end
