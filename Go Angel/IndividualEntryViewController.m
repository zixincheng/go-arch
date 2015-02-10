//
//  IndividualEntryViewController.m
//  Go Angel
//
//  Created by zcheng on 2015-01-23.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "IndividualEntryViewController.h"

#define IMAGE_VIEW_TAG 11
#define TAG_VIEW_TAG 12
#define TextField_TAG 8
#define BUTTON_TAG 9
#define PHOTO_HEADER @"photoSectionHeader"
#define GRID_CELL @"ImageCell"
#define GRID_CELL2 @"TagCell"
#define SINGLE_PHOTO_SEGUE @"singleImageSegue"
//height
#define CAMERA_TOPVIEW_HEIGHT   44  //title
#define CAMERA_MENU_VIEW_HEIGH  44  //menu

#define kDoubleColumnProbability 40

@interface IndividualEntryViewController () {
    
    BOOL takingPhoto;
    BOOL recording;
    NSTimer *timer;
    int sec;
    int min;
    int hour;
    BOOL enableEdit;
    NSMutableArray *selectedPhotos;
    int selected;
}
@end

@implementation IndividualEntryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CellLayout * layout = (id)[self.collectionView collectionViewLayout];
    layout.delegate = self;
    
    // Camera vars init
    AVCaptureSession *tmpSession = [[AVCaptureSession alloc] init];
    self.session = tmpSession;
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    [self.session startRunning];
    self.picker = [[UIImagePickerController alloc] init];
    self.overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    
    //init ui parts
    self.setCoverPageViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 1600, 320, 150)];
    self.setCoverPageViewContainer.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.setCoverPageViewContainer];
    
    self.DonesetCover = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.DonesetCover.backgroundColor = [UIColor redColor];
    self.DonesetCover.frame = CGRectMake(0, 0, 320, 50);
    [self.DonesetCover addTarget:self action:@selector(donesetCover:) forControlEvents:UIControlEventTouchUpInside];
    [self.DonesetCover setTitle:@"Set As Cover image" forState:UIControlStateNormal];
    [self.setCoverPageViewContainer addSubview:self.DonesetCover];
    
    self.CancelsetCover = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.CancelsetCover.frame = CGRectMake(0, 50, 320, 50);
    [self.CancelsetCover addTarget:self action:@selector(cancelsetCover:) forControlEvents:UIControlEventTouchUpInside];
    [self.CancelsetCover setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.setCoverPageViewContainer addSubview:self.CancelsetCover];
    
    
    
    //init buttons on tool bar
    [self.navigationController setToolbarHidden:NO];
    self.mainCameraBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraButtonPressed:)];
    self.deleteBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteBtnPressed:)];
    self.shareBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareAction)];
    self.flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.toolbarItems = [NSArray arrayWithObjects:self.flexibleSpace, self.mainCameraBtn, self.flexibleSpace, nil];
    
    //init long press gesture
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressRecognizer:)];
    lpgr.minimumPressDuration = 2.0;
    lpgr.delegate = self;
    [self.collectionView addGestureRecognizer:lpgr];

    //init vars
    localLibrary = [[LocalLibrary alloc] init];
    self.coinsorter = [[Coinsorter alloc] initWithWrapper:self.dataWrapper];
    defaults = [NSUserDefaults standardUserDefaults];
    
    self.saveInAlbum = [defaults boolForKey:SAVE_INTO_ALBUM];
    selectedPhotos = [NSMutableArray array];
    self.photoPath = [NSMutableArray array];
    self.videoUrl = [NSMutableArray array];
    self.tmpMeta = [NSMutableArray array];
    self.tmpPhotos = [NSMutableArray array];
    
    
    // setup objects
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    account = appDelegate.account;
    
    self.photos =  [self.dataWrapper getPhotosWithLocation:self.localDevice.remoteId location:self.location];
    NSLog(@"count total photos %lu",(unsigned long)self.photos.count);
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self.collectionView reloadData];
    [self clearCellSelections];
}

