//
//  DetailsViewController.m
//  Go Arch
//
//  Created by Jake Runzer on 3/19/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "DetailsViewController.h"

#define KEY_FIELD       1
#define VALUE_FIELD     2

@implementation DetailsViewController {
  BOOL hasCover;
}

- (void) viewDidLoad {
  
  appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  
  _photos = [self.dataWrapper getPhotosWithLocation:self.localDevice.remoteId location:self.location];
  
  [self setCoverPhoto];
  [self setupKeyValues];
  
  // register for notifications
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setCoverPhoto) name:@"CoverPhotoChange" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePhotos) name:@"addNewPhoto" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePhotos) name:@"PhotoDeleted" object:nil];
}

- (void) updatePhotos {
  _photos = [self.dataWrapper getPhotosWithLocation:self.localDevice.remoteId location:self.location];
  
  if (!hasCover && _photos.count > 0) {
    [self setCoverPhoto];
  }
  
  [self setupKeyValues];
}

- (void) setupKeyValues {
  _sections = [[NSMutableArray alloc] initWithObjects:@"Location", @"HEADER 2", @"Building", nil];
  
  // location key/values
  
  _locationKeys = [[NSMutableArray alloc] initWithObjects:
                   @"Address",
                   @"City",
                   @"State",
                   @"Country",
                   nil];
  
  _locationValues = [[NSMutableArray alloc] initWithObjects:
                     _location.name,
                     _location.city,
                     _location.province,
                     _location.country,
                     nil];
  
  // details key/values
  
  _detailsKeys = [[NSMutableArray alloc] initWithObjects:
                  @"Photos",
                  @"Price",
                  @"Type",
                  @"Neighborhood",
                  @"Status",
                  nil];
  
  _detailsValues = [[NSMutableArray alloc] initWithObjects:
                    [NSString stringWithFormat:@"%d", _photos.count],
                    @"1 000 000",
                    @"Residential",
                    @"Family",
                    @"For Sale",
                    nil];
  
  // building key/values
  
  _buildingKeys = [[NSMutableArray alloc] initWithObjects:
                   @"sq/ft",
                   @"# of Baths",
                   @"# of Beds",
                   @"mls #",
                   nil];
  
  _buildingValues = [[NSMutableArray alloc] initWithObjects:
                     @"20",
                     @"1",
                     @"1",
                     @"81789175098347690287",
                     nil];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [_tableView reloadData];
  });
}

// set the cover photo that is displayed
- (void) setCoverPhoto {
  if (_photos.count <= 0) {
    hasCover = NO;
    return;
  }
  CSPhoto * coverPhoto = [self.dataWrapper getCoverPhoto:self.localDevice.remoteId location:self.location];
  if (coverPhoto == nil) {
    coverPhoto = [self.photos objectAtIndex:0];
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
  switch (section) {
    case 0:
      return _locationValues.count;
    case 1:
      return _detailsValues.count;
    case 2:
      return _buildingValues.count;
    default:
      break;
  }
  return _locationKeys.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return _sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  return [_sections objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetailsCell"];

  int section = indexPath.section;
  
  NSMutableArray *keys;
  NSMutableArray *values;
  
  switch (section) {
    case 0:
      keys = _locationKeys;
      values = _locationValues;
      break;
    case 1:
      keys = _detailsKeys;
      values = _detailsValues;
      break;
    case 2:
      keys = _buildingKeys;
      values = _buildingValues;
      break;
    default:
      break;
  }
  
  NSString *key = [keys objectAtIndex:[indexPath row]];
  NSString *value = [values objectAtIndex:[indexPath row]];
  
  
  UILabel *keyField = (UILabel *)[cell viewWithTag:1];
  UILabel *valueField = (UILabel *)[cell viewWithTag:2];

  [keyField setText:key];
  [valueField setText:value];
  
  NSLog(@"key: %@, value: %@", key, value);
  
  return cell;
}

@end
