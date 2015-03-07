//
//  GridCell.m
//  Go Arch
//
//  Created by Jake Runzer on 8/8/14.
//  Copyright (c) 2014 acdGO Software Ltd. All rights reserved.
//

#import "GridCell.h"

@interface GridCell ()
-(void) setup;
@end
@implementation GridCell

@synthesize image;

-(void)setup{
   // self.backgroundColor = [UIColor whiteColor];
    self.backgroundColor = [UIColor greenColor];
    //  Set image view
    _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [_imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    
    [self addSubview:_imageView];
    
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:_imageView
                                                                      attribute:NSLayoutAttributeLeft
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1
                                                                       constant:0];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:_imageView
                                                                       attribute:NSLayoutAttributeRight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self
                                                                       attribute:NSLayoutAttributeRight
                                                                      multiplier:1
                                                                        constant:-0];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:_imageView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1
                                                                      constant:0];
    
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:_imageView
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1
                                                                         constant:-0];
    
    NSArray *constraints = @[leftConstraint, rightConstraint, topConstraint, bottomConstraint];
    [self addConstraints:constraints];
    
    //  Added black stroke
    self.layer.borderWidth = 1;
    self.layer.borderColor = [UIColor blackColor].CGColor;
    self.clipsToBounds = YES;
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    //  UILabel for title
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.textAlignment = NSTextAlignmentRight;
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.shadowColor = [UIColor blackColor];
    _titleLabel.shadowOffset = CGSizeMake(0, 1);
    _titleLabel.numberOfLines = 1;
    [self addSubview:_titleLabel];
}

#pragma mark - Properties

-(UIImage *)image{
    return _imageView.image;
}

-(void)setImage:(UIImage *)newImage{
    _imageView.image = newImage;
        /*
        _imageView.alpha = 0.0;
        
          //Random delay to avoid all animations happen at once
        float millisecondsDelay = (arc4random() % 700) / 1000.0f;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, millisecondsDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                _imageView.alpha = 1.0;
            }];
        });*/
}

-(CSPhoto *)photo{
    return self.photo;
}
-(void)setPhoto:(CSPhoto *)photo {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    _photo = photo;
    
    [appDelegate.mediaLoader loadThumbnail:photo completionHandler:^(UIImage *Currentimage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __block UIImage *newimage;
                if ([photo.isVideo isEqualToString:@"1"]) {
                   newimage = [self addVideoIcon:Currentimage];
                } else {
                    newimage = Currentimage;
                }

                self.image = newimage;
            });
    }];

    _titleLabel.text = _photo.tag;
}

-(UIImage *)addVideoIcon: (UIImage *) VideoImage{
    UIGraphicsBeginImageContext(VideoImage.size);
    [VideoImage drawInRect:CGRectMake(0, 0, VideoImage.size.width, VideoImage.size.height)];
    UIImage *iconImage = [UIImage imageNamed:@"play-circle.png"];
    [iconImage drawInRect:CGRectMake((VideoImage.size.width-140)/2, (VideoImage.size.height-140)/2, 140, 140)];
    
    VideoImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // free the context
    UIGraphicsEndImageContext();
    return VideoImage;
    
}

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self){
        [self setup];
    }
    return self;
}
-(void)layoutSubviews{
    [super layoutSubviews];
    
    _titleLabel.frame = CGRectMake(5, self.bounds.size.height - 25, self.bounds.size.width - 10, 20);
    
    _imageView.layer.shadowOffset = CGSizeMake(8, 8);
    _imageView.layer.shadowColor = [UIColor redColor].CGColor;
    _imageView.layer.shadowOpacity = 1;
}


-(void)prepareForReuse{
    [super prepareForReuse];
    self.image = nil;
}

-(void)setHighlighted:(BOOL)highlighted{
    
    //  This avoids the animation runs every time the cell is reused
    if (self.isHighlighted != highlighted){
        _imageView.alpha = 0.0;
        [UIView animateWithDuration:0.3 animations:^{
            _imageView.alpha = 1.0;
        }];
    }
    
    [super setHighlighted:highlighted];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
