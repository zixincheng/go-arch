//
//  GridCell.h
//  Go Arch
//
//  Created by Jake Runzer on 8/8/14.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CSPhoto.h"
#import "AppDelegate.h"

// custom grid cell for collection view

@interface GridCell : UICollectionViewCell {
    
    UIImageView * _imageView;
    UILabel * _titleLabel;
    CSPhoto *_photo;
}
@property (strong) UIImage *image;
@property (strong) CSPhoto *photo;
@property (strong) UIImageView *imageView;

- (void) setPhoto:(CSPhoto *)photo;

@end
