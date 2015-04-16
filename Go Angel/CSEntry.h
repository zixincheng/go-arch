//
//  CSEntry.h
//  Go Arch
//
//  Created by zcheng on 2015-04-13.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CSLocation;
@class CSAlbum;
@interface CSEntry : NSObject

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

@property (nonatomic, strong) CSLocation *location;
@property (nonatomic, strong) CSAlbum *album;


- (NSString *) formatPrice:(NSNumber *)price;
- (NSString *) formatArea:(NSNumber *)area;

@end
