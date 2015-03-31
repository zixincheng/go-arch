//
//  FilterStepper.h
//  Go Arch
//
//  Created by zcheng on 2015-03-30.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FilterStepper;

typedef void (^ValueChangeCallBack) (FilterStepper *stepper, float Value);
typedef void (^ValuePlusCallBack) (FilterStepper *stepper, float Value);
typedef void (^ValueMinusCallBack) (FilterStepper *stepper, float Value);

@interface FilterStepper : UIControl

@property(nonatomic, strong) UILabel *countLabel;
@property(nonatomic, strong) UIButton *plusButton;
@property(nonatomic, strong) UIButton *minusButton;

@property(nonatomic) float value;
@property(nonatomic) float stepInterval;
@property(nonatomic) float min;
@property(nonatomic) float max;

@property(nonatomic, copy) ValueChangeCallBack valueChnageCallback;
@property(nonatomic, copy) ValuePlusCallBack valuePlusCallBack;
@property(nonatomic, copy) ValueMinusCallBack valueMinusCallBack;

-(void) setUp;
@end
