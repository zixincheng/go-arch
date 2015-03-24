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
  

  localLibrary = [[LocalLibrary alloc] init];
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
  
  // register for notifications from child controllers providing info
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRightButtonText:) name:@"SetRightButtonText" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showShareDelete:) name:@"ShowShareDelete" object:nil];
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
    _pageController.coinsorter = _coinsorter;
    _pageController.dataWrapper = _dataWrapper;
    _pageController.localDevice = _localDevice;
    _pageController.location = _location;
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
            
            [localLibrary saveImage:image metadata:metadata location:self.location];
          }else{
            NSLog(@"save photos into application folder");
            [self saveImageIntoDocument:image metadata:metadata];
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
              [localLibrary saveVideo:moviePath location:self.location];
            } else {
              NSLog(@"save video into application folder");              
              [self saveVideoIntoDocument:moviePath];
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
        
        [localLibrary saveImage:image metadata:metadata location:self.location];
      }else{
        NSLog(@"save photos into application folder");
        [self saveImageIntoDocument:image metadata:metadata];
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
          [localLibrary saveVideo:moviePath location:self.location];
        } else {
          NSLog(@"save video into application folder");
          [self saveVideoIntoDocument:moviePath];
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


# pragma mark - saving assets

-(void) saveVideoIntoDocument:(NSURL *)moviePath {
  
  NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/MyVideo"];
  if (![[NSFileManager defaultManager] fileExistsAtPath:documentsPath]){
    [[NSFileManager defaultManager] createDirectoryAtPath:documentsPath withIntermediateDirectories:NO attributes:nil error:nil];}
  
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
  // NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  //NSString *documentsPath = [paths objectAtIndex:0];
  
  
  NSString *photoUID = [[NSProcessInfo processInfo] globallyUniqueString];
  NSString *thumbPath = [@"MyVideo" stringByAppendingString:[NSString stringWithFormat:@"/thumb_%@.jpg", photoUID]];
  NSString *filePath = [@"MyVideo" stringByAppendingString:[NSString stringWithFormat:@"/%@.mov", photoUID]];
  
  NSString *tmpFullPath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@.mov", photoUID]];
  NSString *tmpThumbPath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/thumb_%@.jpg", photoUID]];
  //NSString *fullPath = [[NSURL fileURLWithPath:filePath] absoluteString];
  
  NSData *videoData = [NSData dataWithContentsOfURL:moviePath];
  
  [videoData writeToFile:tmpFullPath atomically:YES];
  NSData *thumbData = [NSData dataWithData:UIImageJPEGRepresentation(thumbnail, 1.0)];
  [thumbData writeToFile:tmpThumbPath atomically:YES];
  //[self.photoPath addObject:filePath];
  CSPhoto *p = [[CSPhoto alloc] init];
  
  p.dateCreated = [NSDate date];
  p.deviceId = self.localDevice.remoteId;
  p.thumbOnServer = @"0";
  p.fullOnServer = @"0";
  p.thumbURL = thumbPath;
  p.imageURL = filePath;
  p.fileName = [NSString stringWithFormat:@"%@.mov",photoUID];
  p.thumbnailName = [NSString stringWithFormat:@"thumb_%@.jpg", photoUID];
  p.isVideo = @"1";
  p.cover = @"0";
  p.location = self.location;
  
  [self.dataWrapper addPhoto:p];
  
  //self.unUploadedPhotos++;
  
}

// save photos to the document directory and save to core data
- (void) saveImageIntoDocument:(UIImage *)image metadata:(NSDictionary *)metadata {
  
  //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  
  //NSString *documentsPath = [paths objectAtIndex:0];
  NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/MyImage"];
  if (![[NSFileManager defaultManager] fileExistsAtPath:documentsPath]){
    [[NSFileManager defaultManager] createDirectoryAtPath:documentsPath withIntermediateDirectories:NO attributes:nil error:nil];}
  
  NSString *photoUID = [[NSProcessInfo processInfo] globallyUniqueString];
  
  NSString *filePath = [@"MyImage" stringByAppendingString:[NSString stringWithFormat:@"/%@.jpg", photoUID]];
  // NSString *fullPath = [[NSURL fileURLWithPath:filePath] absoluteString];
  
  NSString *thumbPath = [@"MyImage" stringByAppendingString:[NSString stringWithFormat:@"/thumb_%@.jpg", photoUID]];
  
  //[self.photoPath addObject:filePath];
  CSPhoto *p = [[CSPhoto alloc] init];
  
  p.dateCreated = [NSDate date];
  p.deviceId = self.localDevice.remoteId;
  p.thumbOnServer = @"0";
  p.fullOnServer = @"0";
  p.thumbURL = thumbPath;
  p.imageURL = filePath;
  p.fileName = [NSString stringWithFormat:@"%@.jpg", photoUID];
  p.thumbnailName = [NSString stringWithFormat:@"thumb_%@.jpg", photoUID];
  p.isVideo = @"0";
  p.cover = @"0";
  p.location = self.location;
  
  NSString *tmpFullPath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@.jpg", photoUID]];
  NSString *tmpThumbPath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/thumb_%@.jpg", photoUID]];
  
  // save the metada information into image
  NSData *data = UIImageJPEGRepresentation(image, 100);
  CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
  
  CFStringRef UTI = CGImageSourceGetType(source);
  NSMutableData *dest_data = [NSMutableData data];
  CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef) dest_data, UTI, 1, NULL);
  
  CGImageDestinationAddImageFromSource(
                                       destination, source, 0, (__bridge CFDictionaryRef)metadata);
  
  CGImageDestinationFinalize(destination);
  
  
  [dest_data writeToFile:tmpFullPath atomically:YES];
  
  
  UIImage *thumImage = [self resizeImage:(UIImage *)image];
  
  NSData *thumbdata = UIImageJPEGRepresentation(thumImage, 0.6);
  [thumbdata writeToFile:tmpThumbPath atomically:YES];
  
  CFRelease(destination);
  CFRelease(source);
  
  [self.dataWrapper addPhoto:p];
}

