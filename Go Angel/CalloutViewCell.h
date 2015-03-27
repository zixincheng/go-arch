//
//  CalloutViewCell.h
//  Go Arch
//
//  Created by zcheng on 2015-03-26.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CalloutViewCell : UIView
@property (weak, nonatomic) IBOutlet UIImageView *coverImage;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *bedLabel;
@property (weak, nonatomic) IBOutlet UILabel *bathLabel;
@property (weak, nonatomic) IBOutlet UILabel *buildingSQFT;
@property (weak, nonatomic) IBOutlet UILabel *landSQFT;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;

@end
