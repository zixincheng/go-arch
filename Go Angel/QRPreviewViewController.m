//
//  QRPreviewViewController.m
//  Go Arch
//
//  Created by Jake Runzer on 3/4/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "QRPreviewViewController.h"

@interface QRPreviewViewController ()

@end

@implementation QRPreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
  
  _dataWrapper = [[CoreDataWrapper alloc] init];
  _coinsorter = [[Coinsorter alloc] initWithWrapper:self.dataWrapper];
  
  [self getQR];
}

- (void) getQR {
  [_coinsorter getQRCode:^(NSString *base64) {
    if (base64) {
      NSLog(@"%@", base64);
      
      NSData *data = [[NSData alloc] initWithBase64EncodedString:base64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
      UIImage *image = [UIImage imageWithData:data];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [_lblError setHidden:YES];
        [_imageView setHidden:NO];
        [_imageView setImage:image];
      });
      
    } else {
      dispatch_async(dispatch_get_main_queue(), ^{
        [_lblError setHidden:NO];
        [_imageView setHidden:YES];
      });
    
    }
  }];
}

@end