- (UIImage *) resizeImage: (UIImage *)image {
  
  UIImage *tempImage = nil;
  CGSize targetSize = CGSizeMake(360,360);
  
  CGSize size = image.size;
  CGSize croppedSize;
  
  CGFloat offsetX = 0.0;
  CGFloat offsetY = 0.0;
  
  if (size.width > size.height) {
    offsetX = (size.height - size.width) / 2;
    croppedSize = CGSizeMake(size.height, size.height);
  } else {
    offsetY = (size.width - size.height) / 2;
    croppedSize = CGSizeMake(size.width, size.width);
  }
  
  CGRect clippedRect = CGRectMake(offsetX * -1, offsetY * -1, croppedSize.width, croppedSize.height);
  
  CGAffineTransform rectTransform;
  switch (image.imageOrientation)
  {
    case UIImageOrientationLeft:
      rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(M_PI_2), 0, -image.size.height);
      break;
    case UIImageOrientationRight:
      rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-M_PI_2), -image.size.width, 0);
      break;
    case UIImageOrientationDown:
      rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(-M_PI), -image.size.width, -image.size.height);
      break;
    default:
      rectTransform = CGAffineTransformIdentity;
  };
  
  rectTransform = CGAffineTransformScale(rectTransform, image.scale, image.scale);
  
  
  CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectApplyAffineTransform(clippedRect, rectTransform));
  UIImage *result = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
  CGImageRelease(imageRef);
  
  UIGraphicsBeginImageContext(targetSize);
  
  [result drawInRect:CGRectMake(0, 0, 360, 360)];
  tempImage = UIGraphicsGetImageFromCurrentImageContext();
  
  UIGraphicsEndImageContext();
  return tempImage;
}



@end