#pragma mark - Collection view layout things
// Layout: Set cell size
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 5.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 10.0;
}

// Layout: Set Edges
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    // return UIEdgeInsetsMake(0,8,0,8);  // top, left, bottom, right
    return UIEdgeInsetsMake(0,0,0,0);  // top, left, bottom, right
}
# pragma mark - Collection View Delegates/Data Source
/*
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        PhotoSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:PHOTO_HEADER forIndexPath:indexPath];
        NSString *title;
        if (![self.location.unit isEqualToString:@""]) {
            title = [NSString stringWithFormat:@"%@ - %@",self.location.unit, self.location.name];
        } else {
            title = [NSString stringWithFormat:@"%@", self.location.name];
            }
        headerView.HeaderLabel.text = title;
        reusableview = headerView;
    }
    
    return reusableview;
}
*/
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photos.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:GRID_CELL forIndexPath:indexPath];
    //UIImageView *imageView = (UIImageView *) [cell viewWithTag:IMAGE_VIEW_TAG];
    
/*
    UITextField *tagTextField = (UITextField *) [cell viewWithTag:TextField_TAG];
    
    UIView *tageview = (UIView *) [cell viewWithTag:TAG_VIEW_TAG];

    tagTextField.delegate = self;
    tagTextField.enabled = YES;
 */
  //  cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"selectedbackground.png"]];
/*
    [tageview addSubview:tagTextField];
    [cell addSubview:tageview];
*/
    CSPhoto *photo = [self.photos objectAtIndex:[indexPath row]];
    cell.photo = photo;
    float randomWhite = (arc4random() % 40 + 10) / 255.0;
    cell.backgroundColor = [UIColor colorWithWhite:randomWhite alpha:1];
    /*
    if (![photo.tag isEqualToString:@""]) {
         tagTextField.text = photo.tag;
    }
    
    [tagTextField addTarget:self action:@selector(textfieldChanged:) forControlEvents:UIControlEventEditingChanged];
*/
   // AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    //if ([photo.isVideo isEqualToString:@"1"]) {
     //   [appDelegate.mediaLoader loadThumbnail:photo completionHandler:^(UIImage *image) {
     //       dispatch_async(dispatch_get_main_queue(), ^{
      //          [imageView setImage:image];
     //       });
      //  }];
    //} else {
    //[appDelegate.mediaLoader loadFullResImage:photo completionHandler:^(UIImage *image) {
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //        [imageView setImage:image];
     //   });
    //}];
    //}
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (enableEdit) {
        NSString *deSelectedPhoto = [self.photos objectAtIndex:indexPath.row];
        [selectedPhotos removeObject:deSelectedPhoto];
        if (selectedPhotos.count == 0) {
            self.shareBtn.enabled = NO;
            self.deleteBtn.enabled = NO;
        }
    }
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (enableEdit) {
        CSPhoto *selectedphoto = [self.photos objectAtIndex:indexPath.row];
        // Add the selected item into the array
        [selectedPhotos addObject:selectedphoto];
        if (selectedPhotos.count != 0) {
            self.shareBtn.enabled = YES;
            self.deleteBtn.enabled = YES;
        }
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
    }

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
    
    BOOL retVal = photo.layoutType == cellLayoutTypeDouble;
    
    return retVal;
    
}

-(NSUInteger)numberOfColumnsInCollectionView:(UICollectionView *)collectionView{
    
    return 2;
}

# pragma mark - delete button Actions
- (IBAction)editBtnPressed:(id)sender {
    
    UIBarButtonItem *editbtn =  (UIBarButtonItem *)sender;
    if ([editbtn.title isEqualToString:@"Edit"]) {
        self.collectionView.allowsMultipleSelection = YES;
        enableEdit = YES;
        self.editBtn.title = @"Done";
        [self clearCellSelections];
        self.toolbarItems = [NSArray arrayWithObjects:self.shareBtn,self.flexibleSpace, self.deleteBtn, nil];
        self.shareBtn.enabled = NO;
        self.deleteBtn.enabled = NO;
    } else {
        self.editBtn.title = @"Edit";
        enableEdit = NO;
        self.collectionView.allowsMultipleSelection = NO;
        [self clearCellSelections];
        self.toolbarItems = [NSArray arrayWithObjects:self.flexibleSpace, self.mainCameraBtn, self.flexibleSpace, nil];
        
    }
}

