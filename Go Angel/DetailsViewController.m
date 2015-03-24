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
  BOOL isEditing;
}

- (void) viewDidLoad {
  
  appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  
  _photos = [self.dataWrapper getPhotosWithLocation:self.localDevice.remoteId location:self.location];
  
  [self setCoverPhoto];
  
  // register for notifications
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coverUpdated) name:@"CoverPhotoChange" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePhotos) name:@"addNewPhoto" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePhotos) name:@"PhotoDeleted" object:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//  detailsEmbedSegue
  NSString * segueName = segue.identifier;
  
  // the segue for embeding a controller into a container view
  // give the container view controller all needed vars
  if ([segueName isEqualToString: @"detailsEmbedSegue"]) {
    _embedController = (AddNewEntryViewController *)[segue destinationViewController];
    _embedController.usePreviousLocation = YES;
    _embedController.location = _location;
    _embedController.localDevice = _localDevice;
    
    if (!_photos) {
      [self updatePhotos];
    }
    if (hasCover) {
      _embedController.coverPhoto = _coverPhoto;
    }
  }
}

- (void) updatePhotos {
  _photos = [self.dataWrapper getPhotosWithLocation:self.localDevice.remoteId location:self.location];
  
  if (!hasCover && _photos.count > 0) {
    [self setCoverPhoto];
  }
}

- (void) coverUpdated {
  _coverPhoto = [self.dataWrapper getCoverPhoto:self.localDevice.remoteId location:self.location];
  if (_embedController) {
    [_embedController updateCoverPhoto:_coverPhoto];
  }
}

- (void) setCoverPhoto {
  if (!hasCover) {
    if (_photos.count <= 0) {
      hasCover = NO;
      return;
    }
    _coverPhoto = [self.dataWrapper getCoverPhoto:self.localDevice.remoteId location:self.location];
    if (_coverPhoto == nil) {
      _coverPhoto = [self.photos objectAtIndex:0];
    }
    
    hasCover = YES;
  }
}

- (void) viewWillAppear:(BOOL)animated {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"SetRightButtonText" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Edit", @"text", nil]];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editPressed) name:@"RightButtonPressed" object:nil];
  
  isEditing = NO;
  if (!hasCover) {
    [self setCoverPhoto];
  }
}

- (void) viewDidDisappear:(BOOL)animated {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RightButtonPressed" object:nil];
}

- (void) saveLocationDetails {
  
}

- (void) editPressed {
  if (!isEditing) {
    isEditing = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SetRightButtonText" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Save", @"text", nil]];
  } else {
    isEditing = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SetRightButtonText" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Edit", @"text", nil]];
    [self saveLocationDetails];
  }
}

# pragma mark - table view methods

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 30;
}

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
  
//  NSLog(@"key: %@, value: %@", key, value);
  
  return cell;
}

@end
