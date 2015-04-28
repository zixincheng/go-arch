//
//  SaveToDocument.h
//  Go Arch
//
//  Created by zcheng on 2015-03-24.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSPhoto.h"
#import "AppDelegate.h"
#import "CoreDataWrapper.h"
#import "AccountDataWrapper.h"
#import "CSDevice.h"
#import "CSLocation.h"


@interface SaveToDocument : NSObject {
    AppDelegate *appDelegate;
    AccountDataWrapper *account;
}
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) CSDevice *localDevice;

- (void) saveImageIntoDocument:(UIImage *)image metadata:(NSDictionary *)metadata album:(CSAlbum *)album;

-(void) saveVideoIntoDocument:(NSURL *)moviePath album:(CSAlbum *)album;
- (void) saveImageAssetIntoDocument:(ALAsset *)asset album:(CSAlbum *)album;
-(void) saveVideoAssetIntoDocument:(ALAsset *)assets album:(CSAlbum *)album;
@end
