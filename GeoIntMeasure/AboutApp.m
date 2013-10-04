//
//  AboutApp.m
//  GeoIntMeasure
//
//  Created by Paul Yang on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AboutApp.h"

@implementation AboutApp

@synthesize textView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSString *msg = [NSString stringWithString:@"The instruction screen for this app can be viewed by tapping the info button on the bottom right corner of the main map screen. \n\nThis application was created for the GEOINT 2011 Symposium, which takes place in San Antonio, TX. \n\nThe application was developed by: \nJason Loveland (Program Manager) and Paul Yang (Developer). \n\n"];
    
    NSString *icons = [NSString stringWithString:@"Application art and main icons by Zane Parker.  Other icons by Glyphish, (glyphish.com), and app-bits. \n\nNote: Calculations for polygons that contain self-intersecting areas (boundaries of polygon cross themselves) are not valid."];
    
    // NSString *msg2; 
 
    msg = [msg stringByAppendingString:icons];
    
    textView.text = msg;
    textView.backgroundColor = [UIColor clearColor];
    self.navigationItem.title = @"About";
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.view setBackgroundColor:[UIColor whiteColor]];
    }
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

@end
