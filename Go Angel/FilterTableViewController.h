//
//  FilterTableViewController.h
//  Go Arch
//
//  Created by zcheng on 2015-03-30.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FilterStepper.h"
#import "AppDelegate.h"

@protocol FilterTableViewControllerDelegate <NSObject>
@required

- (void)filterInfo:(NSMutableArray *)data;
@end


@interface FilterTableViewController : UITableViewController <UIPickerViewDataSource, UIPickerViewDelegate>{
    AppDelegate *appDelegate;
}
@property (weak, nonatomic) IBOutlet FilterStepper *bathroomsStepper;
@property (weak, nonatomic) IBOutlet FilterStepper *listing;
@property (weak, nonatomic) IBOutlet FilterStepper *type;
@property (weak, nonatomic) IBOutlet FilterStepper *bedroomStepper;
@property (weak, nonatomic) IBOutlet UILabel *homeSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *lotSizeLabel;

@property (weak, nonatomic) IBOutlet UILabel *priceMaxLabel;
@property (weak, nonatomic) IBOutlet UISlider *priceMaxSlider;
@property (weak, nonatomic) IBOutlet UILabel *priceMinLabel;
@property (weak, nonatomic) IBOutlet UISlider *priceMinSlider;
@property (weak, nonatomic) IBOutlet UILabel *yearBuiltLabel;
@property (weak, nonatomic) IBOutlet UISlider *yearBuiltSilder;

@property (weak, nonatomic) IBOutlet UISlider *priceSlider;

@property (nonatomic, retain) NSMutableArray *homeSizedataArray;
@property (nonatomic, retain) NSMutableArray *lotSizedataArray;

@property (nonatomic, retain) NSNumber *buildingSize;
@property (nonatomic, retain) NSNumber *landSize;

@property (nonatomic, weak) id<FilterTableViewControllerDelegate> delegate;


@end
