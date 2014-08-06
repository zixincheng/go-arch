//
//  CSPhoto.m
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "CSPhoto.h"

@implementation CSPhoto

- (id) init {
  self = [super init];
  
  self.taskIdentifier = -1;
  
  return self;
}

- (void) onServerSet:(BOOL)on {
  if (on) {
    self.onServer = @"1";
  }else {
    self.onServer = @"0";
  }
}

@end
