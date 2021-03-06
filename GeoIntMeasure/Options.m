//
//  Options.m
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Options.h"

@implementation Options

@synthesize unitControl, mapTypeControl, message, degreesSwitch, searchPinSwitch, elevationSwitch, trackingSwitch, trackingSlider, trackingMsg, messageBarSwitch, delegate; 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        appDelegate = [[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


#define MAP_STANDARD @"Standard"  // index 0
#define MAP_SATELLITE @"Satellite"  // index 1
#define MAP_HYBRID @"Hybrid"  // index 2

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // initialize unitControl and mapTypeControl

    [mapTypeControl setTitle:MAP_STANDARD forSegmentAtIndex:0];
    [mapTypeControl setTitle:MAP_SATELLITE forSegmentAtIndex:1];
    [mapTypeControl setTitle:MAP_HYBRID forSegmentAtIndex:2];

    // NSLog(@"measModel.mapTypeSelection: %d", appDelegate.measModel.mapTypeSelection);

    [mapTypeControl setSelectedSegmentIndex:appDelegate.measModel.mapTypeSelection];

    [mapTypeControl addTarget:self action:@selector(changeMapType:) forControlEvents:UIControlEventValueChanged];
    
    [mapTypeControl setSelectedSegmentIndex:appDelegate.measModel.mapTypeSelection];
    mapTypeControl.tintColor = [UIColor grayColor];
    
    [unitControl setTitle:UNIT_M forSegmentAtIndex:0];
    [unitControl setTitle:UNIT_KM forSegmentAtIndex:1];
    [unitControl setTitle:UNIT_MI forSegmentAtIndex:2];
    [unitControl setTitle:UNIT_YDS forSegmentAtIndex:3];
    [unitControl setTitle:UNIT_FT forSegmentAtIndex:4];
    [unitControl setTitle:UNIT_ACRES forSegmentAtIndex:5];
    [unitControl setTitle:@"ha" forSegmentAtIndex:6];
    
    unitControl.tintColor = [UIColor grayColor];
    
    [unitControl addTarget:self action:@selector(changeUnitType:) forControlEvents:UIControlEventValueChanged];
    
    [unitControl setSelectedSegmentIndex:appDelegate.measModel.unitSelection];
    
    self.navigationItem.title = @"Options";
    
    /*
    UIBarButtonItem *infoButton = [[[UIBarButtonItem alloc] initWithTitle:@"Info" style:UIBarButtonItemStyleBordered target:self action:@selector(infoAction)] autorelease]; 
    self.navigationItem.rightBarButtonItem = infoButton; 
     */
    UIButton* modalViewButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[modalViewButton addTarget:self action:@selector(infoAction) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *modalBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:modalViewButton];
	self.navigationItem.rightBarButtonItem = modalBarButtonItem;
	[modalBarButtonItem release];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // NSLog(@"Options::viewWillAppear -- appDelegate.kmlManager.emailLoadMode: %d", appDelegate.kmlManager.emailLoadMode);
    [self setSearchPinSwitch];
    [self setElevationSwitch];
    [self setTrackingSwitch];
    [self setCoordsDegreesSwitch];
    [self setMessageBarSwitch];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

# pragma mark options delegate

-(void) dismissOptionsPopoverControllerInDelegate {
    if (delegate && [delegate respondsToSelector:@selector(dismissOptionsPopoverController)]) {
        [delegate dismissOptionsPopoverController];
    }
}


# pragma mark KMLFileChooserDelegate methods
-(void) KMLFileChooserViewDismissed {
    // NSLog(@"Options::KMLFileChooserViewDismissed");
    
    [self sendMail:0];
    
    appDelegate.kmlManager.emailLoadMode = 0;
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

# pragma mark segmented control operations

-(void) changeMapType:(UISegmentedControl *) segmentedControl {
    if (segmentedControl.selectedSegmentIndex == 0) {
        //self.mapView.mapType = MKMapTypeStandard;
        NSLog(@"standard map type");
    }
    else if (segmentedControl.selectedSegmentIndex == 1) {
        //self.mapView.mapType = MKMapTypeHybrid;
        NSLog(@"satellite map type");
    }
    else if (segmentedControl.selectedSegmentIndex == 2) {
        //self.mapView.mapType = MKMapTypeSatellite;
        NSLog(@"hybrid map type");
    }
    appDelegate.measModel.mapTypeSelection = segmentedControl.selectedSegmentIndex;
}

-(void) changeUnitType:(UISegmentedControl *) segmentedControl {
    //NSLog(@"unit selected index: %d", segmentedControl.selectedSegmentIndex);
    appDelegate.measModel.unitSelection = segmentedControl.selectedSegmentIndex;
}

# pragma mark search pin switch
-(IBAction) changeSearchPinOption:(id)sender {
    NSLog(@"change search pin called");
    [[NSUserDefaults standardUserDefaults] setBool:searchPinSwitch.on forKey:@"dropSearchPin"];
}

-(void) setSearchPinSwitch {
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:@"dropSearchPin"];
    searchPinSwitch.on = val;
}

# pragma mark degrees switch
-(IBAction) changeDegreesOption:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:degreesSwitch.on forKey:@"coordsDegrees"];
}

