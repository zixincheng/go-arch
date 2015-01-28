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
    // Camera vars init
    AVCaptureSession *tmpSession = [[AVCaptureSession alloc] init];
    self.session = tmpSession;
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    [self.session startRunning];
    self.picker = [[UIImagePickerController alloc] init];
    self.overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    
    //init ui parts
    
    [self.navigationController setToolbarHidden:NO];
    self.mainCameraBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraButtonPressed:)];
    self.deleteBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteBtnPressed:)];
    self.shareBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareAction)];
    self.flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.toolbarItems = [NSArray arrayWithObjects:self.flexibleSpace, self.mainCameraBtn, self.flexibleSpace, nil];

    //init vars
    localLibrary = [[LocalLibrary alloc] init];
    self.coinsorter = [[Coinsorter alloc] initWithWrapper:self.dataWrapper];
    defaults = [NSUserDefaults standardUserDefaults];
    
    self.saveInAlbum = [defaults boolForKey:SAVE_INTO_ALBUM];
    selectedPhotos = [NSMutableArray array];
    
    
    // setup objects
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    account = appDelegate.account;
    
    self.photos =  [self.dataWrapper getPhotosWithLocation:self.localDevice.remoteId location:self.location];
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

# pragma mark - Collection View Delegates/Data Source

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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photos.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:GRID_CELL forIndexPath:indexPath];
    UIImageView *imageView = (UIImageView *) [cell viewWithTag:IMAGE_VIEW_TAG];

    UITextField *tagTextField = (UITextField *) [cell viewWithTag:TextField_TAG];
    
    UIView *tageview = (UIView *) [cell viewWithTag:TAG_VIEW_TAG];

    tagTextField.delegate = self;
    tagTextField.enabled = YES;
    cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"selectedbackground.png"]];

    [tageview addSubview:tagTextField];
    [cell addSubview:tageview];
    
    CSPhoto *photo = [self.photos objectAtIndex:[indexPath row]];
    [self.photos objectAtIndex:[indexPath row]];
    
    if (![photo.tag isEqualToString:@""]) {
         tagTextField.text = photo.tag;
    }
    
    [tagTextField addTarget:self action:@selector(textfieldChanged:) forControlEvents:UIControlEventEditingChanged];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    [appDelegate.mediaLoader loadFullResImage:photo completionHandler:^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [imageView setImage:image];
        });
    }];
    
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
    }

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
        } completion:^(BOOL finished){
            [self.collectionView reloadData];
        }];
    }
}

- (void)clearCellSelections {
    int collectonViewCount = [self.collectionView numberOfItemsInSection:0];
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


# pragma mark - TextField delegate
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
        NSLog(@"session %@",self.session);
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    //[picker dismissViewControllerAnimated:NO completion:^{
    // picker disappeared
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
    
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

# pragma mark - Save and Update photo

//update the collection view cell
-(void) addNewcell: (CSPhoto *)photos{
    
    int Size = (int)self.photos.count;
    [self.collectionView performBatchUpdates:^{
        
        [self.photos addObject:photos];
        NSMutableArray *arrayWithIndexPaths = [NSMutableArray array];
        
        self.photos =  [self.dataWrapper getPhotosWithLocation:self.localDevice.remoteId location:self.location];
        [arrayWithIndexPaths addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
        [self.collectionView insertItemsAtIndexPaths:arrayWithIndexPaths];
        
        if (Size != 0) {
            [self.collectionView reloadItemsAtIndexPaths:arrayWithIndexPaths];
        }
    }completion:^(BOOL finished) {
        if (finished) {
            self.photos =  [self.dataWrapper getPhotosWithLocation:self.localDevice.remoteId location:self.location];
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
    CMTime time = [asset duration];
    time.value = 0;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    // get app document path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    
    NSString *photoUID = [self getCurrentDateTime];
    NSString *thumbPath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/thumb_%@.jpg", photoUID]];
    NSString *filePath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@.mov", photoUID]];
    
    NSString *fullPath = [[NSURL fileURLWithPath:filePath] absoluteString];
    NSString *fullthumbPath = [[NSURL fileURLWithPath:thumbPath] absoluteString];
    
    NSData *videoData = [NSData dataWithContentsOfURL:moviePath];
    
    [videoData writeToFile:filePath atomically:YES];
    NSData *thumbData = [NSData dataWithData:UIImageJPEGRepresentation(thumbnail, 1.0)];
    [thumbData writeToFile:thumbPath atomically:YES];
    
    CSPhoto *p = [[CSPhoto alloc] init];
    
    p.dateCreated = [NSDate date];
    p.deviceId = self.localDevice.remoteId;
    p.onServer = @"0";
    p.thumbURL = fullthumbPath;
    p.imageURL = fullPath;
    p.fileName = [NSString stringWithFormat:@"%@.mov",photoUID];
    p.isVideo = @"1";
    p.unit = self.location.unit;
    p.city = self.location.city;
    p.name = self.location.name;
    
    [self.dataWrapper addPhoto:p];
    
    //self.unUploadedPhotos++;
    callback(p);
    
}

// save photos to the document directory and save to core data
- (void) saveImageIntoDocument:(UIImage *)image metadata:(NSDictionary *)metadata callback: (void (^) (CSPhoto *photo)) callback {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    NSString *photoUID = [self getCurrentDateTime];
    
    NSString *filePath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@.jpg", photoUID]];
    NSString *fullPath = [[NSURL fileURLWithPath:filePath] absoluteString];
    
    
    CSPhoto *p = [[CSPhoto alloc] init];
    
    p.dateCreated = [NSDate date];
    p.deviceId = self.localDevice.remoteId;
    p.onServer = @"0";
    p.thumbURL = fullPath;
    p.imageURL = fullPath;
    p.fileName = [NSString stringWithFormat:@"%@.jpg", photoUID];
    p.isVideo = @"0";
    p.unit = self.location.unit;
    p.city = self.location.city;
    p.name = self.location.name;
    
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
    
    NSMutableArray *normalArr = [[NSMutableArray alloc] initWithObjects:@"close_cha.png", @"camera_line.png", @"switch_camera.png", @"flashing_auto.png", nil];
    NSMutableArray *highlightArr = [[NSMutableArray alloc] initWithObjects:@"close_cha_h.png", @"", @"", @"", nil];
    NSMutableArray *selectedArr = [[NSMutableArray alloc] initWithObjects:@"", @"camera_line_h.png", @"switch_camera_h.png", @"", nil];
    
    NSMutableArray *actionArr = [[NSMutableArray alloc] initWithObjects:@"dismissBtnPressed:", @"VideoBtnPressed:", @"switchCameraBtnPressed:", @"flashBtnPressed:", nil];
    
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
    
    [UIView animateWithDuration:0.38f animations:^{
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
