//
//  PhotosViewController.m
//  Go Arch
//
//  Created by Jake Runzer on 3/19/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "PhotosViewController.h"

#define GRID_CELL                   @"ImageCell"
#define kDoubleColumnProbability    40
#define NUMBER_OF_COLUMNS           3
#define SINGLE_PHOTO_SEGUE          @"singleImageSegue"

@implementation PhotosViewController {
  BOOL editEnabled;
  int selected;
}

- (void) viewDidLoad {
  
  // init vars
  appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  editEnabled = NO;

  // set the delegate of the custom layout
//  CellLayout * layout = (id)[self.collectionView collectionViewLayout];
//  layout.delegate = self;
  
  // set collection view data source and delegate
  [_collectionView setDataSource:self];
  [_collectionView setDelegate:self];
  
  // get photos for this location from db
  _photos = [self.dataWrapper getPhotosWithAlbum:self.localDevice.remoteId album:self.album];
 
  // init long press gesture
  // used to set home photo
  UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressRecognizer:)];
  lpgr.minimumPressDuration = 1.0;
  lpgr.delegate = self;
  [self.collectionView addGestureRecognizer:lpgr];
  
  // register for notifications
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deletePressed) name:@"DeleteButtonPressed" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sharePressed) name:@"ShareButtonPressed" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addNewcell) name:@"addNewPhoto" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagStored:) name:@"tagStored" object:nil];
}

// everytime view appears, clear cell selection, set right bar button, and fetchmetadata for photos (update tags)
- (void) viewWillAppear:(BOOL)animated {
  NSLog(@"photo view appear");
  
  [self clearCellSelections];
  editEnabled = NO;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editPressed) name:@"RightButtonPressed" object:nil];
  [self setRightButtonText:@"Select"];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self.coinsorter getMetaPhoto:self.photos];
    [self.coinsorter getMetaVideo:self.photos];
  });
}

- (void) scrollToBottom {
  CGPoint bottomOffset = CGPointMake(0, self.collectionView.contentSize.height - self.collectionView.bounds.size.height);
  [self.collectionView setContentOffset:bottomOffset animated:NO];
}

# pragma mark - long press gesture and set to home image

-(void) longPressRecognizer: (UILongPressGestureRecognizer *) gestureRecognizer {
  
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    CGPoint p = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
    if (indexPath == nil) {
      NSLog(@"long press is not in any cell");
    } else {
      UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
      if (cell.highlighted) {
        //self.setCoverPageViewContainer.frame = CGRectMake(0, 430, 320, 150);
        UIActionSheet *shareActionSheet = [[UIActionSheet alloc] initWithTitle:@"Cover Image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Set As Cover Image", nil];
        [shareActionSheet showInView:self.view];
        
        NSLog(@"long press select at %ld", (long)indexPath.row);
        self.selectedCoverPhoto = [self.photos objectAtIndex:indexPath.row];
      }
    }
  }
}

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  switch (buttonIndex) {
    case 0:
    {
      self.album.coverImage =  self.selectedCoverPhoto.remoteID;
      [self.dataWrapper updateAlbum:self.album];
      //[self.coinsorter updateMeta:self.selectedCoverPhoto entity:@"home" value:@"1"];
      
      [[NSNotificationCenter defaultCenter] postNotificationName:@"CoverPhotoChange" object:nil];
      break;
    }
    default:
      break;
  }
}

-(void) addNewcell{
  int Size = (int)self.photos.count;
  self.photos =  [self.dataWrapper getPhotosWithAlbum:self.localDevice.remoteId album:self.album];
  //__block int total = (int)self.tmpPhotos.count +(int)self.videoUrl.count;
  dispatch_async(dispatch_get_main_queue(), ^ {
//    [self.collectionView performBatchUpdates:^{
      NSLog(@"total photo %d",Size);
      
      NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
      
      [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:Size inSection:0]];
      [self.collectionView insertItemsAtIndexPaths:arrayWithIndexPaths];
      
//    }completion:nil];
  });
}

-(void) tagStored: (NSNotification *) notification {
  NSMutableArray *indexset = [NSMutableArray array];
  self.photos =  [self.dataWrapper getPhotosWithAlbum:self.localDevice.remoteId album:self.album];
  CSPhoto *p = [self.dataWrapper getPhoto:[notification.userInfo objectForKey:IMAGE_URL]];
  NSUInteger index = [self.photos indexOfObject:p];
  [indexset addObject:[NSIndexPath indexPathForRow:index inSection:0]];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.collectionView reloadItemsAtIndexPaths:indexset];
  });
}