-(void) deleteBtnPressed:(id)sender {
    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Delete"
                                                      message:@"Delete Selected Photos?"
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"Yes", nil];
    [message show];
    
}

-(void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self clearCellSelections];
    } else if (buttonIndex == 1){
        NSArray *selectedIndexPath = [self.collectionView indexPathsForSelectedItems];
        [self.collectionView performBatchUpdates:^{
            [self deleteItemsFromDataSourceAtIndexPaths: selectedIndexPath];
            [self.collectionView deleteItemsAtIndexPaths:selectedIndexPath];
            
            NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
            for (NSIndexPath *itemPath  in selectedIndexPath) {
                [indexSet addIndex:itemPath.row];
            }
            [self.photoPath objectsAtIndexes:indexSet];
            for (NSString *currentpath in self.photoPath) {
                NSError *error;
                [[NSFileManager defaultManager] removeItemAtPath:currentpath error:&error];
            }

        } completion:^(BOOL finished){
            [self.collectionView reloadData];
        }];
    }
}

- (void)clearCellSelections {
    int collectonViewCount = (int)[self.collectionView numberOfItemsInSection:0];
    for (int i=0; i<=collectonViewCount; i++) {
        [self.collectionView deselectItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0] animated:YES];
    }
}

-(void) deleteItemsFromDataSourceAtIndexPaths :(NSArray *)itemPaths{
    
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSIndexPath *itemPath  in itemPaths) {
        [indexSet addIndex:itemPath.row];
    }
    [self.photos removeObjectsAtIndexes:indexSet];
    
    [self.dataWrapper deletePhotos:itemPaths];
}

# pragma mark - share actions

- (void)shareAction {
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    for (CSPhoto *selectPhoto in selectedPhotos) {

        [appDelegate.mediaLoader loadFullResImage:selectPhoto completionHandler:^(UIImage *image) {
            NSArray *objectsToShare = @[ image ];
        
            UIActivityViewController *activityVC =
            [[UIActivityViewController alloc] initWithActivityItems:objectsToShare
                                          applicationActivities:nil];
        
            NSArray *excludeActivities = @[ ];
        
            activityVC.excludedActivityTypes = excludeActivities;
        
            [self presentViewController:activityVC animated:YES completion:nil];
        }];
    }
}

/*
# pragma mark - TextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationBeginsFromCurrentState:YES];
    self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x, (self.collectionView.frame.origin.y - 180.0), self.collectionView.frame.size.width, self.collectionView.frame.size.height);
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationBeginsFromCurrentState:YES];
    self.collectionView.frame = CGRectMake(self.collectionView.frame.origin.x, (self.collectionView.frame.origin.y + 180.0), self.collectionView.frame.size.width, self.collectionView.frame.size.height);
    [UIView commitAnimations];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    return YES;
}

// when return button pressed, hide keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textfieldChanged:(id)sender {
    
    UITextField *text = sender;
    GridCell *cell = (GridCell *)text.superview.superview.superview;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    CSPhoto *p = [self.photos objectAtIndex:indexPath.row];
    p.tag = text.text;
    [self.dataWrapper addUpdatePhoto:p];
}
*/
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
                self.setCoverPageViewContainer.frame = CGRectMake(0, 430, 320, 150);
                NSLog(@"long press select at %ld", (long)indexPath.row);
                self.selectedCoverPhoto = [self.photos objectAtIndex:indexPath.row];

            }
        }
    }
}

