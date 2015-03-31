//
//  FilterTableViewController.h
//  Go Arch
//
//  Created by zcheng on 2015-03-30.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FilterStepper.h"

@interface FilterTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet FilterStepper *bathroomsStepper;
@property (weak, nonatomic) IBOutlet FilterStepper *listing;
@property (weak, nonatomic) IBOutlet FilterStepper *type;
@property (weak, nonatomic) IBOutlet FilterStepper *bedroomStepper;

@property (weak, nonatomic) IBOutlet UISlider *priceSlider;

@end
