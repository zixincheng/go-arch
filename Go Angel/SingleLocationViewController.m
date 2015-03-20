//
//  SingleLocationViewController.m
//  Go Arch
//
//  Created by Jake Runzer on 3/18/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "SingleLocationViewController.h"

@implementation SingleLocationViewController {
  
  BOOL enableEdit;
  BOOL takingPhoto;
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
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setRightButtonText:) name:@"SetRightButtonText" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showShareDelete:) name:@"ShowShareDelete" object:nil];
}

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

- (void) setRightButtonText: (NSNotification *)n {
  if ([n userInfo] && [n.userInfo objectForKey:@"text"]) {
    NSString *text = [n.userInfo objectForKey:@"text"];
    _rightButton.title = text;
  }
}

- (void) deleteBtnPressed {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"DeleteButtonPressed" object:nil];
}

- (void) shareAction {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ShareButtonPressed" object:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  NSString * segueName = segue.identifier;
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

- (void) takePhotoOrVideo {
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
  [self dismissViewControllerAnimated:YES completion:nil];
  
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
