//
//  AppDelegate.m
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "AppDelegate.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "SegmentedViewController.h"
#import <DropboxSDK/DropboxSDK.h>

@interface AppDelegate() <DBSessionDelegate, DBNetworkRequestDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [Fabric with:@[CrashlyticsKit]];
  self.account = [[AccountDataWrapper alloc] init];
  [self.account readSettings];
  self.dataWrapper = [[CoreDataWrapper alloc]init];
  self.uploadTask = [[UploadPhotosTask alloc]initWithWrapper:self.dataWrapper];
  self.coinsorter = [[Coinsorter alloc] initWithWrapper:self.dataWrapper];
  self.netWorkCheck = [[NetWorkCheck alloc] initWithCoinsorter:self.coinsorter];
  NSLog(@"reading settings");
  
    NSString* appKey = @"iy6waa9tdrvejwh";
    NSString* appSecret = @"axr8qdq0vezfqes";
    NSString *root = kDBRootDropbox;
    
    DBSession* session =
    [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
    session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
    [DBSession setSharedSession:session];
    
  // initialize the image cache
  self.mediaLoader = [[MediaLoader alloc] init];
  
  // here we check if the device name has been set before
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *deviceName = [defaults valueForKey:@"deviceName"];
  if (deviceName == nil) {
    [defaults setObject:[[UIDevice currentDevice] name] forKey:@"deviceName"];
  }
  
  // check if the 'tag photo with location' setting has been set before
  // if it hasn't, set it to true
  BOOL onLocation = [defaults boolForKey:CURR_LOC_ON];
  if (!onLocation) {
    [defaults setBool:NO forKey:CURR_LOC_ON];
  }
  
  BOOL uploadGPS = [defaults boolForKey:GPS_META];
  if (!uploadGPS) {
    [defaults setBool:YES forKey:GPS_META];
  }
    
   UIUserNotificationSettings *settings =
     [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert |
      UIUserNotificationTypeBadge |
      UIUserNotificationTypeSound
                                      categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];

    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
  //self.defaultAlbum = [[createDefaultAlbum alloc] init];
  //[self.defaultAlbum setDefaultAlbum];

  return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");

        }
        return YES;
    }
    
    return NO;
}

-(void) application:(UIApplication *)application performFetchWithCompletionHandler:
(void (^)(UIBackgroundFetchResult))completionHandler {
       NSLog(@"Background fetch started...");
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    SegmentedViewController * vc = [storyboard instantiateViewControllerWithIdentifier:@"SegmentedViewController"];
    [vc fetchNewDataWithCompletionHandler:^(UIBackgroundFetchResult result) {
        completionHandler(result);
    }];
    
    NSLog(@"Background fetch completed...");
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
    NSLog(@"enter backgorund ");

    
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


#pragma mark -
#pragma mark DBSessionDelegate methods

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
    UIAlertView *view = [[UIAlertView alloc]
       initWithTitle:@"Dropbox Session Ended" message:@"Do you want to relink?" delegate:self
                           cancelButtonTitle:@"Cancel" otherButtonTitles:@"Relink", nil];
    [view show];
}


#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
    if (index != alertView.cancelButtonIndex) {
      //  [[DBSession sharedSession] linkUserId:relinkUserId fromController:rootViewController];
    }
    relinkUserId = nil;
}


#pragma mark -
#pragma mark DBNetworkRequestDelegate methods

static int outstandingRequests;

- (void)networkRequestStarted {
    outstandingRequests++;
    if (outstandingRequests == 1) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}

- (void)networkRequestStopped {
    outstandingRequests--;
    if (outstandingRequests == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}

@end
