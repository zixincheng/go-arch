//
//  FilterTableViewController.m
//  Go Arch
//
//  Created by zcheng on 2015-03-30.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "FilterTableViewController.h"
#import "SegmentedViewController.h"

@interface FilterTableViewController ()

@end

@implementation FilterTableViewController {
    BOOL homeSizepickerHidden;
    BOOL lotSizepickerHidden;
}
@synthesize delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = NO;
    homeSizepickerHidden = true;
    lotSizepickerHidden = true;
    [self createPickerView];
    appDelegate = [[UIApplication sharedApplication] delegate];
    //self.buildingSize = [[NSNumber alloc]init];
    //self.landSize = [[NSNumber alloc]init];
    
    self.bedroomStepper.value = 0;
    self.bedroomStepper.stepInterval = 1;
    self.bedroomStepper.max = 7;
    self.bedroomStepper.valueChnageCallback = ^(FilterStepper *stepper,float number) {
        if (number == 0) {
            stepper.countLabel.text = @"Any";
        } else if (number == 7){
            stepper.countLabel.text = [NSString stringWithFormat:@"Bedrooms 6+"];
        } else {
            stepper.countLabel.text = [NSString stringWithFormat:@"Bedrooms %@",@(number)];
        }
    };
    [self.bedroomStepper setUp];
    
    self.bathroomsStepper.value = 0;
    self.bathroomsStepper.stepInterval = 1;
    self.bathroomsStepper.max = 6;
    self.bathroomsStepper.valueChnageCallback = ^(FilterStepper *stepper,float number) {
        if (number == 0) {
            stepper.countLabel.text = @"Any";
        } else if (number == 6) {
            stepper.countLabel.text = @"Bathrooms 6+";
        } else {
            stepper.countLabel.text = [NSString stringWithFormat:@"Bathrooms %@",@(number)];
        }
    };
    [self.bathroomsStepper setUp];
    
    self.listing.value = 0;
    self.listing.stepInterval = 1;
    self.listing.max = 3;
    self.listing.valueChnageCallback = ^(FilterStepper *stepper,float number) {
        if (number == 0) {
            stepper.countLabel.text = @"Any";
        } else if (number == 1) {
            stepper.countLabel.text = @"For Rent";
        } else if (number == 2) {
            stepper.countLabel.text = @"For Sale";
        } else if (number == 3) {
            stepper.countLabel.text = @"For Sale Or Rent";
        }
    };
    [self.listing setUp];
    
    self.type.value = 0;
    self.type.stepInterval = 1;
    self.type.max = 9;
    self.type.valueChnageCallback = ^(FilterStepper *stepper,float number) {
        if (number == 0) {
            stepper.countLabel.text = @"Any";
        } else if (number == 1) {
            stepper.countLabel.text = @"Condominium";
        } else if (number == 2) {
            stepper.countLabel.text = @"Commercial";
        } else if (number == 3) {
            stepper.countLabel.text = @"Farm";
        } else if (number == 4) {
            stepper.countLabel.text = @"House";
        } else if (number == 5) {
            stepper.countLabel.text = @"Land";
        } else if (number == 6) {
            stepper.countLabel.text = @"Parking";
        } else if (number == 7) {
            stepper.countLabel.text = @"Residential";
        } else if (number == 8) {
            stepper.countLabel.text = @"Recretional";
        } else if (number == 8) {
            stepper.countLabel.text = @"TownHouses";
        }
    };
    [self.type setUp];
    
    self.priceMaxSlider.maximumValue = 2500000;
    self.priceMinSlider.maximumValue = 2500000;
    self.priceMaxSlider.value = 2500000;
    self.priceMinSlider.value = 0;
    self.priceMaxLabel.text = @"No Max Price";
    self.priceMinLabel.text = @"No Min Price";
    
    self.yearBuiltSilder.maximumValue = 2015;
    self.yearBuiltSilder.minimumValue = 1965;
    self.yearBuiltSilder.value = 1965;
    self.yearBuiltLabel.text = @"1965 or early";
    
    self.buildingSize = [NSNumber numberWithInt: 0];
    self.landSize = [NSNumber numberWithInt: 0];
    self.homeSizeLabel.text = @"Any";
    self.lotSizeLabel.text = @"Any";
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma slide bar functions
- (IBAction)priceMaxSliderChanged:(id)sender {
    NSLocale *locale = [NSLocale currentLocale];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setLocale:locale];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setNegativeFormat:@"-¤#,##0.00"];
    [formatter setMaximumFractionDigits:0];
    if (self.priceMaxSlider.value >= self.priceMinSlider.value) {
        self.priceMaxSlider.value = roundf(self.priceMaxSlider.value*0.01)*100;
        NSNumber *sliderValue = [NSNumber numberWithInt:(int)roundf(self.priceMaxSlider.value)];
        
        NSString *formatted = [formatter stringFromNumber:sliderValue];
        self.priceMaxLabel.text = [NSString stringWithFormat:@"%@",formatted];
    } else {
        self.priceMaxSlider.value = self.priceMinSlider.value;
    }
    
    if (self.priceMaxSlider.value == 2500000) {
        self.priceMaxLabel.text = [NSString stringWithFormat:@"No Max Price"];
    }
}
- (IBAction)priceMinSliderChanged:(id)sender {
    NSLocale *locale = [NSLocale currentLocale];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setLocale:locale];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setNegativeFormat:@"-¤#,##0.00"];
    [formatter setMaximumFractionDigits:0];
    if (self.priceMinSlider.value <= self.priceMaxSlider.value) {
        self.priceMinSlider.value = roundf(self.priceMinSlider.value*0.001)*1000;
        NSNumber *sliderValue = [NSNumber numberWithInt:(int)roundf(self.priceMinSlider.value)];
        
        NSString *formatted = [formatter stringFromNumber:sliderValue];
        self.priceMinLabel.text = [NSString stringWithFormat:@"%@",formatted ];
    } else {
        self.priceMinSlider.value = self.priceMaxSlider.value;
    }
    
    if (self.priceMinSlider.value == 0) {
        self.priceMinLabel.text = [NSString stringWithFormat:@"No Min Price"];
    }
}
- (IBAction)yearBuiltSliderChanged:(id)sender {
    
    if (self.yearBuiltSilder.value == 1965) {
        self.yearBuiltLabel.text = @"1965 or early";
    } else {
        self.yearBuiltLabel.text = [NSString stringWithFormat:@"%d or younger",(int)self.yearBuiltSilder.value];
    }
    
}


