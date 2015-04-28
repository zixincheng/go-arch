//
//  SaveToDocument.m
//  Go Arch
//
//  Created by zcheng on 2015-03-24.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "SaveToDocument.h"

@implementation SaveToDocument

- (id) init {
    self = [super init];
    appDelegate = [[UIApplication sharedApplication] delegate];
    self.dataWrapper = appDelegate.dataWrapper;
    account = appDelegate.account;
    self.localDevice = [self.dataWrapper getDevice:account.cid];

    
    return self;
}

- (void) saveImageAssetIntoDocument:(ALAsset *)asset album:(CSAlbum *)album {
        @autoreleasepool {

    NSDictionary *meta = asset.defaultRepresentation.metadata;
    
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
        p.album = album;
        
        NSString *tmpFullPath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/%@.jpg", photoUID]];
        NSString *tmpThumbPath = [documentsPath stringByAppendingString:[NSString stringWithFormat:@"/thumb_%@.jpg", photoUID]];
        
        // save the metada information into image
        ALAssetRepresentation *assetRep = [asset defaultRepresentation];
        CGImageRef imgRef = [assetRep fullResolutionImage];
        UIImageOrientation orientation = UIImageOrientationUp;
        orientation = [assetRep orientation];
        UIImage *image = [UIImage imageWithCGImage:imgRef
                                                 scale:1.0f
                                           orientation:orientation];
            
        NSData *data = UIImageJPEGRepresentation(image, 100);
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
        
        CFStringRef UTI = CGImageSourceGetType(source);
        NSMutableData *dest_data = [NSMutableData data];
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef) dest_data, UTI, 1, NULL);
        
        CGImageDestinationAddImageFromSource(
                                             destination, source, 0, (__bridge CFDictionaryRef)meta);
        
        CGImageDestinationFinalize(destination);
        
        
        [dest_data writeToFile:tmpFullPath atomically:YES];
        
        
        UIImage *thumImage = [self resizeImage:(UIImage *)image];
        
        NSData *thumbdata = UIImageJPEGRepresentation(thumImage, 0.6);
        [thumbdata writeToFile:tmpThumbPath atomically:YES];
        
        CFRelease(destination);
        CFRelease(source);
        //CGImageRelease(imgRef);
    
        [self.dataWrapper addPhoto:p];
        }
}


- (void) saveImageIntoDocument:(UIImage *)image metadata:(NSDictionary *)metadata album:(CSAlbum *)album{
    
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
    p.album = album;
    
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
    //self.unUploadedPhotos++;
}

-(void) saveVideoIntoDocument:(NSURL *)moviePath album:(CSAlbum *)album{
    
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
    UIImage *thumImage = [self resizeImage:(UIImage *)thumbnail];
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
    NSData *thumbData = [NSData dataWithData:UIImageJPEGRepresentation(thumImage, 1.0)];
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
    p.album = album;
    
    [self.dataWrapper addPhoto:p];
    
    //self.unUploadedPhotos++;
    
}

-(void) saveVideoAssetIntoDocument:(ALAsset *)assets album:(CSAlbum *)album{
    
    NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/MyVideo"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:documentsPath withIntermediateDirectories:NO attributes:nil error:nil];}
    
    NSURL *moviePath = [[assets valueForProperty:ALAssetPropertyURLs] valueForKey:[[[assets valueForProperty:ALAssetPropertyURLs] allKeys] objectAtIndex:0]];
    
    // generate thumbnail for video
    AVAsset *asset = [AVAsset assetWithURL:moviePath];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = [asset duration];
    time.value = 0;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    UIImage *thumImage = [self resizeImage:(UIImage *)thumbnail];
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
    
    ALAssetRepresentation *rep = [assets defaultRepresentation];
    Byte *buffer = (Byte*)malloc(rep.size);
    NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
    NSData *videoData = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
    
    [videoData writeToFile:tmpFullPath atomically:YES];
    NSData *thumbData = [NSData dataWithData:UIImageJPEGRepresentation(thumImage, 1.0)];
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
    p.album = album;
    
    [self.dataWrapper addPhoto:p];
    
    //self.unUploadedPhotos++;
    
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
    
    [result drawInRect:CGRectMake(0, 0, 380, 380)];
    tempImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return tempImage;
}


@end
