//
//  CSLocationMeta.h
//  Go Arch
//
//  Created by zcheng on 2015-03-23.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSEntry.h"

@interface CSAlbum : NSObject

@property (nonatomic, strong) NSString *albumDescritpion;
@property (nonatomic, strong) NSString *albumId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *coverImage;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) CSEntry *entry;
// the nsmanagedobject id
@property (nonatomic, strong) NSString *objectId;
@end
