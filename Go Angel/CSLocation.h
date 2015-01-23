//
//  CSLocation.h
//  Go Angel
//
//  Created by zcheng on 2015-01-21.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSLocation : NSObject

@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *countryCode;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *province;
@property (nonatomic, strong) NSString *unit;
@property (nonatomic, strong) NSString *name;

@end
