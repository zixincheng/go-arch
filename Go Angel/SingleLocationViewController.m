//
//  SingleLocationViewController.m
//  Go Arch
//
//  Created by Jake Runzer on 3/18/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "SingleLocationViewController.h"

#define CAMERA_TOPVIEW_HEIGHT   44  //title
#define CAMERA_MENU_VIEW_HEIGH  44  //menu

@implementation SingleLocationViewController {
  
  BOOL enableEdit;
  BOOL takingPhoto;
  BOOL recording;
  NSTimer *timer;
  int sec;
  int min;
  int hour;
}

- (void) viewDidLoad {
  
  // init vars
    self.scrollView.contentSize =  CGSizeMake(320, 1500);
    /*
    OverviewViewController *overViewController = (OverviewViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"single_location_overview"];
    UIView *overviewcontainer = [[UIView alloc]initWithFrame:CGRectMake(0, 500, 320, 500)];
    overviewcontainer = overViewController.view;
    overviewcontainer.backgroundColor = [UIColor greenColor];
    [self.scrollView addSubview:overviewcontainer];
    
    DetailsViewController *detailviewController = (DetailsViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"single_location_details"];
    UIView *detailviewcontainer = [[UIView alloc]initWithFrame:CGRectMake(0, 500, 320, 500)];
    //detailviewcontainer = detailviewController.view;
    //[self.scrollView addSubview:detailviewcontainer];
*/
    if (self.album.albumId !=nil) {
        [self.coinsorter getAlbumInfo:self.album.albumId];
        self.album = [self.dataWrapper getSingleAlbum:self.album];
    }
  localLibrary = [[LocalLibrary alloc] init];
  self.saveFunction = [[SaveToDocument alloc]init];
  defaults = [NSUserDefaults standardUserDefaults];
  
  self.saveInAlbum = [defaults boolForKey:SAVE_INTO_ALBUM];
  
  // init buttons
  
  self.mainCameraBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraButtonPressed:)];
  self.flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  self.deleteBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteBtnPressed)];
  self.shareBtn = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareAction)];
  self.toolbarItems = [NSArray arrayWithObjects:self.flexibleSpace, self.mainCameraBtn, self.flexibleSpace, nil];

  [self.navigationController setToolbarHidden:NO];
  
  _rightButton.title = @"";
  
  [_pageControl setNumberOfPages:3];
  [_pageControl setCurrentPage:0];
  
  // register for notifications from child controllers providing info
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRightButtonText:) name:@"SetRightButtonText" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showShareDelete:) name:@"ShowShareDelete" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(metaChanged) name:@"LocationMetadataUpdate" object:nil];
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)metaChanged {
  [self setTitle:self.album.entry.location.sublocation];
}

// show the share and delete buttons in toolbar
- (void) showShareDelete: (NSNotification *)n {
  if ([n userInfo] && [n.userInfo objectForKey:@"show"]) {
    NSString *show = [n.userInfo objectForKey:@"show"];
      self.toolbarItems = [NSArray arrayWithObjects:self.shareBtn, self.flexibleSpace, self.deleteBtn, nil];
    if ([show isEqualToString:@"yes"]) {
    } else {
      self.toolbarItems = [NSArray arrayWithObjects:self.flexibleSpace, self.mainCameraBtn, self.flexibleSpace, nil];
    }
  }
}

// set the top right bar button text
- (void) setRightButtonText: (NSNotification *)n {
  if ([n userInfo] && [n.userInfo objectForKey:@"text"]) {
    NSString *text = [n.userInfo objectForKey:@"text"];
    _rightButton.title = text;
  }
}

// send notification to photo child notification about share and delete button being pressed

- (void) deleteBtnPressed {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"DeleteButtonPressed" object:nil];
}

- (void) shareAction {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ShareButtonPressed" object:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  NSString * segueName = segue.identifier;
  
  // the segue for embeding a controller into a container view
  // give the container view controller all needed vars
  if ([segueName isEqualToString: @"location_page_embed"]) {
    _pageController = (SingleLocationPageViewController *) [segue destinationViewController];
    _pageController.segmentControl = _segmentControl;
    _pageController.pageControl = _pageControl;
    _pageController.coinsorter = _coinsorter;
    _pageController.dataWrapper = _dataWrapper;
    _pageController.localDevice = _localDevice;
    _pageController.album = _album;
  }
}

