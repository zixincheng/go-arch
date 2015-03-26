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
  NSLocale *locale = [NSLocale currentLocale];

  NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
  [formatter setLocale:locale];
  [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
  [formatter setNegativeFormat:@"-¤#,##0.00"];
  [formatter setMaximumFractionDigits:0];
  
  NSString *formatted = [formatter stringFromNumber:price];
  
  return formatted;
}

- (NSString *) formatArea:(NSNumber *)area {
  NSNumberFormatter *formatSQFT = [[NSNumberFormatter alloc] init];
  [formatSQFT setNumberStyle:NSNumberFormatterDecimalStyle];
  [formatSQFT setMaximumFractionDigits:2];
  [formatSQFT setRoundingMode:NSNumberFormatterRoundHalfUp];
  
  NSString *result = [formatSQFT stringFromNumber:area];
  return result;
}

@end
