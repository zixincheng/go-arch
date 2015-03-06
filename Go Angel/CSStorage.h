//
//  CSStorage.h
//  Go Arch
//
//  Created by zcheng on 2014-11-20.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSStorage : NSObject

@property (strong) NSString *uuid;
@property (strong) NSString *storageLabel;
@property (strong) NSString *pluged_in;
@property (strong) NSString *mounted;
@property (strong) NSString *primary;
@property (strong) NSString *backup;
@property (strong) NSNumber *freeSpace;
@property (strong) NSNumber *totalSpace;
@end
