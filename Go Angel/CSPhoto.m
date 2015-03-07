//
//  CSPhoto.m
//  Go Arch
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

- (void) thumbOnServerSet:(BOOL)on {
  if (on) {
    self.thumbOnServer = @"1";
  }else {
    self.thumbOnServer = @"0";
  }
}

- (void) fullOnServerSet:(BOOL)on {
    if (on) {
        self.fullOnServer = @"1";
    }else {
        self.fullOnServer = @"0";
    }
}

@end
