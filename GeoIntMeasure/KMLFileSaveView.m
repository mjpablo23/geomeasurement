//
//  KMLFileSaveView.m
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "KMLFileSaveView.h"
#import "Options.h"

@implementation KMLFileSaveView

@synthesize nameTextField, tableView;

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
    appDelegate = [[UIApplication sharedApplication] delegate];
    
    nameTextField.delegate = self;
    
    [self.navigationItem setTitle:@"Enter a filename"];
    
    // stuff for delete
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Delete"
                                   style:UIBarButtonItemStyleBordered
                                   target:self
                                   action:@selector(toggleEdit:)];
    self.navigationItem.rightBarButtonItem = editButton;
    [editButton release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void) dealloc {
    [tableView release];
    [nameTextField release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction) doneButtonPressed:(id)sender {
    
}

-(void) saveFileName {
    
    NSString *str = nameTextField.text;
    /*
    NSCharacterSet *alphaSet = [NSCharacterSet alphanumericCharacterSet];
    NSCharacterSet *whiteSet = [NSCharacterSet whitespaceCharacterSet];
    // NSCharacterSet *symbolSet = [NSCharacterSet symbolCharacterSet];
    NSCharacterSet *punctuationSet = [NSCharacterSet punctuationCharacterSet];
    NSString *strWithoutAlphaNum = [str stringByTrimmingCharactersInSet:alphaSet];
    NSLog(@"strWithoutAlphaNum: %@", )
    NSString *strWithoutWhitespace = [strWithoutAlphaNum stringByTrimmingCharactersInSet:whiteSet];
    // NSString *strWithoutSymbol = [strWithoutWhitespace stringByTrimmingCharactersInSet:symbolSet];
    NSString *strWithoutPunc = [strWithoutWhitespace stringByTrimmingCharactersInSet:punctuationSet];
    BOOL valid = [strWithoutPunc isEqualToString:@""];
     */
    
    BOOL valid = ([str rangeOfString:@"/"].location == NSNotFound);

    if ([str length] < 1 || valid == NO) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Filename error" message:@"name is either too short or contains invalid characters" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    appDelegate.kmlManager.fileNameToSave = nameTextField.text;
    appDelegate.kmlManager.needToSaveFile = 1;
    NSLog(@"fileName: %@", appDelegate.kmlManager.fileNameToSave);
}

# pragma mark textFieldDelegate

//- (void)textFieldDidEndEditing:(UITextField *)textField {    
//}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self saveFileName];
    
    if (appDelegate.kmlManager.needToSaveFile == 1) {
        [self dismissOptionsView];
    }
    return NO;
}

-(void) dismissOptionsView {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // dismiss the popoverController by accessing the optionsViewController and calling the dismiss
        id optionsViewController = [[self.navigationController viewControllers] objectAtIndex:0];
        [self.navigationController popToRootViewControllerAnimated:NO];
        if ([optionsViewController isKindOfClass:[Options class]]) {
            NSLog(@"top view controller is options class");
            [optionsViewController dismissOptionsPopoverControllerInDelegate];
        }
        else {
            NSLog(@"top view controller not options class");
        }
    }
    else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

# pragma mark table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;  
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    /*
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *filePathsArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentsDirectory  error:nil];
    
    NSLog(@"files array %@", filePathsArray);
    */
    NSArray *filePathsArray = [appDelegate.kmlManager filePathsArray];
	NSUInteger num = [filePathsArray count];
	return num;
}

- (UITableViewCell *)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *SimpleTableIdentifier = @"SimpleTableIdentifier";
	UITableViewCell *cell = [tblView dequeueReusableCellWithIdentifier:
							 SimpleTableIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc]
				 initWithStyle:UITableViewCellStyleDefault
				 reuseIdentifier:SimpleTableIdentifier] autorelease];
	}
    
    NSUInteger row = [indexPath row];
    
    NSArray *filePathsArray = [appDelegate.kmlManager filePathsArray];
    NSString *str = [filePathsArray objectAtIndex:row];
    
    cell.textLabel.text = str;
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];
    
    NSArray *filePathsArray = [appDelegate.kmlManager filePathsArray];
    
    NSString *fileNameWithExtension = [filePathsArray objectAtIndex:row];
    NSArray *fileNameArray = [fileNameWithExtension componentsSeparatedByString:@"."];
    NSString *name = @"";
    for (int i=0; i<([fileNameArray count] - 1); i++) {
        name = [name stringByAppendingString:[fileNameArray objectAtIndex:i]];
    }
    
    appDelegate.kmlManager.fileNameToSave = name;
    appDelegate.kmlManager.needToSaveFile = 1;
    
    // [self.navigationController popToRootViewControllerAnimated:YES];
    [self dismissOptionsView];
}

#pragma mark Table View Delete
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    
    NSString *filePath = [appDelegate.kmlManager fileWithPathInDocuments:row];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:filePath error:NULL];    
    
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}


-(IBAction)toggleEdit:(id)sender {
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    
    if (self.tableView.editing)
        [self.navigationItem.rightBarButtonItem setTitle:@"Done"];
    else
        [self.navigationItem.rightBarButtonItem setTitle:@"Delete"];
}

@end