- (void) setRightButtonText: (NSString *) text {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"SetRightButtonText" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:text, @"text", nil]];
}

- (void) clearCellSelections {
  int collectionViewCount = (int)[self.collectionView numberOfItemsInSection:0];
  for (int i=0; i<=collectionViewCount; i++) {
    [self.collectionView deselectItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0] animated:YES];
    GridCell *selectedCell = (GridCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
    selectedCell.alpha = 1.0;
  }
}

- (void) editPressed {
  if (editEnabled) {
    editEnabled = NO;
    [self setRightButtonText:@"Select"];
    [self clearCellSelections];
    self.collectionView.allowsMultipleSelection = NO;
   [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowShareDelete" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"no", @"show", nil]];
  } else {
    editEnabled = YES;
    selectedPhotos = [[NSMutableArray alloc] init];
    [self clearCellSelections];
    self.collectionView.allowsMultipleSelection = YES;
    [self setRightButtonText:@"Done"];
   [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowShareDelete" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"yes", @"show", nil]];
  }
}

- (void) viewDidDisappear:(BOOL)animated {
  NSLog(@"photos view disappear");
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowShareDelete" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"no", @"show", nil]];  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RightButtonPressed" object:nil];
}

- (void) deletePressed {
  if (editEnabled) {
    NSLog(@"delete pressed");
    if (selectedPhotos.count > 0) {
      UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Delete"
                                                        message:@"Delete Selected Photos?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Yes", nil];
      [message show];
    }
  }
}

-(void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 0) {
    [self clearCellSelections];
  } else if (buttonIndex == 1){
    
    NSArray *selectedIndexPath = [self.collectionView indexPathsForSelectedItems];
    NSArray *deletedPhoto = [self selectedDeletedPhoto:selectedIndexPath];
    [self.collectionView performBatchUpdates:^{
      [self deletePhotoFromFile:deletedPhoto];
      [self deleteItemsFromDataSourceAtIndexPaths: deletedPhoto itemPath:selectedIndexPath];
      [self.collectionView deleteItemsAtIndexPaths:selectedIndexPath];
      
    } completion: ^(BOOL finished){
      [[NSNotificationCenter defaultCenter] postNotificationName:@"PhotoDeleted" object:nil];
    }];
  }

}

-(void) deleteItemsFromDataSourceAtIndexPaths :(NSArray *)deletedPhoto itemPath: (NSArray *) itemPaths{
  
  NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
  for (NSIndexPath *itemPath  in itemPaths) {
    [indexSet addIndex:itemPath.row];
  }
  [self.photos removeObjectsAtIndexes:indexSet];
  for (CSPhoto *p in deletedPhoto) {
    [self.dataWrapper deletePhotos:p];
  }
}

- (void) deletePhotoFromFile: (NSArray *) deletedPhoto {
  NSMutableArray *photoPath = [NSMutableArray array];
  for (CSPhoto *p in deletedPhoto) {
    // get documents directory
    
    NSURL *imageUrl = [NSURL URLWithString:p.imageURL];
    NSURL *thumUrl = [NSURL URLWithString:p.thumbURL];
    [photoPath addObject:imageUrl.path];
    [photoPath addObject:thumUrl.path];
  }
  for (NSString *currentpath in photoPath) {
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:currentpath error:&error];
  }
  
  
}

-(NSArray *) selectedDeletedPhoto: (NSArray *)itemPaths {
  NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
  for (NSIndexPath *itemPath  in itemPaths) {
    [indexSet addIndex:itemPath.row];
  }
  NSArray *deletedPhoto = [self.photos objectsAtIndexes:indexSet];
  
  return deletedPhoto;
  
}

- (void) sharePressed {
  NSLog(@"share pressed");
  if (editEnabled) {
    NSLog(@"selectedphotos count: %lu", (unsigned long)selectedPhotos.count);
    if (selectedPhotos.count > 0) {
      [self shareAction:[[NSMutableArray alloc] init] index:0 photos:selectedPhotos];
    }
  }
}

