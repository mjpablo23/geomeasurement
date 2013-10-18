//
//  KMLFileSaveView.h
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GeoIntMeasureAppDelegate.h"

@interface KMLFileSaveView : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource> {
    GeoIntMeasureAppDelegate *appDelegate;
}

@property (nonatomic, retain) IBOutlet UITextField *nameTextField;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

-(IBAction) doneButtonPressed:(id)sender;
-(void) saveFileName;
-(void) dismissOptionsView;

@end
