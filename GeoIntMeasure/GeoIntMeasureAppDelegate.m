//
//  GeoIntMeasureAppDelegate.m
//  GeoIntMeasure
//
//  Created by Paul Yang on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GeoIntMeasureAppDelegate.h"

#import "GeoIntMeasureViewController.h"

@implementation GeoIntMeasureAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize measModel, kmlManager; 

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
     
    measModel = [[MeasModel alloc] init];
    kmlManager = [[KMLManager alloc] init];
    
    GeoIntMeasureViewController *geoIntView = [[GeoIntMeasureViewController alloc] init];
    
    UINavigationController *navcon = [[UINavigationController alloc] init];
    [navcon pushViewController:geoIntView animated:NO];
    [self.window addSubview:navcon.view];
    [self.window makeKeyAndVisible];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"coordsDegrees"] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"coordsDegrees"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"dropSearchPin"] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"dropSearchPin"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"trackLocation"] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"trackLocation"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"getElevation"] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"getElevation"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"showMessageBar"] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showMessageBar"];
    }
    
    
    // [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"showLicense"];
    // take out above line for deployment
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"showLicense"] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showLicense"];
    }
    
    sleep(1);
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

-(BOOL) iPad {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad); 
}

@end
