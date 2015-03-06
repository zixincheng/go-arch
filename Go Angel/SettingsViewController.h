//
//  SettingsViewController.h
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import <UIKit/UIKit.h>
#if USES_IASK_STATIC_LIBRARY
  #import "InAppSettingsKit/IASKAppSettingsViewController.h"
#else
  #import "IASKAppSettingsViewController.h"
#endif


// settings view controller
// not much here because the InAppSettingsBundle does most of the work

@interface SettingsViewController : UIViewController <IASKSettingsDelegate> {
  IASKAppSettingsViewController *appSettingsViewController;
}

@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;

@end
