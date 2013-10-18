//
//  KMLFileChooser.m
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "KMLFileChooser.h"
#import "Options.h"

@implementation KMLFileChooser

@synthesize tableView, delegate;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // [self.navigationController isNavigationBarHidden:NO];
    
    if (!tableView) {
        CGRect reducedFrame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-30);
        tableView = [[UITableView alloc] initWithFrame:reducedFrame style:UITableViewStyleGrouped];
        tableView.dataSource = self;
        tableView.delegate = self;
    }
    
    [self.view addSubview:tableView];
    
    // stuff for delete
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Delete"
                                   style:UIBarButtonItemStyleBordered
                                   target:self
                                   action:@selector(toggleEdit:)];
    self.navigationItem.rightBarButtonItem = editButton;
    [editButton release];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (appDelegate.kmlManager.emailLoadMode) {
        self.navigationItem.title = @"Email file";
    }
    else {
        self.navigationItem.title = @"Load file";
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

-(void) dealloc {
    [tableView release];
    [super dealloc];
}

# pragma mark table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;  
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *filePathsArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentsDirectory  error:nil];
    
    // NSLog(@"files array %@", filePathsArray);
    
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
     
    // NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[filePathsArray objectAtIndex:0]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *filePathsArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentsDirectory  error:nil];
    
    NSString *str = [filePathsArray objectAtIndex:row];
    
    cell.textLabel.text = str;
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = [indexPath row];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *filePathsArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentsDirectory  error:nil];
    
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[filePathsArray objectAtIndex:row]];
    

    appDelegate.kmlManager.filePathToLoad = filePath;
    appDelegate.kmlManager.fileNameToLoad = [filePathsArray objectAtIndex:row];
    // NSLog(@"KMLFileChooser: %@", appDelegate.kmlManager.filePathToLoad);
    
    if (appDelegate.kmlManager.emailLoadMode == 1) {
        [self.navigationController popViewControllerAnimated:YES];
        [self KMLFileChoosen];
    }
    else {
        appDelegate.kmlManager.needToLoadFileOnMap = 1;
        // [self.navigationController popToRootViewControllerAnimated:YES];
        [self dismissOptionsView];
    }

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

#pragma mark Table View Delete
- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];
    
    /*
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *filePathsArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentsDirectory  error:nil];
    
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[filePathsArray objectAtIndex:row]];
     */
    
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

# pragma mark call delegate methods
-(void) KMLFileChoosen {
    // NSLog(@"KMLFileChooserViewDismissed");
    if ([delegate respondsToSelector:@selector(KMLFileChooserViewDismissed)]) {
        [delegate KMLFileChooserViewDismissed];
    }
}

@end
