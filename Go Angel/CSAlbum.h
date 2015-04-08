//
//  CSLocationMeta.h
//  Go Arch
//
//  Created by zcheng on 2015-03-23.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CSLocation;
@interface CSAlbum : NSObject

@property (nonatomic, strong) NSString *tag;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSNumber *price;
@property (nonatomic, strong) NSString *listing;
@property (nonatomic, strong) NSString *yearBuilt;
@property (nonatomic, strong) NSString *bed;
@property (nonatomic, strong) NSString *bath;
@property (nonatomic, strong) NSNumber *buildingSqft;
@property (nonatomic, strong) NSNumber *landSqft;
@property (nonatomic, strong) NSString *mls;
@property (nonatomic, strong) NSString *albumDescritpion;
@property (nonatomic, strong) NSString *albumId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *coverImage;
@property (nonatomic, strong) CSLocation *location;

@end
