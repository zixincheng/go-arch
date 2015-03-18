//
//  SegmentedViewController.h
//  
//
//  Created by zcheng on 2015-03-18.
//
//

#import <UIKit/UIKit.h>
#import "MainLocationViewController.h"

@interface SegmentedViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *typeSegmentedControl;

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (strong, nonatomic) UIViewController *currentViewController;

@end
