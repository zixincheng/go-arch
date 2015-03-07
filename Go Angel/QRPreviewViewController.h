//
//  QRPreviewViewController.h
//  Go Arch
//
//  Created by Jake Runzer on 3/4/15.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Coinsorter.h"
#import "CoreDataWrapper.h"

@interface QRPreviewViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *lblError;

@property (strong, nonatomic) Coinsorter *coinsorter;
@property (strong, nonatomic) CoreDataWrapper *dataWrapper;

@end
