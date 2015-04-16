//
//  CSLocation.h
//  Go Arch
//
//  Created by zcheng on 2015-01-21.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CSPhoto;
@class CSEntry;
@interface CSLocation : NSObject


@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *province;
@property (nonatomic, strong) NSString *unit;
@property (nonatomic, strong) NSString *sublocation;
@property (nonatomic, strong) NSString *postCode;
@property (nonatomic, strong) NSString *longitude;
@property (nonatomic, strong) NSString *latitude;
@property (nonatomic, strong) NSString *altitude;

@property (nonatomic, strong) CSPhoto *photo;
@property (nonatomic, strong) CSEntry *entry;

// the nsmanagedobject uri
@property (nonatomic, strong) NSString *objectUri;

@end