-(void) donesetCover:(id) sender {
    CSPhoto *oldCover = [self.dataWrapper getCoverPhoto:self.localDevice.remoteId location:self.location];
    if (oldCover == nil) {
        
    } else {
        oldCover.cover = @"0";
        [self.dataWrapper addUpdatePhoto:oldCover];
    }
    self.selectedCoverPhoto.cover = @"1";
    [self.dataWrapper addUpdatePhoto:self.selectedCoverPhoto];
    self.setCoverPageViewContainer.frame = CGRectMake(0, 1600, 320, 150);
}
-(void) cancelsetCover:(id) sender {
    self.setCoverPageViewContainer.frame = CGRectMake(0, 1600, 320, 150);
}
# pragma mark - Camera Button

-(void)cameraButtonPressed:(id)sender{
    self.picker.delegate = self;
    self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.overlay = [self creatCaremaOverlay];
    self.picker.cameraOverlayView = self.overlay;
    self.picker.showsCameraControls = NO;
    takingPhoto = YES;

    [self presentViewController:self.picker animated:YES completion:^{
        [self addCameraCover];
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    //[picker dismissViewControllerAnimated:NO completion:^{
    // picker disappeared
    if (takingPhoto) {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        NSDictionary *metadata = info[UIImagePickerControllerMediaMetadata];
        
        [self.tmpPhotos addObject:image];
        [self.tmpMeta addObject:metadata];
        NSLog(@"number of photo taken count %lu",(unsigned long)self.tmpPhotos.count);
    } else {
        NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
        // Handle a movie capture
        if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
            NSURL *moviePath = [info objectForKey:UIImagePickerControllerMediaURL];
            [self.videoUrl addObject:moviePath];
            NSLog(@"number of video taken count %lu",(unsigned long)self.videoUrl.count);
        }

        
    }
/*
    if (takingPhoto) {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        NSDictionary *metadata = info[UIImagePickerControllerMediaMetadata];
        
        if (self.saveInAlbum) {
            NSLog(@"save photos into album");
            
            [localLibrary saveImage:image metadata:metadata location:self.location callback: ^(CSPhoto *photo){
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [self addNewcell:photo];
                });
            }];
        }else{
            NSLog(@"save photos into application folder");
            [self saveImageIntoDocument:image metadata:metadata callback: ^(CSPhoto *photo){
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [self addNewcell:photo];
                });
            }];
            
        }
    } else {
        if (self.saveInAlbum) {
            NSLog(@"save video into album");
            NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
            // Handle a movie capture
            if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
                NSURL *moviePath = [info objectForKey:UIImagePickerControllerMediaURL];
                NSLog(@"%@",moviePath);
                
                [localLibrary saveVideo:moviePath location:self.location callback:^(CSPhoto *photo) {
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        [self addNewcell:photo];
                    });
                }];
            }
        } else {
            NSLog(@"save video into application folder");
            NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
            // Handle a movie capture
            if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
                NSURL *moviePath = [info objectForKey:UIImagePickerControllerMediaURL];
                NSLog(@"%@",moviePath);
                
                [self saveVideoIntoDocument:moviePath callback:^(CSPhoto *photo) {
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        [self addNewcell:photo];
                    });
                }];
            }
            
        }
    }
*/
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void) savingPhotoFromImagePicker: (NSMutableArray *)tmpPhotos tmpMeta: (NSMutableArray *)tempMeta moviePath: (NSMutableArray *) moviePath{
    //NSMutableArray *readyPhoto = [NSMutableArray array];
    

        for (int count = 0; count < self.tmpPhotos.count; count++) {
            UIImage *image = [self.tmpPhotos objectAtIndex:count];
            NSDictionary *metadata = [self.tmpMeta objectAtIndex:count];
            if (self.saveInAlbum) {
                NSLog(@"save photos into album");
                
                [localLibrary saveImage:image metadata:metadata location:self.location callback: ^(CSPhoto *photo){
                       // [readyPhoto addObject:photo];
                }];
            }else{
                NSLog(@"save photos into application folder");
                [self saveImageIntoDocument:image metadata:metadata callback: ^(CSPhoto *photo){
                   // [readyPhoto addObject:photo];
                }];
            }

        }
    
        for (int count = 0; count<self.videoUrl.count; count++) {
            
            if (self.saveInAlbum) {
                NSLog(@"save video into album");
                for (int count = 0; count < self.videoUrl.count; count++) {
                    NSURL *moviePath = [self.videoUrl objectAtIndex:count];
                    [localLibrary saveVideo:moviePath location:self.location callback:^(CSPhoto *photo) {
                        dispatch_async(dispatch_get_main_queue(), ^ {
                            //[readyPhoto addObject:photo];
                        });
                    }];
                }
            } else {
                NSLog(@"save video into application folder");
                    NSURL *moviePath = [self.videoUrl objectAtIndex:count];
                    
                    [self saveVideoIntoDocument:moviePath callback:^(CSPhoto *photo) {
                        dispatch_async(dispatch_get_main_queue(), ^ {
                            //[readyPhoto addObject:photo];
                        });
                    }];
            }

    }
    
     dispatch_async(dispatch_get_main_queue(), ^ {
         //for (CSPhoto *photo in readyPhoto) {
             [self addNewcell];
         //}
    });
    
}

# pragma mark - Save and Update photo

//update the collection view cell
-(void) addNewcell{
    
    int Size = (int)self.photos.count;
    [self.collectionView performBatchUpdates:^{
        NSLog(@"total photo %d",Size);
       // [self.photos addObject:photos];
        int total = (int)self.tmpPhotos.count +(int)self.videoUrl.count;
        NSLog(@"need to upload  %d",total);
        NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
        
        self.photos =  [self.dataWrapper getPhotosWithLocation:self.localDevice.remoteId location:self.location];
        NSLog(@"after total photo %d",(int)self.photos.count);
        for (int count= 0; count <total; count++) {
            [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:count inSection:0]];

        }
        [self.collectionView insertItemsAtIndexPaths:arrayWithIndexPaths];
        
        if (Size != 0) {
            [self.collectionView reloadItemsAtIndexPaths:arrayWithIndexPaths];
        }
    }completion:^(BOOL finished) {
        if (finished) {
            [self.tmpPhotos removeAllObjects];
            [self.tmpMeta removeAllObjects];
            [self.videoUrl removeAllObjects];
        }
    }];
}

