//
//  Options.h
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GeoIntMeasureAppDelegate.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "KMLWriter.h"
#import "KMLFileChooser.h"
#import "KMLFileSaveView.h"
#import "AboutApp.h"

@protocol OptionsDelegate;

@interface Options : UIViewController <MFMailComposeViewControllerDelegate, UIActionSheetDelegate, KMLFileChooserDelegate> {
    //NSArray *mapTypeChoices;
    GeoIntMeasureAppDelegate *appDelegate;
    id <OptionsDelegate> delegate;
}

@property (nonatomic, retain) IBOutlet UISegmentedControl *unitControl; 
@property (nonatomic, retain) IBOutlet UISegmentedControl *mapTypeControl; 
@property (nonatomic, retain) IBOutlet UILabel *message;
@property (nonatomic, retain) IBOutlet UISwitch *degreesSwitch; 
@property (nonatomic, retain) IBOutlet UISwitch *searchPinSwitch; 
@property (nonatomic, retain) IBOutlet UISwitch *elevationSwitch;
@property (nonatomic, retain) IBOutlet UISwitch *messageBarSwitch;
@property (nonatomic, retain) IBOutlet UISwitch *trackingSwitch; 
@property (nonatomic, retain) IBOutlet UISlider *trackingSlider;
@property (nonatomic, retain) IBOutlet UILabel *trackingMsg; 
@property (nonatomic, assign) id delegate;

-(void) changeUnitType:(UISegmentedControl *) segmentedControl;
-(void) changeMapType:(UISegmentedControl *) segmentedControl;
-(IBAction) changeDegreesOption:(id)sender;
-(void) setCoordsDegreesSwitch;
-(IBAction) changeSearchPinOption:(id)sender;
-(void) setSearchPinSwitch;
-(IBAction) changeElevationOption:(id)sender;
-(void) setElevationSwitch;
-(IBAction) changeMessageBarOption:(id)sender;
-(void) setMessageBarSwitch;
-(IBAction) changeTrackingOption:(id)sender;
-(void) setTrackingSwitch;
-(IBAction) changeTrackingSlider:(id)sender;

// kml stuff
-(IBAction) writeToKML; 
-(IBAction) loadKML:(id)sender;

// email stuff
-(IBAction) openEmailDisplay:(id)sender;
-(void) sendMail:(int) mode;  // mode 0 -- send kml, mode 1 -- send feedback
-(void)displayComposerSheet:(int) mode;

// action sheet
-(void) infoAction; 
- (IBAction)styleAction:(id)sender;

-(void) dismissOptionsPopoverControllerInDelegate;

@end

@protocol OptionsDelegate <NSObject>
-(void) dismissOptionsPopoverController;
@end