//
//  KMLFileChooser.h
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GeoIntMeasureAppDelegate.h"

@protocol KMLFileChooserDelegate;

@interface KMLFileChooser : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    GeoIntMeasureAppDelegate *appDelegate;
    id <KMLFileChooserDelegate> delegate;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) id delegate;

-(void) KMLFileChoosen;
-(void) dismissOptionsView;

@end

@protocol KMLFileChooserDelegate<NSObject>
-(void) KMLFileChooserViewDismissed; 
@end