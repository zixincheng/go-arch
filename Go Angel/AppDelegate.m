//
//  AppDelegate.m
//  Go Angel
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.account = [[AccountDataWrapper alloc] init];
  [self.account readSettings];
  NSLog(@"reading settings");
  
  // initialize the image cache
  self.mediaLoader = [[MediaLoader alloc] init];
  
  // here we check if the device name has been set before
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *deviceName = [defaults valueForKey:@"deviceName"];
  if (deviceName == nil) {
    [defaults setObject:[[UIDevice currentDevice] name] forKey:@"deviceName"];
  }
    
   UIUserNotificationSettings *settings =
     [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert |
      UIUserNotificationTypeBadge |
      UIUserNotificationTypeSound
                                      categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];

  
  return YES;
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    
    NSString *deviceTokenString = [NSString stringWithFormat:@"%@",deviceToken];
    [[NSUserDefaults standardUserDefaults] setObject:deviceTokenString forKey:@"apnId"];
    NSLog(@"device token : %@",deviceTokenString);
}

-(void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    NSLog(@"%@",userInfo);
    NSString *storageInfo = [userInfo objectForKey:@"data"];
    NSDictionary *note = [userInfo objectForKey:@"aps"];
    [[NSUserDefaults standardUserDefaults] setObject:storageInfo forKey:@"storageInfo"];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Notification" message:
                          [note objectForKey:@"alert"] delegate:nil cancelButtonTitle:
                          @"OK" otherButtonTitles:nil, nil];
    [alert show];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"pushNotification" object:nil userInfo:userInfo];
}


- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
  NSLog(@"app went into background, saving completion handler");
  
  self.backgroundTransferCompletionHandler = completionHandler;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // Saves all the application's settings to a plist (XML) file
  [self.account saveSettings];
}

@end