- (IBAction)segmentChanged:(id)sender {
  if (_pageController != nil) {
    [_pageController segmentChanged:sender];
  }
}

- (void) cameraButtonPressed:(id) sender {
  UIActionSheet *cameraSheet = [[UIActionSheet alloc] initWithTitle:@"Upload Photo or Video" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Photo Library", @"Take Photo or Video", nil];
  [cameraSheet showInView:self.view];
  
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

# pragma mark - camera selectors

// text message at top of the custom camera view
- (void)addTopViewWithText:(NSString*)text{
    //if (!_topContainerView) {
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
   // }
    _topLbl.text = text;
}

-(void) flashScreen {
  CGFloat height = DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - 95;
  UIWindow* wnd = [UIApplication sharedApplication].keyWindow;
  UIView* v = [[UIView alloc] initWithFrame: CGRectMake(0, 0, DEVICE_SIZE.width, height)];
  [wnd addSubview: v];
  v.backgroundColor = [UIColor whiteColor];
  [UIView beginAnimations: nil context: nil];
  [UIView setAnimationDuration: 1.0];
  v.alpha = 0.0f;
  [UIView commitAnimations];
}

//button taking picture
- (void)takePictureBtnPressed: (id) sender{
  // if the camera is under photo model
  if (takingPhoto) {
    [self.picker takePicture];
    //[self showCameraCover:YES];
    [self flashScreen];
    // double delayInSeconds = 0.5f;
    // dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    //dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    //sender.userInteractionEnabled = YES;
    //[self showCameraCover:NO];
    //});
  }
  // if the camera is under video model
  else {
    if (recording) {
      [self.cameraBtn setImage:[UIImage imageNamed:@"video.png"] forState:UIControlStateNormal];
      
      [self.picker stopVideoCapture];
      recording = NO;
      sec = 0;
      min = 0;
      hour = 0;
      _topLbl.text = [NSString stringWithFormat:@"%d:%d:%d",hour,min,sec];
      [timer invalidate];
    } else {
      [self.cameraBtn setImage:[UIImage imageNamed:@"videoFinish.png"] forState:UIControlStateNormal];
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
    [self.cameraBtn setImage:[UIImage imageNamed:@"video.png"] forState:UIControlStateNormal];
    
    _topLbl.text = @"Taking Video";
    NSLog(@"media type %@",self.picker.mediaTypes );
  } else {
    self.picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    takingPhoto = YES;
    [self.cameraBtn setImage:[UIImage imageNamed:@"shot.png"] forState:UIControlStateNormal];
    _topLbl.text = @"Taking Photo";
  }
}

// set a timer when video starts, to display the time of a video has been taken
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


# pragma mark - camera overlay

- (UIView *) createCameraOverlay {
  
  // Button to take photo
  CGFloat cameraBtnLength = 90;
  
  self.cameraBtn =[self buildButton:CGRectMake((APP_SIZE.width - cameraBtnLength) / 2, (DEVICE_SIZE.height - CAMERA_MENU_VIEW_HEIGH - cameraBtnLength)  , cameraBtnLength, cameraBtnLength)
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
    
  [self addTopViewWithText:@"Taking Photo"];
  
  [self addMenuViewButtons];
  
  return self.overlay;
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

- (void)drawALineWithFrame:(CGRect)frame andColor:(UIColor*)color inLayer:(CALayer*)parentLayer {
  CALayer *layer = [CALayer layer];
  layer.frame = frame;
  layer.backgroundColor = color.CGColor;
  [parentLayer addSublayer:layer];
}

- (void) takePhotoOrVideo {
  self.picker = [[UIImagePickerController alloc] init];
  self.overlay = [[UIView alloc] initWithFrame:self.view.bounds];
  self.picker.delegate = self;
  self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
  self.overlay = [self createCameraOverlay];
  self.picker.cameraOverlayView = self.overlay;
  self.picker.showsCameraControls = NO;
  takingPhoto = YES;
  
  [self presentViewController:self.picker animated:YES completion:nil];
}

- (void) photoLibrary {
  ELCImagePickerController *elcpicker = [[ELCImagePickerController alloc] initImagePicker];
  elcpicker.maximumImagesCount = 100;
  elcpicker.returnsImage = YES;
  elcpicker.returnsOriginalImage = YES;
  elcpicker.onOrder = NO;
  elcpicker.mediaTypes =@[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
  elcpicker.imagePickerDelegate = self;
  [self presentViewController:elcpicker animated:YES completion:nil];
}

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  switch (buttonIndex) {
    case 0:
      // photo library
      [self photoLibrary];
      break;
    case 1:
      // take photo or video
      [self takePhotoOrVideo];
      break;
    default:
      break;
  }
}

- (IBAction)rightButtonPressed:(id)sender {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"RightButtonPressed" object:nil];
}

# pragma mark - elcimage picker delegate

- (void) elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self dismissViewControllerAnimated:YES completion:nil];
  });
  
  for (NSDictionary *dict in info) {
    if ([dict objectForKey:UIImagePickerControllerMediaType] == ALAssetTypePhoto){
      if ([dict objectForKey:UIImagePickerControllerOriginalImage]){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
          UIImage* image=[dict objectForKey:UIImagePickerControllerOriginalImage];
          NSDictionary *metadata = dict[UIImagePickerControllerMediaMetadata];
          
          if (self.saveInAlbum) {
            NSLog(@"save photos into album");
            
            //[localLibrary saveImage:image metadata:metadata location:self.location];
          }else{
            NSLog(@"save photos into application folder");
            //[self saveImageIntoDocument:image metadata:metadata];
            [self.saveFunction saveImageIntoDocument:image metadata:metadata album:self.album];
          }
        });
        
      } else {
        NSLog(@"UIImagePickerControllerReferenceURL = %@", dict);
      }
    } else if ([dict objectForKey:UIImagePickerControllerMediaType] == ALAssetTypeVideo){
      if ([dict objectForKey:UIImagePickerControllerOriginalImage]){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
          NSString *mediaType = [dict objectForKey: UIImagePickerControllerMediaType];
          // Handle a movie capture
          if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
            NSURL *moviePath = [dict objectForKey:UIImagePickerControllerMediaURL];
            // [self.videoUrl addObject:moviePath];
            //NSLog(@"number of video taken count %lu",(unsigned long)self.videoUrl.count);
            if (self.saveInAlbum) {
              NSLog(@"save video into album");
              //[localLibrary saveVideo:moviePath location:self.location];
            } else {
              NSLog(@"save video into application folder");              
              //[self saveVideoIntoDocument:moviePath];
              [self.saveFunction saveVideoIntoDocument:moviePath album:self.album];
            }
            
          }
          CFRelease((__bridge CFTypeRef)(mediaType));
        });
        
      } else {
        NSLog(@"UIImagePickerControllerReferenceURL = %@", dict);
      }
    } else {
      NSLog(@"Uknown asset type");
    }
  }
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
  [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark - image picker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    if (takingPhoto) {
      UIImage *image = info[UIImagePickerControllerOriginalImage];
      NSDictionary *metadata = info[UIImagePickerControllerMediaMetadata];
      
      // [self.tmpPhotos addObject:image];
      //[self.tmpMeta addObject:metadata];
      //NSLog(@"number of photo taken count %lu",(unsigned long)self.tmpPhotos.count);
      if (self.saveInAlbum) {
        NSLog(@"save photos into album");
        
        //[localLibrary saveImage:image metadata:metadata location:self.location];
      }else{
        NSLog(@"save photos into application folder");
        //[self saveImageIntoDocument:image metadata:metadata];
        [self.saveFunction saveImageIntoDocument:image metadata:metadata album:self.album];
      }
    } else {
      NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
      // Handle a movie capture
      if (CFStringCompare ((__bridge_retained CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        NSURL *moviePath = [info objectForKey:UIImagePickerControllerMediaURL];
        // [self.videoUrl addObject:moviePath];
        //NSLog(@"number of video taken count %lu",(unsigned long)self.videoUrl.count);
        if (self.saveInAlbum) {
          NSLog(@"save video into album");
          //[localLibrary saveVideo:moviePath location:self.location];
        } else {
          NSLog(@"save video into application folder");
          [self.saveFunction saveVideoIntoDocument:moviePath album:self.album];
          //[self saveVideoIntoDocument:moviePath];
        }
        
      }
      CFRelease((__bridge CFTypeRef)(mediaType));
    }
  });
  //totalAssets = (int)self.tmpPhotos.count +(int)self.videoUrl.count;
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
