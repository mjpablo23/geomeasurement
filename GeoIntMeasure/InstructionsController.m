//
//  InstructionsController.m
//  GeoIntMeasure
//
//  Created by Paul Yang on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InstructionsController.h"

@implementation InstructionsController

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
    
    recognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)] autorelease];
	[(UITapGestureRecognizer *)recognizer setNumberOfTouchesRequired:1];
	[self.view addGestureRecognizer:recognizer];
    recognizer.enabled = YES;
    
    UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"instructionsCrop.png"]];
    [self.view addSubview:image];
    [image release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [recognizer release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction) handleTapGesture:(UITapGestureRecognizer *) sender {
	NSLog(@"tap detected");
    
    // cancel the search bar
    [self dismissModalViewControllerAnimated:YES];
}

@end
