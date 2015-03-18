//
//  SegmentedViewController.m
//  
//
//  Created by zcheng on 2015-03-18.
//
//

#import "SegmentedViewController.h"

@interface SegmentedViewController ()

- (UIViewController *)viewControllerForSegmentIndex:(NSInteger)index;

@end

@implementation SegmentedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIViewController *vc = [self viewControllerForSegmentIndex:self.typeSegmentedControl.selectedSegmentIndex];
    [self addChildViewController:vc];
    vc.view.frame = self.containerView.bounds;
    [self.view addSubview:vc.view];
    self.currentViewController = vc;
                                                                
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
}


- (IBAction)segmentChanged:(UISegmentedControl *)sender {
    UIViewController *vc = [self viewControllerForSegmentIndex:sender.selectedSegmentIndex];
    [self addChildViewController:vc];
    [self transitionFromViewController:self.currentViewController toViewController:vc duration:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.currentViewController.view removeFromSuperview];
        vc.view.frame = self.containerView.bounds;

        [self.view addSubview:vc.view];
    } completion:^(BOOL finished) {
        [vc didMoveToParentViewController:self];
        [self.currentViewController removeFromParentViewController];
        self.currentViewController = vc;
    }];
    self.navigationItem.title = vc.title;
}

- (UIViewController *)viewControllerForSegmentIndex:(NSInteger)index {
    UIViewController *vc;
    switch (index) {
        case 0:
            vc = [self.storyboard instantiateViewControllerWithIdentifier:@"mainLocationViewController"];
            break;
        case 1:
            vc = [self.storyboard instantiateViewControllerWithIdentifier:@"MapView"];
            break;
    }
    return vc;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