- (void) shareAction: (NSMutableArray *) images index:(int)index photos:(NSMutableArray *) photos {
  NSLog(@"%d - %lu", index, (unsigned long)[photos count]);
  if (index >= [photos count]) {
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:images applicationActivities:nil];
    NSArray *exclude = @[];
    activityVC.excludedActivityTypes = exclude;
    [self presentViewController:activityVC animated:YES completion:nil];
    return;
  }
  
  CSPhoto *p = [photos objectAtIndex:index];
  [appDelegate.mediaLoader loadFullResImage:p completionHandler:^(UIImage *image) {
    [images addObject:image];
    [self shareAction:images index:index + 1 photos:photos];
  }];
}

# pragma mark - collection view delegate/data source

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
  if (editEnabled) {
    CSPhoto *deSelectedPhoto = [self.photos objectAtIndex:indexPath.row];
    [selectedPhotos removeObject:deSelectedPhoto];
    GridCell *selectedCell = (GridCell *)[collectionView cellForItemAtIndexPath:indexPath];
    selectedCell.alpha = 1.0;
  }
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  
  if (editEnabled) {
    CSPhoto *selectedphoto = [self.photos objectAtIndex:indexPath.row];
    
    // Add the selected item into the array
    [selectedPhotos addObject:selectedphoto];
    
    NSLog(@"selectedphotos count: %lu", (unsigned long)selectedPhotos.count);
    
    GridCell *selectedCell = (GridCell *)[collectionView cellForItemAtIndexPath:indexPath];
    selectedCell.alpha = 0.3;

  } else {
    selected = [indexPath row];
    [self performSegueWithIdentifier:SINGLE_PHOTO_SEGUE sender:self];
  }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if([segue.identifier isEqualToString:SINGLE_PHOTO_SEGUE]) {
    PhotoSwipeViewController *swipeController = (PhotoSwipeViewController *) segue.destinationViewController;
    swipeController.selected = selected;
    swipeController.photos = self.photos;
    swipeController.dataWrapper = self.dataWrapper;
    swipeController.coinsorter = self.coinsorter;
  }
  
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return [_photos count];
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return 1;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  GridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:GRID_CELL forIndexPath:indexPath];
  CSPhoto *photo = [self.photos objectAtIndex:[indexPath row]];
  cell.photo = photo;
  float randomWhite = (arc4random() % 40 + 10) / 255.0;
  cell.backgroundColor = [UIColor colorWithWhite:randomWhite alpha:1];
  if (cell.selected) {
    cell.alpha = 0.3;
  } else {
    cell.alpha = 1.0;
  }

  return cell;
}


# pragma mark - Collection View layout delegate

-(float)collectionView:(UICollectionView *)collectionView relativeHeightForItemAtIndexPath:(NSIndexPath *)indexPath{
  
  //  Base relative height for simple layout type. This is 1.0 (height equals to width, square image)
  float retVal = 1.0;
  
  CSPhoto *photo = [self.photos objectAtIndex:indexPath.row];
  
  if (photo.relativeHeight != 0){
    
    //  If the relative height was set before, return it
    retVal = photo.relativeHeight;
    
  }else{
    
    BOOL isDoubleColumn = [self collectionView:collectionView isDoubleColumnAtIndexPath:indexPath];
    if (isDoubleColumn){
      //  Base relative height for double layout type. This is 0.75 (height equals to 75% width)
      retVal = 0.75;
    }
    
    /*  Relative height random modifier. The max height of relative height is 25% more than
     *  the base relative height */
    
    float extraRandomHeight = arc4random() % 25;
    retVal = retVal + (extraRandomHeight / 100);
    
    /*  Persist the relative height on each photo so the value will be the same every time
     *  the layout invalidates */
    photo.relativeHeight = retVal;
  }
  return retVal;
}

-(BOOL)collectionView:(UICollectionView *)collectionView isDoubleColumnAtIndexPath:(NSIndexPath *)indexPath{
  CSPhoto *photo = [self.photos objectAtIndex:indexPath.row];
  
  if (photo.layoutType == cellLayoutTypeUndefined){
    
    // random determin if a cell is double column or single column
    
    NSUInteger random = arc4random() % 100;
    if (random < kDoubleColumnProbability){
      photo.layoutType = cellLayoutTypeDouble;
    }else{
      photo.layoutType = cellLayoutTypeSingle;
    }
  }
  
  return NO;
  
}

-(NSUInteger)numberOfColumnsInCollectionView:(UICollectionView *)collectionView{
  
  return 3;
}

@end
