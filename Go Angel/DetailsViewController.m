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
    BOOL atMaps;
}

- (void) viewDidLoad {
    
    NSLog(@"load");
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _photos = [self.dataWrapper getPhotosWithAlbum:self.localDevice.remoteId album:self.album];
    
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
        _embedController.album = _album;
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
    _photos = [self.dataWrapper getPhotosWithAlbum:self.localDevice.remoteId album:self.album];
    
    if (!hasCover && _photos.count > 0) {
        [self setCoverPhoto];
    }
}

- (void) coverUpdated {
    _coverPhoto = [self.dataWrapper getCoverPhoto:self.localDevice.remoteId album:self.album];
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
        _coverPhoto = [self.dataWrapper getCoverPhoto:self.localDevice.remoteId album:self.album];
        if (_coverPhoto == nil) {
            _coverPhoto = [self.photos objectAtIndex:0];
        }
        
        hasCover = YES;
    }
}

- (void) goingToMapsAddLocation {
    atMaps = YES;
}

- (void) enableEditing {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SetRightButtonText" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Save", @"text", nil]];
    isEditing = YES;
    atMaps = NO;
    
    if (_embedController) {
        [_embedController setEditEnabled:YES];
    }
}

- (void) disableEditing {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SetRightButtonText" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Edit", @"text", nil]];
    isEditing = NO;
    atMaps = NO;
    
    if (_embedController) {
        [_embedController setEditEnabled:NO];
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editPressed) name:@"RightButtonPressed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goingToMapsAddLocation) name:@"AddNewLocationNotification" object:nil];
    
    if (!hasCover) {
        [self setCoverPhoto];
    }
    
    if (atMaps) {
        atMaps = NO;
        [self enableEditing];
    } else {
        [self disableEditing];
    }
}

- (void) viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RightButtonPressed" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AddNewLocationNotification" object:nil];
}

- (void) saveLocationDetails {
    
    //  NSMutableArray *changedKeys = [[NSMutableArray alloc] init];
    //  NSMutableArray *changeValues = [[NSMutableArray alloc] init];
    //
    //
    //  NSNumberFormatter *format = [[NSNumberFormatter alloc]init];
    //  format.numberStyle = NSNumberFormatterDecimalStyle;
    //
    //  // find all of the keys and values of text fields that have changed
    //  // then make api calls to update all photos belong to this location
    //  // then save data in db
    //
    //  if (![_location.name isEqualToString:_embedController.addressTextField.text]) {
    //    NSLog(@"address name differetn");
    //  }
    //  if (![_location.city isEqualToString:_embedController.cityTextField.text]) {
    //
    //  }
    //  if (![_location.province isEqualToString:_embedController.stateTextField.text]) {
    //
    //  }
    //  if (![_location.country isEqualToString:_embedController.countryTextField.text]) {
    //
    //  }
    //  if (![_location.postCode isEqualToString:_embedController.postcodeTextField.text]) {
    //
    //  }
    //  if (![_location.locationMeta.tag isEqualToString:_embedController.tagTextField.text]) {
    //
    //  }
    //  if (![_location.locationMeta.price doubleValue] == [[format numberFromString:_embedController.priceTextField.text] doubleValue]) {
    //
    //  }
    //  if (![_location.locationMeta.yearBuilt isEqualToString:_embedController.yearBuiltTextField.text]) {
    //
    //  }
    //  if (![[_location.locationMeta.buildingSqft stringValue] isEqualToString:_embedController.buildingSqftTextField.text]) {
    //
    //  }
    //  if (![_location.locationMeta.mls isEqualToString:_embedController.mlsTextField.text]) {
    //
    //  }
    //
    
    if ([self.album.entry.location.sublocation isEqualToString:@""] || [self.album.entry.location.city isEqualToString:@""] || [self.album.entry.location.province isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ERROR" message:@"Address or City or State Can't be Empty" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        [self enableEditing];
    } else {
        [appDelegate.dataWrapper updateAlbum:self.album];
        [self.coinsorter updateAlbum:self.album];
        NSLog(@"updated location");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationMetadataUpdate" object:nil];
    }
}

- (void) editPressed {
    if (!isEditing) {
        [self enableEditing];
    } else {
        [self disableEditing];
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
