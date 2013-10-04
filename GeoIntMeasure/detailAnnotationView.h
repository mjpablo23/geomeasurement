//
//  detailAnnotationView.h
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GeoIntMeasureAppDelegate.h"
#import "CustomCell.h"

@interface detailAnnotationView : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    GeoIntMeasureAppDelegate *appDelegate;
    NSMutableArray *infoStrings;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;

@property (nonatomic, retain) MapPoint *mp;

-(UISegmentedControl *) upDownSegmentedControl;
-(void) doArrowAction:(UISegmentedControl *) segmentedControl;

@end