-(void) setCoordsDegreesSwitch {
    BOOL coordsInDegrees = [[NSUserDefaults standardUserDefaults] boolForKey:@"coordsDegrees"];
    degreesSwitch.on = coordsInDegrees;
}

# pragma mark elevation switch
-(IBAction) changeElevationOption:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:elevationSwitch.on forKey:@"getElevation"];
}

-(void) setElevationSwitch {
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:@"getElevation"];
    elevationSwitch.on = val;
}

# pragma mark message bar switch

-(IBAction) changeMessageBarOption:(id)sender {
    // NSLog(@"change message bar to: %d", messageBarSwitch.on);
    [[NSUserDefaults standardUserDefaults] setBool:messageBarSwitch.on forKey:@"showMessageBar"];
}

-(void) setMessageBarSwitch {
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:@"showMessageBar"];
    messageBarSwitch.on = val;
}

# pragma mark tracking switch
-(IBAction) changeTrackingOption:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:trackingSwitch.on forKey:@"trackLocation"];
    trackingSlider.hidden = !trackingSwitch.on;
    trackingMsg.hidden = !trackingSwitch.on;
}

-(void) setTrackingSwitch {
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:@"trackLocation"];
    trackingSwitch.on = val;
    trackingSlider.hidden = !trackingSwitch.on;
    trackingSlider.value = appDelegate.measModel.trackingSecs;
    trackingMsg.hidden = !trackingSwitch.on;
    trackingMsg.text = [NSString stringWithFormat:@"Pin drop time interval: %d secs", appDelegate.measModel.trackingSecs];
}

# pragma mark tracking slider
-(IBAction) changeTrackingSlider:(id)sender {
    int secs = (int) trackingSlider.value; 
    // NSLog(@"trackingSlider value: %d", secs);
    if (secs != appDelegate.measModel.trackingSecs) {
        appDelegate.measModel.trackingSecs = secs;        
        trackingMsg.text = [NSString stringWithFormat:@"Track time interval: %d secs", secs];
    }
}

# pragma mark write to kml
-(IBAction) loadKML:(id)sender {
    appDelegate.kmlManager.emailLoadMode = 0;
    KMLFileChooser *fileChooser = [[KMLFileChooser alloc] init];
    [self.navigationController pushViewController:fileChooser animated:YES];
    [fileChooser release];
}

-(IBAction) writeToKML {
    // NSLog(@"Options::writeToKML");
    KMLFileSaveView *kmlSaveView = [[KMLFileSaveView alloc] initWithNibName:@"KMLFileSaveView" bundle:nil];
    [self.navigationController pushViewController:kmlSaveView animated:YES];
    [kmlSaveView release];
}

- (NSString *)dataFilePath { 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectory = [paths objectAtIndex:0]; 
    return [documentsDirectory stringByAppendingPathComponent:@"testWrite.kml"];
}

# pragma mark email controller

