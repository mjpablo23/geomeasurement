//
//  detailAnnotationView.m
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "detailAnnotationView.h"

@implementation detailAnnotationView

@synthesize tableView, mp;

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
    // NSLog(@"viewDidLoad called in detailAnnotationView");
    // Do any additional setup after loading the view from its nib.
    
    if (!tableView) {
        CGRect reducedFrame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-30);
        
        tableView = [[UITableView alloc] initWithFrame:reducedFrame style:UITableViewStyleGrouped];
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.allowsSelection = NO;
    }
    
    [self.view addSubview:tableView];
    
    // self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self upDownSegmentedControl]];
     
    // tableView.allowsSelection = NO;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(UISegmentedControl *) upDownSegmentedControl {
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:nil];
    UIImage *up = [appDelegate.measModel imageWithImage:[UIImage imageNamed:@"arrowup.png"] scaledToSize:CGSizeMake(20, 20)];
    UIImage *down = [appDelegate.measModel imageWithImage:[UIImage imageNamed:@"arrowdown.png"] scaledToSize:CGSizeMake(20, 20)];
    [segmentedControl insertSegmentWithImage:down atIndex:0 animated:NO];
    [segmentedControl insertSegmentWithImage:up atIndex:1 animated:NO];
    [segmentedControl addTarget:self action:@selector(doArrowAction:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.momentary = YES; 
    return [segmentedControl autorelease];
}

-(void) doArrowAction:(UISegmentedControl *) segmentedControl {
    // NSLog(@"pin action selected index: %d", segmentedControl.selectedSegmentIndex);
    // NSArray *points = [appDelegate.measModel getPointsForMode];
    NSArray *points = nil;
    NSUInteger indMeas = [appDelegate.measModel.coordinatePoints indexOfObject:mp];
    if (indMeas != NSNotFound) 
        points = appDelegate.measModel.coordinatePoints;
    else
        points = appDelegate.measModel.hybridPoints;
    
    NSUInteger annotInd = [points indexOfObject:mp];
    int newAnnotFound = 0;
    
    // NSLog(@"current annotInd: %d", annotInd);
    
    if (segmentedControl.selectedSegmentIndex == 0) {
        // go down one (down in tableview)
        if (annotInd < ([points count]-1)) {
            newAnnotFound = 1;
            // NSLog(@"going to annotInd: %d, numPoints: %d", annotInd+1, [points count]);
            mp = [points objectAtIndex:annotInd+1];
        }
    }
    else if (segmentedControl.selectedSegmentIndex == 1) {
        // go up one (up in tableview)
        if (annotInd > 0) {
            newAnnotFound = 1;
            // NSLog(@"going to annotInd: %d, numPoints: %d", annotInd-1, [points count]);
            mp = [points objectAtIndex:annotInd-1];
        }
    }
    
    if (newAnnotFound == 1) {
        [self viewWillAppear:YES];
        [tableView reloadData];
    }
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.title = @"Point Details";
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController setToolbarHidden:YES];
    
    NSString *title = @"Point title";
    NSString *titleStr = mp.title;
    
    NSString *subtitle = @"Point subtitle";
    NSString *subtitleStr = mp.subtitle;

    NSString *latLabel = @"Latitude";
    NSString *latStr = [NSString stringWithFormat:@"%.7f", mp.coordinate.latitude];
    NSString *latLabel2 = @"Latitude in deg° min' sec\"";
    NSString *latDegStr = [appDelegate.measModel convertToDegrees:mp.coordinate.latitude];
    
    NSString *lonLabel = @"Longitude";
    NSString *lonStr = [NSString stringWithFormat:@"%.7f", mp.coordinate.longitude];
    NSString *lonLabel2 = @"Longitude in deg° min' sec\"";
    NSString *lonDegStr = [appDelegate.measModel convertToDegrees:mp.coordinate.longitude];
    
    NSString *deltaLabel = @"Distance from previous point";
    NSString *deltaStr = [appDelegate.measModel getConvertedDistanceStr:mp.deltaDistanceMeters];
    NSString *totalLabel = @"Total distance to point";
    NSString *totalStr = [appDelegate.measModel getConvertedDistanceStr:mp.totalDistanceMeters];    
    
    int invalidElev = 0;
    NSString *urlString = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/elevation/json?locations=%.8f,%.8f&sensor=true", mp.coordinate.latitude, mp.coordinate.longitude];
    BOOL getElevationVal = [[NSUserDefaults standardUserDefaults] boolForKey:@"getElevation"];
    NSString *elevationString = nil;
    if (getElevationVal == YES) {
        elevationString = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString] encoding:NSUTF8StringEncoding error:nil];
    }
    // NSLog(@"elevation string:\n %@", elevationString);
    double el = 0;
    if (elevationString == nil) {
        invalidElev = 1;
    }
    else {
        NSArray *listItems = [elevationString componentsSeparatedByString:@"\n"];
        int j=0; 
        NSString *statusLine = nil; 
        for (NSString *str in listItems) {
            // NSLog(@"str %d: %@", j, str);
            j++;
            if ([str rangeOfString:@"status"].location != NSNotFound) {
                // NSLog(@"--> status line %d: %@", j, str);
                statusLine = str;
            }
        }
        
        NSString *status = [[statusLine componentsSeparatedByString:@":"] objectAtIndex:1];
        int badVal = ([status rangeOfString:@"OK"].location == NSNotFound);
        // NSLog(@"statusStr: %@, isBad: %d", status, badVal);
        invalidElev = badVal;
        if (invalidElev == 0) {
            NSString *elevLine = [listItems objectAtIndex:3];
            NSArray *elevLineItems = [elevLine componentsSeparatedByString:@":"];
            NSString *elValStr = [elevLineItems objectAtIndex:1];
            // NSLog(@"elevation str found:%@", elValStr);
            el = [elValStr doubleValue];
        }
    }
    NSString *elevationLabel = @"Elevation";
    NSString *elevationStr;
    if (invalidElev == 1) {
        elevationStr = @"not available";
    }
    else {
        elevationStr = [appDelegate.measModel getConvertedDistanceStr:el]; 
    }
    
    infoStrings = [[NSMutableArray alloc] initWithObjects:title, titleStr, subtitle, subtitleStr, latLabel, latStr, latLabel2, latDegStr, lonLabel, lonStr, lonLabel2, lonDegStr, deltaLabel, deltaStr, totalLabel, totalStr, elevationLabel, elevationStr, nil];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:[self upDownSegmentedControl]] autorelease];
    
    int numSecs = 0;
    NSLog(@"sleep %d secs", numSecs);
    sleep(numSecs);
    // NSLog(@"done sleeping");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void) dealloc {
    [tableView release];
    [infoStrings release];
    //[self.navigationItem.rightBarButtonItem release];
    [super dealloc];
}

# pragma mark table view methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;  
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [infoStrings count] / 2;
}

- (UITableViewCell *)tableView:(UITableView *)tblView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
              
    static NSString *CellIdentifier = @"Cell";
    CustomCell *cell = [tblView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[CustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSUInteger row = [indexPath row];
    
    NSString *str = [infoStrings objectAtIndex:(2*row)];
    NSString *sub = [infoStrings objectAtIndex:(2*row+1)];
    
    //cell.textLabel.text = str;
    
    cell.primaryLabel.text = str;
    cell.secondaryLabel.text = sub;
    
    // NSLog(@"returning cell %d", row);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // NSUInteger row = [indexPath row];
}
    
@end
