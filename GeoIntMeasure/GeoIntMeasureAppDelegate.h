//
//  GeoIntMeasureAppDelegate.h
//  GeoIntMeasure
//
//  Created by Paul Yang on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MeasModel.h"
#import "KMLManager.h"

@class GeoIntMeasureViewController;

@interface GeoIntMeasureAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet GeoIntMeasureViewController *viewController; 

@property (nonatomic, retain) MeasModel *measModel;

@property (nonatomic, retain) KMLManager *kmlManager;

-(BOOL) iPad;

@end