#pragma mark -  cancel cand save button functions
- (IBAction)cancelBtnAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveBtnAction:(id)sender {
    NSMutableDictionary *filterInfo = [[NSMutableDictionary alloc]init];
    [filterInfo setValue:[NSNumber numberWithInt:(int)roundf(self.priceMaxSlider.value)] forKey:@"MaxPrice"];
    [filterInfo setValue:[NSNumber numberWithInt:(int)roundf(self.priceMinSlider.value)] forKey:@"MinPrice"];
    [filterInfo setValue:[NSString stringWithFormat:@"%@",@(self.bedroomStepper.value)] forKey:@"bedRoom"];
    [filterInfo setValue:[NSString stringWithFormat:@"%@",@(self.bathroomsStepper.value)] forKey:@"bathRoom"];
    [filterInfo setValue:self.listing.countLabel.text forKey:@"listing"];
    [filterInfo setValue:self.type.countLabel.text forKey:@"type"];
    [filterInfo setValue:[NSString stringWithFormat:@"%@",@(self.yearBuiltSilder.value)] forKey:@"yearBuilt"];
    [filterInfo setValue:self.buildingSize forKey:@"homeSize"];
    [filterInfo setValue:self.landSize forKey:@"lotSize"];
    
    NSMutableArray *filterLocationArray = [appDelegate.dataWrapper filterLocations:filterInfo];
    
    if ([delegate respondsToSelector:@selector(filterInfo:)]) {
        [delegate filterInfo:filterLocationArray];
    }
    [self.navigationController popViewControllerAnimated:YES];
    
}

#pragma mark - picker view functions
#pragma mark - picker view datasource and delegate
// Number of components.
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

// Total rows in our component.
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    if (pickerView.tag == 0) {
        return self.homeSizedataArray.count;
    } else{
        return self.lotSizedataArray.count;
    }
}

// Display each row's data.
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if (pickerView.tag == 0) {
        self.buildingSize =[self.homeSizedataArray objectAtIndex:row];
        if ([self.homeSizedataArray objectAtIndex:row] == [NSNumber numberWithInt:0]) {
             return @"Any";
        } else {
        return [NSString stringWithFormat:@"%@+ Sq Ft",[self formatArea:[self.homeSizedataArray objectAtIndex:row]]];
        }
    } else {
        self.landSize =[self.lotSizedataArray objectAtIndex:row];
        if ([self.lotSizedataArray objectAtIndex:row] == [NSNumber numberWithInt:0]) {
            return @"Any";
        } else if ([self.lotSizedataArray objectAtIndex:row] < [NSNumber numberWithInt:10000]){
            return [NSString stringWithFormat:@"%@+ Sq Ft",[self formatArea:[self.lotSizedataArray objectAtIndex:row]]];
        } else {
            NSNumber *x = [self.lotSizedataArray objectAtIndex:row];
            double y = [x doubleValue];
            NSNumber *arcers = [NSNumber numberWithDouble:y/43560];
            return [NSString stringWithFormat:@"%@+ Acres",[self formatArea:arcers]];
        }
    }
}

