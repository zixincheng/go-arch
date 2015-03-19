//
//  DetailsViewController.m
//  Go Arch
//
//  Created by Jake Runzer on 3/19/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "DetailsViewController.h"

@implementation DetailsViewController

- (void) viewDidLoad {
}

- (void) viewWillAppear:(BOOL)animated {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"SetRightButtonText" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Edit", @"text", nil]];
}

@end