// save photos to the document directory


//get currentdate so that each image can have a unique name

-(NSString*)getCurrentDateTime
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyyMMddHHmmss"];
    NSDate *now = [NSDate date];
    NSString *retStr = [format stringFromDate:now];
    
    return retStr;
}

-(void) saveVideoIntoDocument:(NSURL *)moviePath callback:(void (^) (CSPhoto *photo)) callback{
    
    
    // generate thumbnail for video
    AVAsset *asset = [AVAsset assetWithURL:moviePath];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = [asset duration];
    time.value = 0;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    // get app document path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    
    NSString *photoUID = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *thumbPath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/thumb_%@.jpg", photoUID]];
    NSString *filePath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@.mov", photoUID]];
    
    NSString *fullPath = [[NSURL fileURLWithPath:filePath] absoluteString];
    NSString *fullthumbPath = [[NSURL fileURLWithPath:thumbPath] absoluteString];

    NSData *videoData = [NSData dataWithContentsOfURL:moviePath];
    
    [videoData writeToFile:filePath atomically:YES];
    NSData *thumbData = [NSData dataWithData:UIImageJPEGRepresentation(thumbnail, 1.0)];
    [thumbData writeToFile:thumbPath atomically:YES];
    [self.photoPath addObject:filePath];
    CSPhoto *p = [[CSPhoto alloc] init];
    
    p.dateCreated = [NSDate date];
    p.deviceId = self.localDevice.remoteId;
    p.onServer = @"0";
    p.thumbURL = thumbPath;
    p.imageURL = fullPath;
    p.fileName = [NSString stringWithFormat:@"%@.mov",photoUID];
    p.thumbnailName = [NSString stringWithFormat:@"thumb_%@.jpg", photoUID];
    p.isVideo = @"1";
    p.cover = @"0";
    p.location = self.location;
    
    [self.dataWrapper addPhoto:p];
    
    //self.unUploadedPhotos++;
    callback(p);
    
}