// Do something with the selected row.
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if (pickerView.tag == 0) {
        if ([self.homeSizedataArray objectAtIndex:row] == [NSNumber numberWithInt:0]) {
            self.homeSizeLabel.text =  @"Any";
        } else {
            self.homeSizeLabel.text = [NSString stringWithFormat:@"%@+ Sq Ft",[self formatArea:[self.homeSizedataArray objectAtIndex:row]]];
        }
    } else {
        NSLog(@"You selected this: %@", [self.lotSizedataArray objectAtIndex: row]);
        if ([self.lotSizedataArray objectAtIndex:row] == [NSNumber numberWithInt:0]) {
            self.lotSizeLabel.text = @"Any";
        } else if ([self.lotSizedataArray objectAtIndex:row] < [NSNumber numberWithInt:10000]){
            self.lotSizeLabel.text = [NSString stringWithFormat:@"%@+ Sq Ft",[self formatArea:[self.lotSizedataArray objectAtIndex:row]]];
        } else {
            NSNumber *x = [self.lotSizedataArray objectAtIndex:row];
            double y = [x doubleValue];
            NSNumber *arcers = [NSNumber numberWithDouble:y/43560];
            self.lotSizeLabel.text = [NSString stringWithFormat:@"%@+ Acres",[self formatArea:arcers]];

        }
    }

}

-(void) togglePicker:(NSIndexPath *) indexPath {
    if (indexPath == [NSIndexPath indexPathForRow:0 inSection:6]) {
        homeSizepickerHidden = !homeSizepickerHidden;
    } else {
        lotSizepickerHidden = !lotSizepickerHidden;
    }
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    [self.tableView reloadData];
}

-(void) createPickerView {
    
    
    self.homeSizedataArray = [[NSMutableArray alloc] init];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:0]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:600]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:800]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:1000]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:1200]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:1200]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:1400]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:1600]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:1800]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:2000]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:2250]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:2500]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:2750]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:3000]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:3500]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:4000]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:5000]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:6000]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:7000]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:8000]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:9000]];
    [self.homeSizedataArray addObject:[NSNumber numberWithInt:10000]];
    
    
    self.lotSizedataArray = [[NSMutableArray alloc] init];
    [self.lotSizedataArray addObject:[NSNumber numberWithInt:0]];
    [self.lotSizedataArray addObject:[NSNumber numberWithInt:4000]];
    [self.lotSizedataArray addObject:[NSNumber numberWithInt:6000]];
    [self.lotSizedataArray addObject:[NSNumber numberWithInt:8000]];
    [self.lotSizedataArray addObject:[NSNumber numberWithInt:43560/4]];
    [self.lotSizedataArray addObject:[NSNumber numberWithInt:43560/2]];
    [self.lotSizedataArray addObject:[NSNumber numberWithInt:43560]];
    [self.lotSizedataArray addObject:[NSNumber numberWithInt:43560*2]];
    [self.lotSizedataArray addObject:[NSNumber numberWithInt:43560*5]];
    [self.lotSizedataArray addObject:[NSNumber numberWithInt:43560*5]];
    [self.lotSizedataArray addObject:[NSNumber numberWithInt:43560*10]];
    [self.lotSizedataArray addObject:[NSNumber numberWithInt:43560*20]];
    
    
}

- (NSString *) formatArea:(NSNumber *)area {
    NSNumberFormatter *formatSQFT = [[NSNumberFormatter alloc] init];
    [formatSQFT setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatSQFT setMaximumFractionDigits:2];
    [formatSQFT setRoundingMode:NSNumberFormatterRoundHalfUp];
    
    NSString *result = [formatSQFT stringFromNumber:area];
    return result;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            return 2;
            break;
        case 6:
            return 4;
            break;
        default:
            return 1;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath == [NSIndexPath indexPathForRow:0 inSection:0] || indexPath==[NSIndexPath indexPathForRow:1 inSection:0] || indexPath==[NSIndexPath indexPathForRow:0 inSection:5]) {
        return 60;
    } else if (indexPath == [NSIndexPath indexPathForRow:1 inSection:6]){
        if (homeSizepickerHidden) {
            return 0;
        } else {
            return 200;
        }
    } else if (indexPath == [NSIndexPath indexPathForRow:3 inSection:6]) {
        if (lotSizepickerHidden) {
            return 0;
        } else {
            return 200;
        }
    }
    else {
        return 44;
    }
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *homesizeIndex = [NSIndexPath indexPathForRow:0 inSection:6];
    NSIndexPath *lotsizeIndex = [NSIndexPath indexPathForRow:2 inSection:6];
    if (indexPath == homesizeIndex) {
        NSLog(@"home size");
        [self togglePicker: indexPath];
        /*
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        self.pickerViewContainer.frame = CGRectMake(0, 580, 320, 300);
        [UIView commitAnimations];*/
    } else if (indexPath == lotsizeIndex) {
        NSLog(@"lot size ");
        [self togglePicker: indexPath];
    }
}

@end
