//
//  AppDelegate.m
//  SimpleSample-videochat-ios
//
//  Created by QuickBlox team on 1/02/13.
//  Copyright (c) 2013 QuickBlox. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "SplashViewController.h"

@implementation AppDelegate
@synthesize window = _window;
@synthesize testOpponents;
@synthesize currentUser;

- (void)dealloc
{
    [_window release];
    [testOpponents release];	
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //
    // This is test oppoents. This is 2 users' logins/passwords & ids
    //
    self.testOpponents = @[@"DevVideoChatUser33", @195516,
                      @"DevVideoChatUser44", @195517];
    
    
    //
    // Set QuickBlox credentials. Register at admin.quickblox.com, create a new app
    // and copy credentials here to have your own backend instance enabled.
    [QBSettings setApplicationID:92];
    [QBSettings setAuthorizationKey:@"wJHdOcQSxXQGWx5"];
    [QBSettings setAuthorizationSecret:@"BTFsj7Rtt27DAmT"];
    
    NSMutableDictionary *videoChatConfiguration = [[QBSettings videoChatConfiguration] mutableCopy];
    [videoChatConfiguration setObject:@20 forKey:kQBVideoChatCallTimeout];
    [videoChatConfiguration setObject:AVCaptureSessionPresetMedium forKey:kQBVideoChatFrameQualityPreset];
    [videoChatConfiguration setObject:@15 forKey:kQBVideoChatVideoFramesPerSecond];
    [videoChatConfiguration setObject:@1 forKey:kQBVideoChatWriteQueueMaxOperationsThreshold];
    [videoChatConfiguration setObject:@0 forKey:kQBVideoChatP2PTimeout];
    [QBSettings setVideoChatConfiguration:videoChatConfiguration];


    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];
    
    // Show Splash screen
    //
    SplashViewController *splashViewController = [[SplashViewController alloc] init];
    [self.window setRootViewController:splashViewController];
    [splashViewController release];
    
    [self.window makeKeyAndVisible];
    
    return YES;
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
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