// save photos to the document directory and save to core data
- (void) saveImageIntoDocument:(UIImage *)image metadata:(NSDictionary *)metadata callback: (void (^) (CSPhoto *photo)) callback {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    NSString *photoUID = [[NSProcessInfo processInfo] globallyUniqueString];
    
    NSString *filePath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@.jpg", photoUID]];
    NSString *fullPath = [[NSURL fileURLWithPath:filePath] absoluteString];
    
    [self.photoPath addObject:filePath];
    CSPhoto *p = [[CSPhoto alloc] init];
    
    p.dateCreated = [NSDate date];
    p.deviceId = self.localDevice.remoteId;
    p.onServer = @"0";
    p.thumbURL = fullPath;
    p.imageURL = fullPath;
    p.fileName = [NSString stringWithFormat:@"%@.jpg", photoUID];
    p.isVideo = @"0";
    p.cover = @"0";
    p.location = self.location;
    
    // save the metada information into image
    NSData *data = UIImageJPEGRepresentation(image, 100);
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    
    CFStringRef UTI = CGImageSourceGetType(source);
    NSMutableData *dest_data = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef) dest_data, UTI, 1, NULL);
    
    CGImageDestinationAddImageFromSource(
                                         destination, source, 0, (__bridge CFDictionaryRef)metadata);
    
    CGImageDestinationFinalize(destination);
    
    [dest_data writeToFile:filePath atomically:YES];
    
    CFRelease(destination);
    NSLog(@"saving photo to %@ with filename %@", filePath, p.fileName);
    
    [self.dataWrapper addPhoto:p];
    
    //self.unUploadedPhotos++;
    callback(p);
}



# pragma mark - Custom Camera View
//create custom camera overlay
-(UIView *) creatCaremaOverlay {
    
    [self addTopViewWithText:@"Taking Photo"];
    [self addCameraMenuView];
    
    return self.overlay;
    
}


// text message at top of the custom camera view
- (void)addTopViewWithText:(NSString*)text{
    if (!_topContainerView) {
        CGRect topFrame = CGRectMake(0, 0, APP_SIZE.width, CAMERA_TOPVIEW_HEIGHT);
        
        UIView *tView = [[UIView alloc] initWithFrame:topFrame];
        tView.backgroundColor = [UIColor clearColor];
        [self.overlay addSubview:tView];
        self.topContainerView = tView;
        
        UIView *emptyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, topFrame.size.width, topFrame.size.height)];
        emptyView.backgroundColor = [UIColor blackColor];
        emptyView.alpha = 0.4f;
        [_topContainerView addSubview:emptyView];
        
        topFrame.origin.x += 10;
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 500, topFrame.size.height)];
        lbl.backgroundColor = [UIColor clearColor];
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [UIFont systemFontOfSize:25.f];
        lbl.textAlignment = NSTextAlignmentNatural;
        [_topContainerView addSubview:lbl];
        self.topLbl = lbl;
    }
    _topLbl.text = text;
}

// create camera menu view, include camera button and camera control buttons
- (void)addCameraMenuView{
    
    //Button to take photo
    CGFloat cameraBtnLength = 90;
    self.caremaBtn =[self buildButton:CGRectMake((APP_SIZE.width - cameraBtnLength) / 2, (DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - cameraBtnLength)  , cameraBtnLength, cameraBtnLength)
                         normalImgStr:@"shot.png"
                      highlightImgStr:@""
                       selectedImgStr:@""
                               action:@selector(takePictureBtnPressed:)
                           parentView:self.overlay];
    
    
    //sub view of list of buttons in camera view
    UIView *menuView = [[UIView alloc] initWithFrame:CGRectMake(0, DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH, self.view.frame.size.width, CAMERA_MENU_VIEW_HEIGH)];
    menuView.backgroundColor = [UIColor clearColor];
    [self.overlay addSubview:menuView];
    self.cameraMenuView = menuView;
    
    
    
    [self addMenuViewButtons];
}