-(IBAction) openEmailDisplay:(id)sender {
    appDelegate.kmlManager.emailLoadMode = 1;
    
    KMLFileChooser *fileChooser = [[KMLFileChooser alloc] init];
    fileChooser.delegate = self;
    //[self presentModalViewController:fileChooser animated:YES];
    
    [self.navigationController pushViewController:fileChooser animated:YES];
    [fileChooser release];
    
    // call this in viewWillAppear instead
    // [self sendMail:0];
}

-(void) sendMail:(int) mode {
    // NSLog(@"calling sendMail:%d", mode);
    
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    if (mailClass != nil && [MFMailComposeViewController canSendMail]) {
        [self displayComposerSheet:mode];
    }
    else {
        message.text = @"can't send mail";
    }
}

// Displays an email composition interface inside the application. Populates all the Mail fields. 
-(void)displayComposerSheet:(int) mode
{
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
    // mode 0 -- send kml, mode 1 -- send feedback
    if (mode == 0) {
        [picker setSubject:@"KML File of route"];
	}
    else if (mode == 1) {
        [picker setSubject:@"Feedback for GeoInt Application"];
    }
    
	// Set up recipients    
    if (mode == 1) {
        NSArray *toRecipients = [NSArray arrayWithObject:@"eric.narges@lmco.com"]; 
        [picker setToRecipients:toRecipients];
    }
	
	// Attach an kml file to the email
    
    if (mode == 0) {
        // NSString *path = [self dataFilePath];
        NSString *path = appDelegate.kmlManager.filePathToLoad;
        NSData *myData = [NSData dataWithContentsOfFile:path];
        //[picker addAttachmentData:myData mimeType:@"text/plain" fileName:@"testWrite.kml"];
        [picker addAttachmentData:myData mimeType:@"application/xml" fileName:appDelegate.kmlManager.fileNameToLoad];    
    } 
     
    
	// Fill out the email body text
    
	NSString *emailBody = @"";
    
    if (mode == 0) {
        emailBody = @"This is my route! (kml file made with with GEOINT iOS application)";
    }
    else if (mode == 1) {
        
        NSString *deviceInfo = [NSString stringWithFormat:@"Current iOS Info (to help with fixes): %@ %@ running on %@\n\n", [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion, [UIDevice currentDevice].model];

        emailBody = @"My feedback on this app: \n\n\n\n";
        emailBody = [emailBody stringByAppendingString:deviceInfo];
    }
    
	[picker setMessageBody:emailBody isHTML:NO];
	
    // NSLog(@"calling displayComposerSheet::presentModalViewController");
	[self presentViewController:picker animated:YES completion:nil];
    [picker release];
}


// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	// message.hidden = NO;
	// Notifies users about errors associated with the interface
	switch (result)
	{
		case MFMailComposeResultCancelled:
			message.text = @"Result: canceled";
			break;
		case MFMailComposeResultSaved:
			message.text = @"Result: saved";
			break;
		case MFMailComposeResultSent:
			message.text = @"Result: sent";
			break;
		case MFMailComposeResultFailed:
			message.text = @"Result: failed";
			break;
		default:
			message.text = @"Result: not sent";
			break;
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark action sheet

-(void) infoAction {
    NSLog(@"info button pressed");
    [self styleAction:nil];
}

- (IBAction)styleAction:(id)sender
{
	UIActionSheet *styleAlert = [[UIActionSheet alloc] initWithTitle:@"App Info:"
                                                            delegate:self cancelButtonTitle:@"Cancel"
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:	@"App info",
                                 @"Email feedback",
                                 nil,
                                 nil];
	
	// use the same style as the nav bar
	// styleAlert.actionSheetStyle = self.navigationController.navigationBar.barStyle;
	
	[styleAlert showInView:self.view];
	[styleAlert release];
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Change the navigation bar style, also make the status bar match with it
	switch (buttonIndex)
	{
		case 0:
		{
            // present modal view controller
            AboutApp *view = [[AboutApp alloc] initWithNibName:@"AboutApp" bundle:nil];
            [self.navigationController pushViewController:view animated:YES];
            [view release];
			break;
		}
		case 1:
		{
            [self sendMail:1];
			break;
		}
		case 2:
		{
			// present modal view controller
			break;
		}
	}
}


@end
