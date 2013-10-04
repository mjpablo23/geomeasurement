//
//  PinListTable.h
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GeoIntMeasureAppDelegate.h"
#import "detailAnnotationView.h"

@protocol PinListTableDelegate;

@interface PinListTable : UITableViewController {
    GeoIntMeasureAppDelegate *appDelegate;
    id <PinListTableDelegate> delegate;
    UISegmentedControl *modeControl;
}

@property (nonatomic, assign) id delegate;

-(UISegmentedControl *) mappingModeSegmentedControl;

@end

@protocol PinListTableDelegate <NSObject>

-(void) updateMappingMode;
-(void) switchMappingMode:(UISegmentedControl *) segmentedControl;

@end