//buttons on the bottom of camera view
- (void)addMenuViewButtons {
    
    NSMutableArray *normalArr = [[NSMutableArray alloc] initWithObjects:@"close_cha.png", @"camera_line.png", @"flashing_auto.png", nil];
    NSMutableArray *highlightArr = [[NSMutableArray alloc] initWithObjects:@"close_cha_h.png", @"", @"", @"", nil];
    NSMutableArray *selectedArr = [[NSMutableArray alloc] initWithObjects:@"", @"camera_line_h.png", @"", nil];
    
    NSMutableArray *actionArr = [[NSMutableArray alloc] initWithObjects:@"dismissBtnPressed:", @"VideoBtnPressed:", @"flashBtnPressed:", nil];
    
    CGFloat eachW = APP_SIZE.width / actionArr.count;
    
    [self drawALineWithFrame:CGRectMake(eachW, 0, 1, CAMERA_MENU_VIEW_HEIGH) andColor:[UIColor colorWithRed:102 green:102 blue:102 alpha:1.0000] inLayer:_cameraMenuView.layer];
    
    
    
    for (int i = 0; i < actionArr.count; i++) {
        
        UIButton * btn = [self buildButton:CGRectMake(eachW * i, 0, eachW, CAMERA_MENU_VIEW_HEIGH)
                              normalImgStr:[normalArr objectAtIndex:i]
                           highlightImgStr:[highlightArr objectAtIndex:i]
                            selectedImgStr:[selectedArr objectAtIndex:i]
                                    action:NSSelectorFromString([actionArr objectAtIndex:i])
                                parentView:_cameraMenuView];
        
        btn.showsTouchWhenHighlighted = YES;
        
        [_cameraBtnSet addObject:btn];
    }
}

- (UIButton*)buildButton:(CGRect)frame
            normalImgStr:(NSString*)normalImgStr
         highlightImgStr:(NSString*)highlightImgStr
          selectedImgStr:(NSString*)selectedImgStr
                  action:(SEL)action
              parentView:(UIView*)parentView {
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    if (normalImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:normalImgStr] forState:UIControlStateNormal];
    }
    if (highlightImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:highlightImgStr] forState:UIControlStateHighlighted];
    }
    if (selectedImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:selectedImgStr] forState:UIControlStateSelected];
    }
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:btn];
    
    return btn;
}

- (void)drawALineWithFrame:(CGRect)frame andColor:(UIColor*)color inLayer:(CALayer*)parentLayer {
    CALayer *layer = [CALayer layer];
    layer.frame = frame;
    layer.backgroundColor = color.CGColor;
    [parentLayer addSublayer:layer];
}


// create a camra cover to indicate each time taking a photo
- (void)addCameraCover {
    UIView *upView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, APP_SIZE.width, 0)];
    upView.backgroundColor = [UIColor blackColor];
    [self.overlay addSubview:upView];
    self.doneCameraUpView = upView;
    
    UIView *downView = [[UIView alloc] initWithFrame:CGRectMake(0, DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - 90, APP_SIZE.width, 0)];
    downView.backgroundColor = [UIColor blackColor];
    [self.overlay addSubview:downView];
    self.doneCameraDownView = downView;
}

// camera cover animation
- (void)showCameraCover:(BOOL)toShow {
    
    [UIView animateWithDuration:0.18f animations:^{
        CGRect upFrame = _doneCameraUpView.frame;
        upFrame.size.height = (toShow ? (DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - 90) / 2:0 );
        _doneCameraUpView.frame = upFrame;
        
        CGRect downFrame = _doneCameraDownView.frame;
        downFrame.origin.y = (toShow ? (DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - 90)/2 : DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - 90);
        downFrame.size.height = (toShow ? (DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - 90) / 2 : 0);
        _doneCameraDownView.frame = downFrame;
    }];
}
#pragma mark Camera buttons actions

