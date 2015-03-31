//
//  FilterStepper.m
//  Go Arch
//
//  Created by zcheng on 2015-03-30.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "FilterStepper.h"

@implementation FilterStepper

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self customInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self customInit];
    }
    return self;
}

-(void) customInit {
    
    self.value = 0.0f;
    self.stepInterval = 1.0f;
    self.min = 0.0f;
    self.max = 10.0f;
    
    self.countLabel = [[UILabel alloc]init];
    self.countLabel.textAlignment = NSTextAlignmentCenter;
    self.countLabel.layer.borderWidth = 1.0f;
    [self addSubview:self.countLabel];
    
    self.plusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.plusButton setTitle:@"+" forState:UIControlStateNormal];
    [self.plusButton addTarget:self action:@selector(plusButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.plusButton];
    
    self.minusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.minusButton setTitle:@"-" forState:UIControlStateNormal];
    [self.minusButton addTarget:self action:@selector(miunsButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.minusButton];
    
    [self.countLabel setFont:[UIFont fontWithName:@"Avernir-Roman" size:14.0f]];
    self.plusButton.titleLabel.font = [UIFont fontWithName:@"Avenir-Black" size:24.0f];
    self.minusButton.titleLabel.font = [UIFont fontWithName:@"Avenir-Black" size:24.0f];
    
    UIColor *defaultColor = [UIColor colorWithRed:(79/255.0) green:(161/255.0) blue:(210/255.0) alpha:1.0];
    
    self.layer.borderColor = defaultColor.CGColor;
    self.countLabel.layer.borderColor = defaultColor.CGColor;
    self.countLabel.textColor = defaultColor;
    [self.plusButton setTitleColor:defaultColor forState:UIControlStateNormal];
    [self.minusButton setTitleColor:defaultColor forState:UIControlStateNormal];
    
    self.layer.borderWidth = 1.0f;
    self.layer.cornerRadius = 3.0;
    
}

- (void)layoutSubviews
{
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    self.countLabel.frame = CGRectMake(44.0f, 0, width - (44.0f * 2), height);
    self.plusButton.frame = CGRectMake(width - 44.0f, 0, 44.0f, height);
    self.minusButton.frame = CGRectMake(0, 0, 44.0f, height);
    
}

-(void) setUp {
    if (self.valueChnageCallback)
    {
        self.valueChnageCallback(self, self.value);
    }
}

- (void)setValue:(float)value
{
    _value = value;

    
    if (self.valueChnageCallback)
    {
        self.valueChnageCallback(self, self.value);
    }
}


-(void) plusButtonAction: (id) sender {
    
    if (self.value < self.max)
    {
        self.value += self.stepInterval;
        if (self.valuePlusCallBack)
        {
            self.valuePlusCallBack(self, self.value);
        }
    }
    
}

-(void) miunsButtonAction: (id) sender {
    
    if (self.value > self.min)
    {
        self.value -= self.stepInterval;
        if (self.valueMinusCallBack)
        {
            self.valueMinusCallBack(self, self.value);
        }
    }
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
