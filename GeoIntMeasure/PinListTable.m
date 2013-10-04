//
//  PinListTable.m
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PinListTable.h"

@implementation PinListTable

@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    appDelegate = [[UIApplication sharedApplication] delegate];
    
    [self.navigationController setToolbarHidden:YES];
    
    modeControl = [self mappingModeSegmentedControl];    
    self.navigationItem.titleView = modeControl;

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) 
        [modeControl setSelectedSegmentIndex:0];
    else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID)
        [modeControl setSelectedSegmentIndex:1];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

# pragma mark segmented control for mapping mode

-(UISegmentedControl *) mappingModeSegmentedControl {
    NSArray *mappingOptions = [[NSArray arrayWithObjects:@"Measure", @"Route", nil] retain];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:mappingOptions]; 
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    segmentedControl.tintColor = [UIColor grayColor];
    [segmentedControl addTarget:self action:@selector(switchMappingMode:) forControlEvents:UIControlEventValueChanged];
    return [segmentedControl autorelease];
}

-(void) switchMappingMode:(UISegmentedControl *) segmentedControl {
    NSLog(@"switchMappingMode selected index: %d", segmentedControl.selectedSegmentIndex);
    
    int doUpdate = 0;
    if(segmentedControl.selectedSegmentIndex == 0 && appDelegate.measModel.mappingMode != MAP_MODE_MEAS) {
        doUpdate = 1;
    }
    else if (segmentedControl.selectedSegmentIndex == 1 && appDelegate.measModel.mappingMode != MAP_MODE_HYBRID) {
        doUpdate = 1;
    }
    
    if (doUpdate == 1 && [delegate respondsToSelector:@selector(updateMappingMode)]) {
        [delegate updateMappingMode];
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) 
        return [appDelegate.measModel.coordinatePoints count];
    else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID)
        return [appDelegate.measModel.hybridPoints count];
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
     */
    static NSString *CellIdentifier = @"Cell";
    CustomCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[CustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    int row = [indexPath row];
    
    MapPoint *mp = nil;
    if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) 
        mp = [appDelegate.measModel.coordinatePoints objectAtIndex:row];
    else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID)
        mp = [appDelegate.measModel.hybridPoints objectAtIndex:row];
    
    // Configure the cell...
    // cell.textLabel.text = mp.title;
    cell.primaryLabel.text = mp.title;
    cell.secondaryLabel.text = mp.subtitle;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    
    int row = [indexPath row];
    MapPoint *mp = nil;
    if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) 
        mp = [appDelegate.measModel.coordinatePoints objectAtIndex:row];
    else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID)
        mp = [appDelegate.measModel.hybridPoints objectAtIndex:row];
    
    detailAnnotationView *detailViewController = [[detailAnnotationView alloc] init];
    detailViewController.mp = mp;
    // ...
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
    
}

@end