//button taking picture
- (void)takePictureBtnPressed: (id) sender{
    // if the camera is under photo model
    if (takingPhoto) {
        [self.picker takePicture];
        [self showCameraCover:YES];
        double delayInSeconds = 0.5f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            //sender.userInteractionEnabled = YES;
            [self showCameraCover:NO];
        });
    }
    // if the camera is under video model
    else {
        if (recording) {
            [self.caremaBtn setImage:[UIImage imageNamed:@"video.png"] forState:UIControlStateNormal];
            
            [self.picker stopVideoCapture];
            recording = NO;
            sec = 0;
            min = 0;
            hour = 0;
            _topLbl.text = [NSString stringWithFormat:@"%d:%d:%d",hour,min,sec];
            [timer invalidate];
        } else {
            [self.caremaBtn setImage:[UIImage imageNamed:@"videoDone.png"] forState:UIControlStateNormal];
            [self.picker startVideoCapture];
            timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(videotimer) userInfo:nil repeats:YES];
            recording = YES;
        }
        
    }
}
// taking videos
- (void)VideoBtnPressed:(UIButton*)sender {
    
    sender.selected = !sender.selected;
    if (takingPhoto) {
        
        self.picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
        takingPhoto = NO;
        [self.caremaBtn setImage:[UIImage imageNamed:@"video.png"] forState:UIControlStateNormal];
        _topLbl.text = @"Taking Video";
        NSLog(@"media type %@",self.picker.mediaTypes );
    } else {
        self.picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
        takingPhoto = YES;
        [self.caremaBtn setImage:[UIImage imageNamed:@"shot.png"] forState:UIControlStateNormal];
        _topLbl.text = @"Taking Photo";
    }
}

// set a timer when video starts, to display t#import <AVFoundation/AVFoundation.h>he time of a video has been taken
-(void)videotimer {
    NSLog(@"timer");
    sec = sec % 60;
    min = sec / 60;
    hour = min / 60;
    dispatch_async(dispatch_get_main_queue(), ^{
        _topLbl.text = [NSString stringWithFormat:@"%d:%d:%d",hour,min,sec];
    });
    sec ++;
    NSLog(@"%d",sec);
}

//button "X"
- (void)dismissBtnPressed:(id)sender {
    [self.picker dismissViewControllerAnimated:YES completion:^{
        [timer invalidate];
        NSLog(@"self.tmpphotocount %lu",(unsigned long)self.tmpPhotos.count);
        [self savingPhotoFromImagePicker:self.tmpPhotos tmpMeta:self.tmpMeta moviePath:self.videoUrl];
    }];
    
}

// flash light button functions
- (void)flashBtnPressed:(UIButton*)sender {
    [self switchFlashMode:sender];
}

- (void)switchFlashMode:(UIButton*)sender {
    
    NSString *imgStr = @"";
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [device lockForConfiguration:nil];
    if ([device hasFlash]) {
        if (!sender) {
            device.flashMode = AVCaptureFlashModeAuto;
        } else {
            if (device.flashMode == AVCaptureFlashModeOff) {
                device.flashMode = AVCaptureFlashModeOn;
                imgStr = @"flashing_on.png";
                
            } else if (device.flashMode == AVCaptureFlashModeOn) {
                device.flashMode = AVCaptureFlashModeAuto;
                imgStr = @"flashing_auto.png";
                
            } else if (device.flashMode == AVCaptureFlashModeAuto) {
                device.flashMode = AVCaptureFlashModeOff;
                imgStr = @"flashing_off.png";
                
            }
        }
        
        if (sender) {
            [sender setImage:[UIImage imageNamed:imgStr] forState:UIControlStateNormal];
        }
        
    }
    [device unlockForConfiguration];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
