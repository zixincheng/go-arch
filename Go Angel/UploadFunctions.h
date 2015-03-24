//
//  UploadFunctions.h
//  Go Arch
//
//  Created by zcheng on 2015-03-24.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Coinsorter.h"
#import "NetWorkCheck.h"
#import "AppDelegate.h"
#import "AccountDataWrapper.h"
#import "CoreDataWrapper.h"
#import "CSPhoto.h"

@interface UploadFunctions : NSObject{
    AppDelegate *appDelegate;
    AccountDataWrapper *account;
    NSUserDefaults *defaults;
}
@property (nonatomic, strong) CoreDataWrapper *dataWrapper;
@property (nonatomic, strong) Coinsorter *coinsorter;
@property (nonatomic, strong) NetWorkCheck *networkStatus;

- (void) uploadPhotosToApi:(NSString *)networkStatus;
- (void) onePhotoThumbToApi:(CSPhoto *)photo networkStatus:(NSString *)networkStatus;

@end
