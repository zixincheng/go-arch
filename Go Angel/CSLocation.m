//
//  CSLocation.m
//  Go Arch
//
//  Created by zcheng on 2015-01-21.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "CSLocation.h"

@implementation CSLocation

- (NSString *) formatPrice:(NSNumber *)price {
  NSLocale *locale = [NSLocale systemLocale];
  
  NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
  [formatter setLocale:locale];
  [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
  [formatter setCurrencyCode:[locale objectForKey:NSLocaleCurrencyCode]];
  [formatter setNegativeFormat:@"-¤#,##0.00"];
  
  NSString *formatted = [formatter stringFromNumber:price];
  
  return formatted;
}

@end
