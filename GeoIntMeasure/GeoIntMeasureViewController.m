//
//  GeoIntMeasureViewController.m
//  GeoIntMeasure
//
//  Created by Paul Yang on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GeoIntMeasureViewController.h"

#define REGION_DIST 25000

/*
 @implementation UINavigationBar(CustomImage)
 - (void)drawRect:(CGRect)rect {
 UIImage *image = [UIImage imageNamed: @"TopNav.png"];
 [image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
 }
 @end
 */

@implementation GeoIntMeasureViewController

@synthesize mapView, messageView, messageLabel, toggleButton, messageViewOnScreen, searchBarView, searchBar, activityInd, mappingModeButton, mappingModeControl, currentLocationButton, optionsMenuButton, listButton, flexibleSpace, measSegmentedControl, measControlButton, hybridPathTypeSegmentedControl, hybridPathTypeButton, optionsPopover, optionsPopoverOn, pinListPopover, pinListPopoverOn, detailPopover, detailPopoverOn, upperToolbarView, upperToolbar;

# pragma mark initialize mapView

-(MKMapView *) mapView {
    if (!mapView) mapView = [[MKMapView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    
    // added 1-18-12 -- to get google logo to show up
    mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    return mapView;
}

# pragma mark mapView delegate methods
- (void)mapView:(MKMapView *)mv didAddAnnotationViews:(NSArray *)views {
    MKAnnotationView *annotationView = [views objectAtIndex:0];
    id <MKAnnotation> mp = [annotationView annotation];
    
    //MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([mp coordinate], REGION_DIST, REGION_DIST);
    // [mv setRegion:region animated:YES];
    
    CLLocationCoordinate2D coordinate = [mp coordinate];
    NSLog(@"lat: %f, lon: %f", coordinate.latitude, coordinate.longitude );
    
    // put into array
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	// NSLog(@"viewForAnnotation entered");
    
    if ([annotation isEqual:[self.mapView userLocation]]) {
        return nil;
    }
    
    [activityInd stopAnimating];
    messageLabel.hidden = NO;
    
	MKPinAnnotationView *l_mpPin=[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"currentloc"];
    
    // don't need to check if it's in meas vs route modes
    if ([appDelegate.measModel.coordinatePoints indexOfObject:annotation] == 0) {
        l_mpPin.pinColor = MKPinAnnotationColorGreen;
    }
    else if ([appDelegate.measModel.hybridPoints indexOfObject:annotation] == 0) {
        l_mpPin.pinColor = MKPinAnnotationColorPurple;
    }
    else {
        l_mpPin.pinColor = MKPinAnnotationColorRed;
    }
    
    l_mpPin.draggable = YES;
    
    l_mpPin.animatesDrop=TRUE;
    l_mpPin.canShowCallout = YES;
    l_mpPin.calloutOffset = CGPointMake(-5, 5);
    
    
    UIImage *removeIconOrig = [UIImage imageNamed:@"delete.png"];
    CGSize iconSize = CGSizeMake(30, 30);
    UIImage *removeIcon = [appDelegate.measModel imageWithImage:removeIconOrig scaledToSize:iconSize];
    // UIImageView *removeView = [[UIImageView alloc] initWithImage:removeIcon];
    UIButton *removeView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, iconSize.width, iconSize.height)];
    [removeView setImage:removeIcon forState:UIControlStateNormal];
    l_mpPin.leftCalloutAccessoryView = removeView;
    l_mpPin.leftCalloutAccessoryView.tag = 0;
    [removeView release];
    
    l_mpPin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    l_mpPin.rightCalloutAccessoryView.tag = 1;
    
    return [l_mpPin autorelease];
}


-(void) mapView:(MKMapView *) sender annotationView:(MKAnnotationView *)aView calloutAccessoryControlTapped:(UIControl *)control {
    MapPoint *mp = aView.annotation;
    block_t annotationBlock = ^{
        // NSLog(@"running processAnnotationCallout");
        [self processAnnotationCallout:mp controlTagVal:control.tag];
    };
    [self runCodeBlockWithActivityInd:annotationBlock];
}

-(void) runCodeBlockWithActivityInd:(block_t) codeBlock {
    
    [self.activityInd startAnimating];
    self.messageLabel.hidden = YES;
    
    //NSLog(@"create downloadQueue");
    dispatch_queue_t downloadQueue = dispatch_queue_create("activity ind block", NULL);
    dispatch_queue_t callerQueue = dispatch_get_current_queue();
    //NSLog(@"call dispatch_async");
    dispatch_async(downloadQueue, ^{
        dispatch_async(callerQueue, ^{
            codeBlock();
            [self.activityInd stopAnimating];
            self.messageLabel.hidden = NO;
        });
        dispatch_release(callerQueue);
    });
    //NSLog(@"release downloadQueue");
    dispatch_release(downloadQueue);
}

-(void) processAnnotationCallout:(MapPoint *) mp controlTagVal:(int)controlTagVal {
    
    if (controlTagVal == 0) {
        [self deleteAnnotation:mp];
    }
    else {
        // made separate method to account for iPad stuff
        [self processDetailAnnotationView:mp];
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    // NSLog(@"drag state of annotationView changed: %@", annotationView);
    
    MapPoint *mp = annotationView.annotation;
    
    if (newState == MKAnnotationViewDragStateEnding)
    {
        NSLog(@"Dragged annotationView new coordinate: %.2f, %.2f", mp.coordinate.latitude, mp.coordinate.longitude);
        
        block_t dragBlock = ^{
            // NSLog(@"running processAnnotationCallout");
            
            int originalMapMode = appDelegate.measModel.mappingMode;
            
            // goto mapping mode of when pin was placed
            [self updateMappingModeTo:mp.mappingModeWhenPlaced];
            
            if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) {
                [self updateMeasureModeOverlaysAndAnnotations];
            }
            else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
                [self updateRouteModeOverlaysAndAnnotations:mp];
            }
            
            [self updateMappingModeTo:originalMapMode];
        };
        [self runCodeBlockWithActivityInd:dragBlock];
    }
}

- (void)mapView:(MKMapView *)sender didSelectAnnotationView:(MKAnnotationView *)aView
{
    
}

# pragma mark core location methods
- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    // NSLog(@"locationManager::didUpdateToLocation: \n%@", newLocation);
    NSTimeInterval t = [[newLocation timestamp] timeIntervalSinceNow];
    
    if (t < -180) {
        return;
    }
    
    if (doneWaitingForLocationAquire == 0) {
        // NSLog(@"don't drop pin for current location yet:: \ndoneWaitingForLocationAquire: %d", doneWaitingForLocationAquire);
        return;
    }
    else {
        // NSLog(@"finished waiting for current location");
    }
    
    coreLocationFailed = 0;
    
    MapPoint *mp = [[MapPoint alloc] initWithCoordinate:[newLocation coordinate] title:@"current point" subtitle:@"subtitle"];
    
    MKUserLocation *blueDot = [self.mapView userLocation];
    
    // [blueDot setTitle:[NSString stringWithFormat:@"(%.5f, %.5f)", mp.coordinate.latitude, mp.coordinate.longitude]];
    
    [blueDot setTitle:[appDelegate.measModel getLatLonStr:mp.coordinate.latitude longitude:mp.coordinate.longitude]];
    [blueDot setSubtitle:@"current location"];
    
    if ([appDelegate.measModel.coordinatePoints count] == 0) {
        [self setCenterCoordinate:[newLocation coordinate] zoomLevel:15 animated:YES];
    }
    else {
        [self.mapView setCenterCoordinate:[newLocation coordinate] animated:YES];
    }
    
    if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) {
        [self addAnnotationToMap:mp];  // add annotation for current location
    }
    else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
        [self addHybridAnnotationToMap:mp];
    }
    
    [mp release];
    
    [self foundLocation];
}

-(void) foundLocation {
    [locationManager stopUpdatingLocation];
    // lookingForLocation = 0;
    
    // NSLog(@"Location found");
    
    [activityInd stopAnimating];
    activityInd.hidden = YES;
    messageLabel.hidden = NO;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"core location failure: can't find current location");
    coreLocationFailed = 1;
    [activityInd stopAnimating];
    messageLabel.hidden = NO;
    messageLabel.text = @"current location not found";
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    [super viewDidLoad];
    
    appDelegate = [[UIApplication sharedApplication] delegate];
    
    locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    [locationManager setDistanceFilter:kCLDistanceFilterNone];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    
    // dFinder = [[LMDirectionFinder alloc] init];
    
    coreLocationFailed = 0;
    
    
    // Tap gestures to dismiss search keyboard
    // UITapGestureRecognizer *recognizer;
	recognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)] autorelease];
	[(UITapGestureRecognizer *)recognizer setNumberOfTouchesRequired:1];
	[self.mapView addGestureRecognizer:recognizer];
    recognizer.enabled = NO;
	// recognizer.delegate = self;
    
    
    // long tap to put down waypoint
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.35; //user needs to press for 0.35 seconds
    [self.mapView addGestureRecognizer:lpgr];
    [lpgr release];
    
    self.view = [[[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame] autorelease];
    
    self.mapView.frame = self.view.bounds;
    [self.view addSubview:self.mapView];
    
    //self.mapView.hidden = YES;
    self.mapView.delegate = self;
    
    // change title back to Start later
    // list button item
    //UIBarButtonItem *listButton = [[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleBordered target:self action:@selector(openPinListTable)] autorelease];
    listButton = [[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleBordered target:self action:@selector(openPinListTable)] autorelease];
    

    
    UIImage *listIconOrig = [UIImage imageNamed:@"folder.png"];
    UIImage *listIcon = [appDelegate.measModel imageWithImage:listIconOrig scaledToSize:CGSizeMake(20, 20)];
    [listButton setImage:listIcon];
    
    //self.navigationItem.rightBarButtonItem = listButton;
    
    // search button
    UIBarButtonItem *searchButton = [[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleBordered target:self action:@selector(testSearch)] autorelease];
    
    UIImage *searchIconOrig = [UIImage imageNamed:@"magnifyingglass.png"];
    UIImage *searchIcon = [appDelegate.measModel imageWithImage:searchIconOrig scaledToSize:CGSizeMake(20, 20)];
    [searchButton setImage:searchIcon];
    // searchButton.tintColor = [UIColor grayColor];
    
   // self.navigationItem.leftBarButtonItem = searchButton;
    
    //self.navigationItem.titleView = [self pinActionSegmentedControl];
    UIView * segContrlView = [[UIView alloc] initWithFrame:[self pinActionSegmentedControl].bounds];
    [segContrlView addSubview:[self pinActionSegmentedControl]];
    UIBarButtonItem *segBtn = [[UIBarButtonItem alloc] initWithCustomView:segContrlView];
    
    
    upperToolbar = [[UIToolbar  alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width-20, 33)];
    
    flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    [upperToolbar setItems:[NSArray arrayWithObjects:searchButton,flexibleSpace, segBtn,flexibleSpace,listButton, nil]];
    upperToolbarView = [[UIView alloc] initWithFrame:CGRectMake(0, 22, self.view.bounds.size.width-20, 33)];
    upperToolbarView.backgroundColor = [UIColor clearColor];
    
    [upperToolbarView addSubview:upperToolbar];
    self.navigationItem.titleView  =upperToolbarView;
    
    
    [self setToolbarItems:[NSArray arrayWithObjects:currentLocationButton, flexibleSpace, mappingModeButton, flexibleSpace, measControlButton, flexibleSpace, optionsMenuButton, nil]];
    
    
    [self loadToolbar];
    
    UIColor *defaultBlueColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.6];
    
    //[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    // self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    // self.navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;
    self.navigationController.toolbar.tintColor = defaultBlueColor;
    self.navigationController.navigationBar.tintColor = defaultBlueColor;
    
    // UIColor *defaultBlueColor = [UIColor colorWithHue:0.6 saturation:0.33 brightness:0.69 alpha:1];
    
    // todo: put border around the view
    
    if ([appDelegate iPad]) {
        messageViewSize = CGSizeMake(780, 60);
    }
    else {
        messageViewSize = CGSizeMake(320, 60);
    }
    
    self.messageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, messageViewSize.width, messageViewSize.height)];
    [messageView setBackgroundColor:defaultBlueColor];
    //[self.messageView setBackgroundColor:[UIColor lightGrayColor]];
    [self.messageView setAlpha:0.8];
    [self.view addSubview:self.messageView];
    
    messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, messageViewSize.width, messageViewSize.height)];
    [messageLabel setFont:[UIFont boldSystemFontOfSize:18]];
    [messageLabel setTextAlignment:NSTextAlignmentCenter];
    [messageLabel setBackgroundColor:[UIColor clearColor]];
    [messageLabel setTextColor:[UIColor whiteColor]];
    [messageLabel setText:@"message bar text"];
    messageLabel.adjustsFontSizeToFitWidth = YES;
    messageLabel.minimumScaleFactor = 5;
    messageLabel.numberOfLines = 5;
    [self.messageView addSubview:messageLabel];
    [self.messageView addSubview:activityInd];
    self.activityInd.hidden = YES;
    
    // not used
    toggleButtonImage = [UIImage imageNamed:@"eject.png"];
    toggleButtonSize = CGSizeMake(55, 30);
    toggleButtonLocation = CGPointMake(50, 60);
    toggleButton = [[UIButton alloc] initWithFrame:CGRectMake(toggleButtonLocation.x, toggleButtonLocation.y, toggleButtonSize.width, toggleButtonSize.height)];
    toggleButton.alpha = 0.8;
    [toggleButton setImage:toggleButtonImage forState:UIControlStateNormal];
    [toggleButton addTarget:self action:@selector(toggleMessageView) forControlEvents:UIControlEventTouchUpInside];
    // [self.view addSubview:toggleButton];
    // toggleButton.hidden = YES;
    
    // instructions button
    UIButton *instructionsButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    instructionsButton.frame = CGRectMake(self.view.frame.size.width - 25, self.view.frame.size.height - 120, instructionsButton.frame.size.width, instructionsButton.frame.size.height);
    [instructionsButton addTarget:self action:@selector(presentInstructionsView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:instructionsButton];
    
    
    messageViewOnScreen = 1;
    
    [defaultBlueColor release];
}

-(void) loadToolbar {
    [self.navigationController setToolbarHidden:NO];
    [self.navigationController.toolbar setBarStyle:UIBarStyleDefault];
    
    // current location button
    currentLocationButton = [[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleBordered target:self action:@selector(gotoCurrentLocation)] autorelease];
    
    UIImage *locationIconSmall = [UIImage imageNamed:@"location-arrow.png"];
    UIImage *locationIcon = [appDelegate.measModel imageWithImage:locationIconSmall scaledToSize:CGSizeMake(15, 15)];
    
    [currentLocationButton setImage:locationIcon];
    
    // options button
    optionsMenuButton = [[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleBordered target:self action:@selector(openOptionsMenu)] autorelease];
    
    UIImage *optionsIconSmall = [UIImage imageNamed:@"gear.png"];
    UIImage *optionsIcon = [appDelegate.measModel imageWithImage:optionsIconSmall scaledToSize:CGSizeMake(15, 15)];
    [optionsMenuButton setImage:optionsIcon];
    
    flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    int useButtonForMappingMode = 0;
    if (useButtonForMappingMode == 1) {
        mappingModeButton = [[[UIBarButtonItem alloc] initWithTitle:@"Measure" style:UIBarButtonItemStyleBordered target:self action:@selector(updateMappingMode)] autorelease];
    }
    else {
        mappingModeControl = [self mappingModeSegmentedControl];
        [mappingModeControl setSelectedSegmentIndex:0];
        mappingModeButton = [[UIBarButtonItem alloc] initWithCustomView:mappingModeControl];
    }
    
    // [self updateMappingMode];
    
    measSegmentedControl = [self measureSegmentedControl];
    measSegmentedControl.selectedSegmentIndex = appDelegate.measModel.mode;
    measControlButton = [[UIBarButtonItem alloc] initWithCustomView:measSegmentedControl];
    
    hybridPathTypeSegmentedControl = [self hybridSegmentedControl];
    hybridPathTypeButton = [[UIBarButtonItem alloc] initWithCustomView:hybridPathTypeSegmentedControl];
    hybridPathTypeSegmentedControl.tintColor = [UIColor grayColor];
    
    /*
     UISegmentedControl *pinSegmentedControl = [self pinActionSegmentedControl];
     UIBarButtonItem *pinControlButton = [[UIBarButtonItem alloc] initWithCustomView:pinSegmentedControl];
     */
    
    if ([appDelegate iPad] == YES) {
        activityInd = [self activityIndicator:CGRectMake(370, 20, 25, 25)];
    }
    else {
        activityInd = [self activityIndicator:CGRectMake(150, 20, 25, 25)];
    }
    
    [self setToolbarItems:[NSArray arrayWithObjects:currentLocationButton, flexibleSpace, mappingModeButton, flexibleSpace, measControlButton, flexibleSpace, optionsMenuButton, nil]];
    
    [flexibleSpace release];
    
    BOOL alwaysShowLicense = NO;
    if (alwaysShowLicense || [[NSUserDefaults standardUserDefaults] boolForKey:@"showLicense"] == YES) {
        [self presentLicenseAgreement];
    }
}

-(void) presentLicenseAgreement {
    LicenseView *license = [[LicenseView alloc] initWithNibName:@"LicenseView" bundle:nil];
    license.delegate = self;
    
    if ([appDelegate iPad] == YES) {
        license.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:license animated:NO completion:nil];
        license.view.superview.frame = CGRectMake(0, 0, 320, 480);
        license.view.superview.center = self.view.center;
    }
    else {
        [self presentViewController:license animated:NO completion:nil];
    }
    
    [license release];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"viewDidAppear called");
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:@"showMessageBar"];
    [self toggleMessageViewTo:(int) val];
}

-(void) viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear called on main view controller");
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:YES];
    [self updateMessageBar];
    [self updateAllAnnotations];
    [self updateMapType];
    
    if (searchBarView.hidden == NO) {
        [self searchBarCancelButtonClicked:searchBar];
    }
    
    if (appDelegate.kmlManager.needToLoadFileOnMap == 1) {
        [self loadKML];
        appDelegate.kmlManager.needToLoadFileOnMap = 0;
        if ([appDelegate.measModel.coordinatePoints count] == 0 && [appDelegate.measModel.hybridPoints count] == 0) {
            messageLabel.text = @"no points in file";
        }
    }
    
    if (appDelegate.kmlManager.needToSaveFile == 1) {
        [self writeKMLFile];
        appDelegate.kmlManager.needToSaveFile = 0;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"KML File Saved" message:@"KML file has been saved locally.  It can be loaded again from within the app. It can also be saved to your computer with iTunes App File Sharing, and viewed with Google Earth.  You can load kml files from other users using iTunes File Sharing."  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alert show];
        [alert release];
    }
    
    [self setTrackLocationTimer];
}



# pragma mark track location timer

-(void) setTrackLocationTimer {
    
    BOOL trackLocationVal = [[NSUserDefaults standardUserDefaults] boolForKey:@"trackLocation"];
    NSLog(@"trackLocationVal: %d", trackLocationVal);
    
    int intervalSecs = appDelegate.measModel.trackingSecs;
    if (trackLocationVal == YES) {
        if (trackLocationTimer == nil || [trackLocationTimer isValid] == NO) {
            // don't need to get rid of old one
        }
        else {
            // get rid of old one
            [trackLocationTimer invalidate];
            trackLocationTimer = nil;
        }
        
        // set new one with new intervalSecs
        trackLocationTimer = [NSTimer scheduledTimerWithTimeInterval:intervalSecs target:self selector:@selector(gotoCurrentLocationWithTimer:) userInfo:nil repeats:YES];
        
        [[UIApplication sharedApplication ] setIdleTimerDisabled: YES ];
        messageLabel.text = [NSString stringWithFormat:@"Measure mode tracking. Current location pin drops every %d seconds", intervalSecs];
        
        [self.mapView setShowsUserLocation:YES];
        doneWaitingForLocationAquire = 1;
    }
    else if (trackLocationTimer != nil ) {
        [trackLocationTimer invalidate];
        trackLocationTimer = nil;
        [[ UIApplication sharedApplication ] setIdleTimerDisabled: NO ];
        // NSLog(@"trackLocationTimer invalidated, set to nil");
    }
}

# pragma mark update map type
-(void) updateMapType {
    if (appDelegate.measModel.mapTypeSelection == 0) {
        self.mapView.mapType = MKMapTypeStandard;
        NSLog(@"standard map type");
    }
    else if (appDelegate.measModel.mapTypeSelection == 1) {
        self.mapView.mapType = MKMapTypeSatellite;
        NSLog(@"satellite map type");
    }
    else if (appDelegate.measModel.mapTypeSelection == 2) {
        self.mapView.mapType = MKMapTypeHybrid;
        NSLog(@"hybrid map type");
    }
}

# pragma mark hybrid mode segmented control for toolbar

// moved to MeasModel
// #define HYBRID_PATH_ROUTE 0
// #define HYBRID_PATH_LINE 1

-(UISegmentedControl *) hybridSegmentedControl {
    NSArray *measOptions = [[NSArray arrayWithObjects:@"Path", @"Line", nil] retain];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:measOptions];
    [segmentedControl addTarget:self action:@selector(changeHybridType:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.selectedSegmentIndex = 0; // select route by default
    return [segmentedControl autorelease];
}

-(void) changeHybridType:(UISegmentedControl *) segmentedControl {
    NSLog(@"meas type selected index: %d", segmentedControl.selectedSegmentIndex);
    appDelegate.measModel.hybridPathMode = segmentedControl.selectedSegmentIndex;
    switch (segmentedControl.selectedSegmentIndex) {
        case HYBRID_PATH_ROUTE:
            // index 0
            NSLog(@"hybrid: in path mode");
            messageLabel.text = @"find route to next point";
            break;
        case HYBRID_PATH_LINE:
            // index 1
            NSLog(@"hybrid: in line mode");
            messageLabel.text = @"find line to next point";
            break;
        default:
            break;
    }
    //    [self updateMessageBar];
}

# pragma mark measure mode segmented control for toolbar

-(UISegmentedControl *) measureSegmentedControl {
    //NSArray *measOptions = [[NSArray arrayWithObjects:@"Distance", @"Area", nil] retain];
    //UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:measOptions];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:nil];
    [segmentedControl insertSegmentWithImage:[UIImage imageNamed:@"distance.png"] atIndex:0 animated:NO];
    [segmentedControl insertSegmentWithImage:[UIImage imageNamed:@"area.png"] atIndex:1 animated:NO];
    [segmentedControl addTarget:self action:@selector(changeMeasType:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.selectedSegmentIndex = 0; // select distance by default
    segmentedControl.tintColor = [UIColor grayColor];
    return [segmentedControl autorelease];
}

-(void) changeMeasType:(UISegmentedControl *) segmentedControl {
    NSLog(@"meas type selected index: %d", segmentedControl.selectedSegmentIndex);
    appDelegate.measModel.mode = segmentedControl.selectedSegmentIndex;
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            NSLog(@"in distance mode");
            [self drawCurrentPolyline];
            break;
        case 1:
            NSLog(@"in area mode");
            [self drawCurrentPolygon];
            break;
        default:
            break;
    }
    [self updateMessageBar];
}

# pragma mark mapping mode toggle (measure, route, hybrid)

-(UISegmentedControl *) mappingModeSegmentedControl {
    NSArray *mappingOptions = [[NSArray arrayWithObjects:@"Measure", @"Route", nil] retain];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:mappingOptions];

    segmentedControl.tintColor = [UIColor grayColor];
    [segmentedControl addTarget:self action:@selector(switchMappingMode:) forControlEvents:UIControlEventValueChanged];
    return [segmentedControl autorelease];
}

-(void) switchMappingMode:(UISegmentedControl *) segmentedControl {
    NSLog(@"switchMappingMode selected index: %d", segmentedControl.selectedSegmentIndex);
    if(segmentedControl.selectedSegmentIndex == 0) {
        [self updateMappingModeTo:MAP_MODE_MEAS];
    }
    else if (segmentedControl.selectedSegmentIndex == 1) {
        [self updateMappingModeTo:MAP_MODE_HYBRID];
    }
}

-(void) updateMappingModeTo:(int) newMapMode {
    if (appDelegate.measModel.mappingMode != newMapMode) {
        [self updateMappingMode];
    }
    else {
        // do not update
    }
}

-(void) updateMappingMode {
    // appDelegate.measModel.mappingMode = (appDelegate.measModel.mappingMode + 1) % 3;
    
    // skip the normal route mode
    if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
        appDelegate.measModel.mappingMode = MAP_MODE_MEAS;
    }
    else if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) {
        appDelegate.measModel.mappingMode = MAP_MODE_HYBRID;
    }
    
    // NSLog(@"new mappingMode: %d", appDelegate.measModel.mappingMode);
    
    NSString *mappingModeStr = nil;
    switch (appDelegate.measModel.mappingMode) {
        case MAP_MODE_MEAS:
            mappingModeStr = @"Measure";
            [self setToolbarItems:[NSArray arrayWithObjects:currentLocationButton, flexibleSpace, mappingModeButton, flexibleSpace, measControlButton, flexibleSpace, optionsMenuButton, nil]];
            // self.messageLabel.text = [NSString stringWithFormat:@"In Measurement Mode \n (for area and distance)"];
            break;
        case MAP_MODE_HYBRID:
            mappingModeStr = @"Route";
            [self setToolbarItems:[NSArray arrayWithObjects:currentLocationButton, flexibleSpace, mappingModeButton, flexibleSpace, hybridPathTypeButton, flexibleSpace, optionsMenuButton, nil]];
            // self.messageLabel.text = @"In Route Mode: lay down paths or lines";
            break;
        default:
            break;
    }
    [mappingModeButton setTitle:mappingModeStr];
}

# pragma mark redo, undo, and erase buttons
-(UISegmentedControl *) pinActionSegmentedControl {
    //NSArray *pinOptions = [[NSArray arrayWithObjects:@"Undo", @"Redo", @"Clear", nil] retain];
    // UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:pinOptions];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:nil];
    [segmentedControl insertSegmentWithImage:[UIImage imageNamed:@"do.png"] atIndex:0 animated:NO];
    [segmentedControl insertSegmentWithImage:[UIImage imageNamed:@"redo.png"] atIndex:1 animated:NO];
    [segmentedControl insertSegmentWithImage:[UIImage imageNamed:@"clearall.png"] atIndex:2 animated:NO];
    [segmentedControl addTarget:self action:@selector(doPinAction:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.momentary = YES;
    return [segmentedControl autorelease];
}

-(void) doPinAction:(UISegmentedControl *) segmentedControl {
    
    [self dismissPinListPopoverController];
    [self dismissDetailPopoverController];
    
    NSLog(@"pin action selected index: %d", segmentedControl.selectedSegmentIndex);
    if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) {
        [self doPinActionMeasureMode:segmentedControl];
    }
    else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
        [self doPinActionRouteMode:segmentedControl];
    }
}

-(void) doPinActionMeasureMode:(UISegmentedControl *) segmentedControl {
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            NSLog(@"undo last annotation");
            MapPoint *lastAnnot = [appDelegate.measModel.coordinatePoints lastObject];
            if (lastAnnot != nil) {
                [appDelegate.measModel.erasedPoints addObject:lastAnnot];
                [self.mapView removeAnnotation:lastAnnot];
                [appDelegate.measModel.coordinatePoints removeLastObject];
            }
            
            [appDelegate.measModel updateTotalDistance];
            
            if (appDelegate.measModel.mode == 1) {
                [self drawCurrentPolygon];
            }
            else if (appDelegate.measModel.mode == 0) {
                [self drawCurrentPolyline];
            }
            break;
        case 1:
            NSLog(@"redo last annotation");
            if ([appDelegate.measModel.erasedPoints count] > 0) {
                //NSLog(@"num erased objects: %d", [appDelegate.measModel.erasedPoints count]);
                MapPoint *erasedAnnot = [appDelegate.measModel.erasedPoints lastObject];
                [self addAnnotationToMap:erasedAnnot];
                [appDelegate.measModel.erasedPoints removeLastObject];
            }
            break;
            
        case 2:
            // erase all pins and segments from view
            // [self mapClearAll];
            // [self mapClearAllMeasurements];
            [self clearAllPressed];
            break;
            
        default:
            break;
    }
    
    [self updateMessageBar];
}

-(void) doPinActionRouteMode:(UISegmentedControl *) segmentedControl {
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            NSLog(@"actionRouteMode: 0");
            [self undoLastRoutePin];
            break;
        case 1:
            [self redoLastRoutePin];
            break;
        case 2:
            // [self mapClearAllRoutes];
            [self clearAllPressed];
            break;
        default:
            break;
    }
    
    [self updateMessageBar];
}

-(void) undoLastRoutePin {
    
    NSMutableArray *points = nil;
    NSMutableArray *erasedPoints = nil;
    if (appDelegate.measModel.mappingMode == 1) {
        points = appDelegate.measModel.routePoints;
        erasedPoints = appDelegate.measModel.routeErasedPoints;
    }
    else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
        points = appDelegate.measModel.hybridPoints;
        erasedPoints = appDelegate.measModel.hybridErasedPoints;
    }
    
    MapPoint *lastAnnot = [points lastObject];
    if (lastAnnot != nil) {
        [erasedPoints addObject:lastAnnot];
        [self.mapView removeAnnotation:lastAnnot];
        [points removeLastObject];
        
        // MKPolyline *lastRouteLine = [appDelegate.measModel.routeLines lastObject];
        // [appDelegate.measModel.routeLines removeObject:lastRouteLine];
        // [self.mapView removeOverlay:lastRouteLine];
        
        [self.mapView removeOverlay:lastAnnot.lineFromPrevPoint];
    }
}

-(void) redoLastRoutePin {
    
    NSMutableArray *erasedPoints = nil;
    if (appDelegate.measModel.mappingMode == 1) {
        erasedPoints = appDelegate.measModel.routeErasedPoints;
    }
    else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
        erasedPoints = appDelegate.measModel.hybridErasedPoints;
    }
    
    if ([erasedPoints count] > 0) {
        NSLog(@"num erased route points: %d", [erasedPoints count]);
        int numErased = [erasedPoints count];
        if (numErased > 0) {
            MapPoint *erasedAnnot = [erasedPoints lastObject];
            
            if (appDelegate.measModel.mappingMode == 1) {
                // [self addRouteAnnotationToMap:erasedAnnot];
            }
            else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
                [self addHybridAnnotationToMap:erasedAnnot];
            }
            [erasedPoints removeLastObject];
        }
    }
}

-(void) mapClearAll {
    NSLog(@"erase all annotations");
    [self.mapView removeAnnotations:mapView.annotations];
    [self.mapView removeOverlays:mapView.overlays];
    
    [self.mapView setShowsUserLocation:NO];
    
    [appDelegate.measModel.coordinatePoints removeAllObjects];
    // [appDelegate.measModel.lines removeAllObjects];  // no longer used
    [appDelegate.measModel.erasedPoints removeAllObjects];
    // [appDelegate.measModel.deltaDistMetersArray removeAllObjects];  // no longer used
}

-(void) mapClearAllRoutes {
    
    /*
     NSMutableArray *points;
     if (appDelegate.measModel.mappingMode == 1) {
     points = appDelegate.measModel.routePoints;
     }
     else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
     points = appDelegate.measModel.hybridPoints;
     }
     */
    
    NSMutableArray *points = appDelegate.measModel.hybridPoints;
    
    [self.mapView setShowsUserLocation:NO];
    
    for (MapPoint *mp in points) {
        [self.mapView removeAnnotation:mp];
    }
    
    for (MapPoint *routePoint in points) {
        if (routePoint.lineFromPrevPoint != nil)
            [self.mapView removeOverlay:routePoint.lineFromPrevPoint];
    }
    
    /*
     for (MKPolyline *line in appDelegate.measModel.routeLines) {
     [self.mapView removeOverlay:line];
     }
     */
    
    [points removeAllObjects];
    // [appDelegate.measModel.routeLines removeAllObjects];
}

-(void) mapClearAllMeasurements {
    [self.mapView setShowsUserLocation:NO];
    for (MapPoint *mp in appDelegate.measModel.coordinatePoints) {
        [self.mapView removeAnnotation:mp];
    }
    if (appDelegate.measModel.currentPolyline != nil) {
        [self.mapView removeOverlay:appDelegate.measModel.currentPolyline];
    }
    if (appDelegate.measModel.currentPolygon != nil) {
        [self.mapView removeOverlay:appDelegate.measModel.currentPolygon];
    }
    [appDelegate.measModel.coordinatePoints removeAllObjects];
    [appDelegate.measModel.erasedPoints removeAllObjects];
}

# pragma mark alert view delegate for clear all

-(void) clearAllPressed {
    NSString *modeStr = @"";
    if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) {
        modeStr = @"Measure";
    }
    else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
        modeStr = @"Route";
    }
    NSString *titleStr = [NSString stringWithFormat:@"%@ Clear All", modeStr];
    NSString *msgStr = [NSString stringWithFormat:@"this will erase all pins for the %@ mode.  You cannot undo this action.  are you sure?", modeStr];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:titleStr message:msgStr delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
    [alert show];
    [alert release];
    
    // [self updatePinListTableView];
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        return;
    }
    else {
        if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) {
            [self mapClearAllMeasurements];
        }
        else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
            [self mapClearAllRoutes];
        }
    }
}

# pragma mark gestures


-(IBAction) handleTapGesture:(UITapGestureRecognizer *) sender {
	NSLog(@"tap detected");
    
    // cancel the search bar
    if (searchBarView.hidden == NO) {
        [self searchBarCancelButtonClicked:searchBar];
    }
}

-(IBAction) handleLongPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    
    [self addPointToMap:touchPoint];
}


# pragma mark adding annotations
-(void) addPointToMap:(CGPoint ) touchPoint
{
    CLLocationCoordinate2D touchMapCoordinate =
    [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    
    MapPoint *annot = [[MapPoint alloc] initWithCoordinate:touchMapCoordinate title:@"tap coordinate"  subtitle:@"subtitle"];
    
    if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) {
        [self addAnnotationToMap:annot];
    }
    else if (appDelegate.measModel.mappingMode == 1) {
        //[self addRouteAnnotationToMap:annot];
    }
    else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
        [self addHybridAnnotationToMap:annot];
    }
    
    [annot release];
}

-(void) addHybridAnnotationToMap:(MapPoint *) annot {
    [self addHybridAnnotationToMap:annot isNewPoint:1 withActivity:1];
}

-(void) addHybridAnnotationToMap:(MapPoint *) annot isNewPoint:(int) isNewPoint withActivity:(int) withActivity {
    NSLog(@"calling addHybridAnnotationToMap");
    int routeLineVal = 0;
    if (appDelegate.measModel.hybridPathMode == HYBRID_PATH_LINE) {
        // draw a line
        routeLineVal = [self drawNewPolyline:annot];
    }
    else if (appDelegate.measModel.hybridPathMode == HYBRID_PATH_ROUTE) {
        // annot.mappingTypeFromPrevPoint = 1;
        NSLog(@"addHybridAnnotationToMap:: withActivity:%d", withActivity);
        routeLineVal = [self drawCurrentRouteLineWithActivity:annot isNewPoint:isNewPoint withActivity:withActivity];
        // routeLineVal = [self drawCurrentRouteLine:annot];
    }
    [self updateRouteAnnotationTitle:annot addResult:routeLineVal mappingMode:appDelegate.measModel.mappingMode];
    
    // [self updateAllAnnotations];
    
    [self updateMessageBarRoute:routeLineVal];
}

-(void) addAnnotationToMap:(MapPoint *) annot
{
    annot.mappingModeWhenPlaced = MAP_MODE_MEAS;
    annot.pathTypeFromPrevPoint = HYBRID_PATH_LINE;
    
    [appDelegate.measModel.coordinatePoints addObject:annot];
    
    [self updateMeasureModeOverlaysAndAnnotations];
    
    [self.mapView addAnnotation:annot];
}

# pragma mark delete annotation from map
-(void) deleteAnnotation:(MapPoint *) annot {
    int originalMapMode = appDelegate.measModel.mappingMode;
    int pinMapMode = annot.mappingModeWhenPlaced;
    
    if (pinMapMode == MAP_MODE_MEAS) {
        [self updateMappingModeTo:MAP_MODE_MEAS];
        [self deleteMeasureAnnotation:annot];
    }
    else if (pinMapMode == MAP_MODE_HYBRID) {
        [self updateMappingModeTo:MAP_MODE_HYBRID];
        [self deleteRouteAnnotation:annot];
    }
    
    [self updateMappingModeTo:originalMapMode];
}

-(void) deleteMeasureAnnotation:(MapPoint *) annot {
    
    // remove from coordinatePoints
    [appDelegate.measModel.coordinatePoints removeObject:annot];
    
    // remove from map
    [self.mapView removeAnnotation:annot];
    
    // update the drawing and annotation titles
    [self updateMeasureModeOverlaysAndAnnotations];
}

-(void) updateMeasureModeOverlaysAndAnnotations {
    if (appDelegate.measModel.mode == 0) {
        [self drawCurrentPolyline];
    }
    else if (appDelegate.measModel.mode == 1) {
        [self drawCurrentPolygon];
    }
    
    [appDelegate.measModel updateTotalDistance];
    [self updateAllAnnotations];
    [self updateMessageBar];
}

-(void) deleteRouteAnnotation:(MapPoint *) annot {
    int annotInd = [appDelegate.measModel.hybridPoints indexOfObject:annot];
    int numRoutePoints = [appDelegate.measModel.hybridPoints count];
    
    MapPoint *nextPoint;
    [self.mapView removeAnnotation:annot];
    [appDelegate.measModel.hybridPoints removeObject:annot];
    
    if ([appDelegate.measModel.hybridPoints count] == 0) {
        [self updateMessageBar];
        return;
    }
    
    if (annotInd == 0) {
        // do update next point, don't remove previous line
        // with annot already removed from points array, nextPoint is first item in array
        nextPoint = [appDelegate.measModel.hybridPoints objectAtIndex:0];
        if (nextPoint.lineFromPrevPoint != nil)
            [self.mapView removeOverlay:nextPoint.lineFromPrevPoint];
        // [nextPoint.lineFromPrevPoint release];  // static analyzer warning: when should this be released?
        nextPoint.lineFromPrevPoint = nil;
        nextPoint.totalDistanceMeters = 0;
        nextPoint.deltaDistanceMeters = 0;
        [self updateRouteModeOverlaysAndAnnotations:nextPoint];
        //[self updateRouteModeOverlaysAndAnnotations:[appDelegate.measModel.hybridPoints lastObject]];
    }
    else if (annotInd == numRoutePoints - 1) {
        // don't update next point, remove previous line
        [self.mapView removeOverlay:annot.lineFromPrevPoint];
    }
    else {
        // remove previous line, update next point
        [self.mapView removeOverlay:annot.lineFromPrevPoint];
        // with annot already removed from points array, nextPoint is index of removed item in array
        nextPoint = [appDelegate.measModel.hybridPoints objectAtIndex:annotInd];
        [self updateRouteModeOverlaysAndAnnotations:nextPoint];
    }
    
    //[self updateAllAnnotations];
}

-(void) updateRouteModeOverlaysAndAnnotations:(MapPoint *) annot {
    // annot is the dragged annotation
    int numHybridPts = [appDelegate.measModel.hybridPoints count];
    
    if (numHybridPts <= 1) {
        [self updateAllAnnotations];
        [self updateMessageBar];
        return;
    }
    
    int ind = [appDelegate.measModel.hybridPoints indexOfObject:annot];
    MapPoint *nextPoint = nil;
    // MapPoint *prevPoint = nil;
    
    MKPolyline *lineFromPrev = nil;
    MKPolyline *lineToNext = nil;
    
    if (ind == numHybridPts-1) {
        // prevPoint = [appDelegate.measModel.hybridPoints objectAtIndex:(ind-1)];
        lineFromPrev = annot.lineFromPrevPoint;
    }
    else if (ind == 0) {
        nextPoint = [appDelegate.measModel.hybridPoints objectAtIndex:1];
        lineToNext = nextPoint.lineFromPrevPoint;
    }
    else {
        // prevPoint = [appDelegate.measModel.hybridPoints objectAtIndex:(ind-1)];
        nextPoint = [appDelegate.measModel.hybridPoints objectAtIndex:(ind+1)];
        lineFromPrev = annot.lineFromPrevPoint;
        lineToNext = nextPoint.lineFromPrevPoint;
    }
    
    // save hybridPathMode
    int hybridPathModeOriginal = appDelegate.measModel.hybridPathMode;
    
    if (lineFromPrev != nil) {
        [self.mapView removeOverlay:lineFromPrev];
        appDelegate.measModel.hybridPathMode = annot.pathTypeFromPrevPoint;
        if (appDelegate.measModel.hybridPathMode == HYBRID_PATH_LINE) {
            // redraw line to current point
            [self drawNewPolyline:annot isNewMapPoint:0];
        }
        else if (appDelegate.measModel.hybridPathMode == HYBRID_PATH_ROUTE) {
            int newRouteFound = [self drawCurrentRouteLine:annot isNewPoint:0];
            if (newRouteFound == -1) {
                // if new route was not found, draw straight line
                appDelegate.measModel.hybridPathMode = HYBRID_PATH_LINE;
                [self drawNewPolyline:annot isNewMapPoint:0];
                appDelegate.measModel.hybridPathMode = HYBRID_PATH_ROUTE;
            }
        }
    }
    
    if (lineToNext != nil) {
        [self.mapView removeOverlay:lineToNext];
        appDelegate.measModel.hybridPathMode = nextPoint.pathTypeFromPrevPoint;
        if (appDelegate.measModel.hybridPathMode == HYBRID_PATH_LINE) {
            // redraw line to next point
            [self drawNewPolyline:nextPoint isNewMapPoint:0];
        }
        else if (appDelegate.measModel.hybridPathMode == HYBRID_PATH_ROUTE) {
            int newRouteFound = [self drawCurrentRouteLine:nextPoint isNewPoint:0];
            if (newRouteFound == -1) {
                // if new route was not found, draw straight line
                appDelegate.measModel.hybridPathMode = HYBRID_PATH_LINE;
                [self drawNewPolyline:nextPoint isNewMapPoint:0];
                appDelegate.measModel.hybridPathMode = HYBRID_PATH_ROUTE;
            }
        }
    }
    
    // reload hybridPathMode
    appDelegate.measModel.hybridPathMode = hybridPathModeOriginal;
    // continue this later
    
    [self updateAllAnnotations];
    
    [self updateMessageBar];
}

# pragma mark annotation messages


-(void) updateRouteAnnotationTitle:(MapPoint *) annot addResult:(int) val mappingMode:(int) mappingMode {
    
    if (val == -1) {
        NSLog(@"returning from updateRouteAnnotationTitle");
        return;
    }
    
    [self updateAnnotationTitle:annot];
}

-(void) updateAnnotationTitle:(MapPoint *) annot {
    
    // NSArray *points = [self getPointsForMode];
    NSArray *points = [appDelegate.measModel getPointsForMode];
    
    int annotInd = [points indexOfObject:annot];
    
    NSLog(@"updateAnnotationTitle::annotInd: %d, numPointsForMode: %d", annotInd, [points count]);
    
    NSString *latLon = [appDelegate.measModel getLatLonStr:annot.coordinate.latitude longitude:annot.coordinate.longitude shortVersion:1];
    
    NSString *newTitle = [NSString stringWithFormat:@"%@", latLon];
    
    NSString *newSubtitle;
    
    if (annotInd == 0) {
        newSubtitle = [NSString stringWithFormat:@"%d:: starting point", annotInd+1];
    }
    else {
        double totalDist = [appDelegate.measModel convertDistance:annot.totalDistanceMeters power:1];
        double deltaDist = [appDelegate.measModel convertDistance:annot.deltaDistanceMeters power:1];
        
        NSString *unitStr = [appDelegate.measModel getUnitStr];
        newSubtitle = [NSString stringWithFormat:@"%d:: ∑: %.2f %@, Δ: %.2f %@", annotInd+1, totalDist, unitStr, deltaDist, unitStr];
        
        // NSLog(@"inside else:: title: %@, subtitle: %@", newTitle, newSubtitle);
    }
    
    NSLog(@"title: %@, subtitle: %@", newTitle, newSubtitle);
    
    annot.title = newTitle;
    annot.subtitle = newSubtitle;
    
}

-(void) updateAllAnnotations {
    
    int originalMappingMode = appDelegate.measModel.mappingMode;
    
    [self updateMappingModeTo:MAP_MODE_MEAS];
    for (MapPoint *annot in appDelegate.measModel.coordinatePoints) {
        [self updateAnnotationTitle:annot];
    }
    
    
    [self updateMappingModeTo:MAP_MODE_HYBRID];
    double accumPathDist = 0;
    for (MapPoint *annot in appDelegate.measModel.hybridPoints) {
        accumPathDist += annot.deltaDistanceMeters;
        annot.totalDistanceMeters = accumPathDist;
        [self updateRouteAnnotationTitle:annot addResult:1 mappingMode:appDelegate.measModel.mappingMode];
    }
    
    [self updateMappingModeTo:originalMappingMode];
    
    MKUserLocation *blueDot = [self.mapView userLocation];
    
    [blueDot setTitle:[appDelegate.measModel getLatLonStr:blueDot.coordinate.latitude longitude:blueDot.coordinate.longitude shortVersion:1]];
    [blueDot setSubtitle:@"current location"];
}

# pragma mark line drawing for measure mode

-(int) drawNewPolyline:(MapPoint *) annot {
    return [self drawNewPolyline:annot isNewMapPoint:1];
}

-(int) drawNewPolyline:(MapPoint *) annot isNewMapPoint:(int) isNewMapPoint {
    int numPoints = [appDelegate.measModel.hybridPoints count];
    
    annot.mappingModeWhenPlaced = MAP_MODE_HYBRID;
    annot.pathTypeFromPrevPoint = HYBRID_PATH_LINE;
    
    if (numPoints == 0 && isNewMapPoint == 1) {
        [appDelegate.measModel.hybridPoints addObject:annot];
        [self.mapView addAnnotation:annot];
        return 0;
    }
    
    if (isNewMapPoint == 1) {
        [appDelegate.measModel.hybridPoints addObject:annot];
        [self.mapView addAnnotation:annot];
    }
    
    MapPoint *oldAnnot;
    
    int annotInd = [appDelegate.measModel.hybridPoints indexOfObject:annot];
    
    oldAnnot = [appDelegate.measModel.hybridPoints objectAtIndex:annotInd-1];
    double dist = [appDelegate.measModel distanceBetweenMapPoints:annot oldMapPoint:oldAnnot];
    
    CLLocationCoordinate2D coordinatesToDraw[2];
    coordinatesToDraw[0] = [oldAnnot coordinate];
    coordinatesToDraw[1] = [annot coordinate];
    
    MKPolyline *line = [MKPolyline polylineWithCoordinates:coordinatesToDraw count:2];
    
    annot.deltaDistanceMeters = dist;
    annot.lineFromPrevPoint = line;
    
    double accumDist = 0;
    
    for (MapPoint *prevPoint in appDelegate.measModel.hybridPoints) {
        accumDist += prevPoint.deltaDistanceMeters;
        prevPoint.totalDistanceMeters = accumDist;
    }
    // annot.totalDistanceMeters = accumDist + dist;
    
    
    [self.mapView addOverlay:annot.lineFromPrevPoint];
    
    return 1;
}

-(void) drawCurrentPolyline {
    
    if (appDelegate.measModel.currentPolyline != nil) {
        [self.mapView removeOverlay:appDelegate.measModel.currentPolyline];
    }
    
    if (appDelegate.measModel.currentPolygon != nil) {
        [self.mapView removeOverlay:appDelegate.measModel.currentPolygon];
    }
    
    int numPoints = [appDelegate.measModel.coordinatePoints count];
    
    if (numPoints <= 1)
        return;
    
    CLLocationCoordinate2D coordinatesToDraw[numPoints];
    
    for (int i=0; i<numPoints; i++) {
        coordinatesToDraw[i] = [[appDelegate.measModel.coordinatePoints objectAtIndex:i] coordinate];
    }
    
    MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coordinatesToDraw count:numPoints];
    
    appDelegate.measModel.currentPolyline = polyline;
    
    [self.mapView addOverlay:polyline];
}


-(void) drawCurrentPolygon {
    if (appDelegate.measModel.currentPolygon != nil) {
        [self.mapView removeOverlay:appDelegate.measModel.currentPolygon];
    }
    
    if (appDelegate.measModel.currentPolyline != nil) {
        [self.mapView removeOverlay:appDelegate.measModel.currentPolyline];
    }
    
    int numCoordinates = [appDelegate.measModel.coordinatePoints count];
    CLLocationCoordinate2D coordinatesToDraw[numCoordinates];
    int i=0;
    for (MapPoint *annot in appDelegate.measModel.coordinatePoints) {
        coordinatesToDraw[i] = [annot coordinate];
        i++;
    }
    MKPolygon *polygon = [MKPolygon polygonWithCoordinates:coordinatesToDraw count:numCoordinates];
    [self.mapView addOverlay:polygon];
    
    // put into measModel as current polygon
    appDelegate.measModel.currentPolygon = polygon;
}

# pragma mark line drawing for measure mode

-(int) drawCurrentRouteLine:(MapPoint *) newRoutePoint {
    return [self drawCurrentRouteLine:newRoutePoint isNewPoint:1];
}

// *** update this part ***
-(int) drawCurrentRouteLineWithActivity:(MapPoint *)newRoutePoint isNewPoint:(int)isNewPoint withActivity:(int)withActivity {
    if (withActivity == 1) {
        routeBlockDone = 0;
        block_t annotationBlock = ^{
            NSLog(@"running drawCurrentRouteLine");
            currentRouteLineReturnVal = [self drawCurrentRouteLine:newRoutePoint isNewPoint:isNewPoint];
            NSLog(@"return value from drawCurrentRouteLine inside block: %d", currentRouteLineReturnVal);
            routeBlockDone = 1;
        };
        [self runCodeBlockWithActivityInd:annotationBlock];
        NSLog(@"return value from drawCurrentRouteLine outside block: %d", currentRouteLineReturnVal);
        
        /*
         while (routeBlockDone != 1) {
         // block
         }
         routeBlockDone = 0;
         */
        
        return currentRouteLineReturnVal;
        
        
        /*
         [self.activityInd startAnimating];
         self.messageLabel.hidden = YES;
         
         currentRouteLineReturnVal = [self drawCurrentRouteLine:newRoutePoint isNewPoint:isNewPoint];
         
         [self.activityInd stopAnimating];
         self.messageLabel.hidden = NO;
         
         return currentRouteLineReturnVal;
         */
    }
    else {
        return [self drawCurrentRouteLine:newRoutePoint isNewPoint:isNewPoint];
    }
}

// think about consolidating with drawNewPolyline

-(int) drawCurrentRouteLine:(MapPoint *)newRoutePoint isNewPoint:(int)isNewPoint {
    int mappingMode = appDelegate.measModel.mappingMode;
    NSMutableArray *points = nil;
    if (mappingMode == 1) {
        points = appDelegate.measModel.routePoints;
    }
    else if (mappingMode == MAP_MODE_HYBRID) {
        points = appDelegate.measModel.hybridPoints;
    }
    
    int numPoints = [points count];
    
    newRoutePoint.mappingModeWhenPlaced = MAP_MODE_HYBRID;
    newRoutePoint.pathTypeFromPrevPoint = HYBRID_PATH_ROUTE;
    
    if (numPoints == 0 && isNewPoint == 1) {
        // NSLog(@"adding first route point");
        [points addObject:newRoutePoint];
        [self.mapView addAnnotation:newRoutePoint];
        
        [self updateAllAnnotations];  // added 2-15-12
        [self updateMessageBarRoute:0];
        return 0;
    }
    
    MapPoint *oldRoutePoint;
    
    if (isNewPoint == 1) {
        // if it's a new route point, it's not in the array, so the oldRoutePoint is the last object in the array
        oldRoutePoint = [points lastObject];
    }
    else {
        // if it's not a new route point, it's already in the array
        int pointInd = [points indexOfObject:newRoutePoint];
        if (pointInd == 0) {
            // if the index is 0, then the line doesn't need to be drawn.  the next one will take care of it.
            //NSLog(@"return from drawCurrentRouteLine");
            [self updateAllAnnotations];  // added 2-15-12
            [self updateMessageBarRoute:0];
            return 0;
        }
        else {
            // if the index is not 0, the oldRoutePoint is the previous point
            oldRoutePoint = [points objectAtIndex:pointInd-1];
        }
    }
    
    double pathDistance = [appDelegate.measModel distanceRouteBetweenMapPoints:newRoutePoint oldMapPoint:oldRoutePoint];
    NSLog(@"path distance: %f", pathDistance);
    
    if (pathDistance == -1) {
        NSLog(@"routeLine is nil, exiting drawCurrentRouteLine");
        [self updateAllAnnotations];  // added 2-15-12
        [self updateMessageBarRoute:-1];
        return -1;
    }
    else {
        NSLog(@"routeLine found");
    }
    
    newRoutePoint.deltaDistanceMeters = pathDistance;
    
    if (isNewPoint == 1) {
        [points addObject:newRoutePoint];
        [self.mapView addAnnotation:newRoutePoint];
    }
    
    // update and accumulate total distance for each point
    double accumPathDist = 0;
    for (MapPoint *prevRoutePoint in points) {
        accumPathDist += prevRoutePoint.deltaDistanceMeters;
        prevRoutePoint.totalDistanceMeters = accumPathDist;
    }
    
    [self.mapView addOverlay:newRoutePoint.lineFromPrevPoint];
    
    // NSLog(@"returning from drawCurrentRouteLine at end");
    [self updateAllAnnotations];  // added 2-15-12
    [self updateMessageBarRoute:1];
    return 1;
}

# pragma mark line drawing delegate
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay{
	
	if ([overlay isKindOfClass:[MKPolyline class]]) {
		
		MKPolylineView *polylineView = [[MKPolylineView alloc] initWithPolyline:overlay];
		
        if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) {
            polylineView.strokeColor = [UIColor blueColor];
            polylineView.lineWidth = 3.5;
        }
        if (appDelegate.measModel.mappingMode == 1) {
            polylineView.strokeColor = [UIColor redColor];
            polylineView.lineWidth = 3.5;
        }
        else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
            polylineView.strokeColor = [UIColor purpleColor];
            polylineView.lineWidth = 3.5;
        }
		return [polylineView autorelease];
	}
    
    if ([overlay isKindOfClass:[MKPolygon class]])
        
    {
        MKPolygonView* aView = [[[MKPolygonView alloc] initWithPolygon:(MKPolygon*)overlay] autorelease];
        
        aView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        aView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
        aView.lineWidth = 3;
        
        return aView;
    }
    
	return [[[MKOverlayView alloc] initWithOverlay:overlay] autorelease];
}

# pragma mark update message bar

-(void) updateMessageBarRoute:(int) result {
    NSMutableArray *points = nil;
    if (appDelegate.measModel.mappingMode == 1) {
        points = appDelegate.measModel.routePoints;
    }
    else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
        points = appDelegate.measModel.hybridPoints;
    }
    int numCoordinates = [points count];
    NSString *str;
    if (result == -1) {
        messageLabel.text = @"no route found";
        return;
    }
    else if (numCoordinates == 0) {
        str = [NSString stringWithFormat:@"Press and hold to drop route pin"];
        messageLabel.text = str;
        return;
    }
    else if (numCoordinates == 1) {
        str = [NSString stringWithFormat:@"To move a route pin, select it, then drag."];
        messageLabel.text = str;
        return;
    }
    
    double totalDist = [[points lastObject] totalDistanceMeters];
    NSString *totalStr = @"Route total distance: ";
    totalStr = [totalStr stringByAppendingFormat:@"%@",[appDelegate.measModel getConvertedDistanceStr:totalDist]];
    
    [self.messageLabel setText:totalStr];
}

-(void) updateMessageBar {
    if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) {
        [self updateMessageBarMeasure];
    }
    else if (appDelegate.measModel.mappingMode == 1 || appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
        [self updateMessageBarRoute:1];
    }
}

-(void) updateMessageBarMeasure {
    int numCoordinates = [appDelegate.measModel.coordinatePoints count];
    if (numCoordinates == 0) {
        NSString *str = [NSString stringWithFormat:@"Press and hold to drop a pin"];
        [self.messageLabel setText:str];
        return;
    }
    
    if (numCoordinates == 1) {
        NSString *str = [NSString stringWithFormat:@"To move a pin, select it, then drag to place at pin's tip"];
        [self.messageLabel setText:str];
        return;
    }
    
    double convertedDist = 0;
    NSString *unitStr;
    if (appDelegate.measModel.mode == 0) {
        // convertedDist = appDelegate.measModel.accumDistanceMeters;
        // convertedDist = [appDelegate.measModel accumDistanceMetersForAnnot:[appDelegate.measModel.coordinatePoints lastObject]];
        convertedDist = [[appDelegate.measModel.coordinatePoints lastObject] totalDistanceMeters];
    }
    else if (appDelegate.measModel.mode == 1) {
        appDelegate.measModel.accumAreaMetersSq = [appDelegate.measModel currentArea];
        convertedDist = appDelegate.measModel.accumAreaMetersSq;
    }
    
    unitStr = [appDelegate.measModel getUnitStr];
    
    NSString *totalStr = nil;
    if (appDelegate.measModel.mode == 0) {
        // distance mode
        convertedDist = [appDelegate.measModel convertDistance:convertedDist power:1];
        if (appDelegate.measModel.unitSelection <= 4) {
            totalStr = [NSString stringWithFormat:@"Total Distance: %.2f %@", convertedDist, unitStr];
        }
        else {
            totalStr = [NSString stringWithFormat:@"Total Distance: %.2f root %@", convertedDist, unitStr];
        }
    }
    else if (appDelegate.measModel.mode == 1) {
        // area mode
        convertedDist = [appDelegate.measModel convertDistance:convertedDist power:2];
        if (appDelegate.measModel.unitSelection <= 4) {
            totalStr= [NSString stringWithFormat:@"Total Area: %.2f square %@", convertedDist, unitStr];
        }
        else {
            totalStr= [NSString stringWithFormat:@"Total Area: %.2f %@", convertedDist, unitStr];
        }
    }
    [self.messageLabel setText:totalStr];
}

# pragma mark search bar
-(void) showSearchBar {
    //NSLog(@"showing search bar");
    
    [self dismissPinListPopoverController];
    [self dismissDetailPopoverController];
    
    if (searchBar == nil) {
        
        searchBar = [[[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 65)] autorelease];
        searchBar.delegate = self;
        
        [searchBar setShowsCancelButton:YES animated:YES];
        searchBar.placeholder = @"Search or address";
        
        [searchBar becomeFirstResponder];
        
        searchBarView = [[[UIView alloc] initWithFrame:searchBar.frame] autorelease];
        [searchBarView addSubview:searchBar];
        [self.view addSubview:searchBarView];
    }
    else {
        searchBarView.hidden = NO;
        [searchBar becomeFirstResponder];
    }
    
    recognizer.enabled = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)aSearchBar {
    //NSLog(@"search bar cancel pressed");
    [aSearchBar resignFirstResponder];
    [self showNavigationAndMessageBars];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar {
    //NSLog(@"search for text: %@", searchBar.text);
    [aSearchBar resignFirstResponder];
    [self showNavigationAndMessageBars];
    //NSLog(@"search still contains text: %@", searchBar.text);
    //CLLocationCoordinate2D searchLocation = [self addressLocation];
}

- (void) showNavigationAndMessageBars {
    [self.searchBarView setHidden:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.messageView setHidden:NO];
    [self.toggleButton setHidden:NO];
    // messageViewOnScreen = 1;
    // [self toggleMessageViewTo:1];
    
    recognizer.enabled = NO;
}

# pragma mark searching for address

// not used
- (IBAction) showAddress {
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta=0.2;
    span.longitudeDelta=0.2;
    
    CLLocationCoordinate2D location = [self addressLocation];
    
    region.span=span;
    region.center=location;
    [self.mapView setRegion:region animated:TRUE];
    [self.mapView regionThatFits:region];
}

-(CLLocationCoordinate2D) addressLocation {
    NSString *urlString = [NSString stringWithFormat:@"http://maps.google.com/maps/geo?q=%@&output=csv", [searchBar.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *locationString = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString] usedEncoding:NSUTF8StringEncoding error:nil];
    NSArray *listItems = [locationString componentsSeparatedByString:@","];
    
    double latitude = 0.0;
    double longitude = 0.0;
    
    int zoomLevel = 1;
    
    CLLocationCoordinate2D location;
    
    if([listItems count] >= 4 && [[listItems objectAtIndex:0] isEqualToString:@"200"]) {
        latitude = [[listItems objectAtIndex:2] doubleValue];
        longitude = [[listItems objectAtIndex:3] doubleValue];
        NSLog(@"google listItems[1]: %@", [listItems objectAtIndex:1]);
        self.messageLabel.text = self.searchBar.text;
        // searchSuccesful = 1;
        zoomLevel = [[listItems objectAtIndex:1] intValue] + 5;
    }
    else {
        //Show error
        self.messageLabel.text = @"no search results found";
        return location;
        // searchSuccesful = 0;
    }
    
    location.latitude = latitude;
    location.longitude = longitude;
    
    //[self setCentreCoordinate:location zoomScale:zoomLevel animated:YES];
    
    [self setCenterCoordinate:location zoomLevel:zoomLevel animated:YES];
    
    BOOL val = [[NSUserDefaults standardUserDefaults] boolForKey:@"dropSearchPin"];
    if (val) {
        MapPoint *annot = [[MapPoint alloc] initWithCoordinate:location title:@"tap coordinate"  subtitle:@"subtitle"];
        if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) {
            [self addAnnotationToMap:annot];
        }
        else if (appDelegate.measModel.mappingMode == MAP_MODE_HYBRID) {
            [self addHybridAnnotationToMap:annot];
        }
    }
    
    return location;
}

# pragma mark activity indicator
-(UIActivityIndicatorView *) activityIndicator:(CGRect) frame {
    if (self.activityInd == nil) {
        self.activityInd = [[UIActivityIndicatorView alloc] initWithFrame:frame];
    }
    return self.activityInd;
}

# pragma mark KML parser

- (NSString *)dataFilePath {
    return appDelegate.kmlManager.filePathToLoad;
}

-(void) writeKMLFile {
    //KMLWriter *writer = [[KMLWriter alloc] init];
    //NSData *data = [writer xmlDataFromRequest];
    //[writer release];
}

-(void) loadKML {
    
    NSString *path = [self dataFilePath];
    kml = [[KMLParser parseKMLAtPath:path] retain];
    
    // [self mapClearAll];
    [self mapClearAllMeasurements];
    [self mapClearAllRoutes];
    
    // Add all of the MKOverlay objects parsed from the KML file to the map.
    // NSArray *overlays = [kml overlays];
    // [self.mapView addOverlays:overlays];
    
    // Add all of the MKAnnotation objects parsed from the KML file to the map.
    NSArray *annotations = [kml points];
    
    NSArray *pointNames = [kml pointNames];
    
    // point names format:
    // i, mp.mappingModeWhenPlaced, mp.pathTypeFromPrevPoint
    
    NSMutableArray *measurePoints = [[[NSMutableArray alloc] init] autorelease];
    NSMutableArray *hybridPoints = [[[NSMutableArray alloc] init] autorelease];
    
    for (int i=0; i<[pointNames count]; i++) {
        NSString *ptName = [pointNames objectAtIndex:i];
        // NSLog(@"ptName: %@", ptName);
        NSArray *nums = [ptName componentsSeparatedByString:@","];
        
        /*
         if ([nums count] < 3) {
         continue;
         }
         */
        
        CLLocationCoordinate2D coord = [[annotations objectAtIndex:i] coordinate];
        MapPoint *annot = [[[MapPoint alloc] initWithCoordinate:coord title:@"tap coordinate"  subtitle:@"subtitle"] autorelease];
        
        if ([nums count] < 3) {
            annot.mappingModeWhenPlaced = MAP_MODE_MEAS;
            annot.pathTypeFromPrevPoint = HYBRID_PATH_LINE;
        }
        else {
            annot.mappingModeWhenPlaced = [[nums objectAtIndex:1] integerValue];
            annot.pathTypeFromPrevPoint = [[nums objectAtIndex:2] integerValue];
        }
        
        if (annot.mappingModeWhenPlaced == MAP_MODE_MEAS) {
            [measurePoints addObject:annot];
        }
        else if (annot.mappingModeWhenPlaced == MAP_MODE_HYBRID) {
            [hybridPoints addObject:annot];
        }
    }
    
    // appDelegate.measModel.mappingMode = MAP_MODE_MEAS;
    [self updateMappingModeTo:MAP_MODE_MEAS];
    for (MapPoint *annot in measurePoints) {
        // NSLog(@"calling addAnnotationToMap in loadKML");
        [self addAnnotationToMap:annot];
    }
    
    // appDelegate.measModel.mappingMode = MAP_MODE_HYBRID;
    // [self updateMappingMode];
    [self updateMappingModeTo:MAP_MODE_HYBRID];
    for (MapPoint *annot in hybridPoints) {
        if (annot.pathTypeFromPrevPoint == HYBRID_PATH_LINE) {
            appDelegate.measModel.hybridPathMode = HYBRID_PATH_LINE;
        }
        else if (annot.pathTypeFromPrevPoint == HYBRID_PATH_ROUTE) {
            appDelegate.measModel.hybridPathMode = HYBRID_PATH_ROUTE;
        }
        NSLog(@"calling addHybridAnnotationToMap in loadKML");
        // changed 2-13-12
        [self addHybridAnnotationToMap:annot isNewPoint:1 withActivity:0];
    }
    
    //[self updateMappingMode];
    [self updateMappingModeTo:MAP_MODE_MEAS];
    
    // Walk the list of overlays and annotations and create a MKMapRect that
    // bounds all of them and store it into flyTo.
    
    MKMapRect flyTo = MKMapRectNull;
    /*
     for (id <MKOverlay> overlay in overlays) {
     if (MKMapRectIsNull(flyTo)) {
     flyTo = [overlay boundingMapRect];
     } else {
     flyTo = MKMapRectUnion(flyTo, [overlay boundingMapRect]);
     }
     }
     */
    
    
    for (id <MKAnnotation> annotation in annotations) {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        if (MKMapRectIsNull(flyTo)) {
            flyTo = pointRect;
        } else {
            flyTo = MKMapRectUnion(flyTo, pointRect);
        }
    }
    
    // Position the map so that all overlays and annotations are visible on screen.
    self.mapView.visibleMapRect = flyTo;
    
}

# pragma mark button presses

-(void) testPrint:(int)val {
    NSLog(@"print testPrint: %d", val);
}

-(void) presentInstructionsView {
    NSLog(@"present instructions");
    
    InstructionsController *instructions = [[InstructionsController alloc] initWithNibName:@"InstructionsController" bundle:nil];
    
    if ([appDelegate iPad] == YES) {
        instructions.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:instructions animated:YES completion:nil];
        instructions.view.superview.frame = CGRectMake(0, 0, 320, 461);
        instructions.view.superview.center = self.view.center;
    }
    else {
        [self presentViewController:instructions animated:YES completion:nil];
    }
    
    [instructions release];
}

-(void) toggleMessageViewTo:(int) onFlag {
    // NSLog(@"setting messageViewTo:: onFlag: %d, messageViewOnScreen: %d", onFlag, messageViewOnScreen);
    if (messageViewOnScreen != onFlag) {
        [self toggleMessageView];
    }
    // NSLog(@"messageViewOnScreen new value: %d", messageViewOnScreen);
}

-(void) toggleMessageView {
    // NSLog(@"1 toggle message view:: messageViewOnScreen: %d", messageViewOnScreen);
    
    messageViewOnScreen = !messageViewOnScreen;
    
    // NSLog(@"2 toggle message view:: messageViewOnScreen: %d", messageViewOnScreen);
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                         // messageView.hidden = !messageView.hidden;
                         if (messageViewOnScreen == 1) {
                             [messageView setFrame:CGRectMake(0, 0, messageViewSize.width, messageViewSize.height)];
                         }
                         else {
                             [messageView setFrame:CGRectMake(0, -60, messageViewSize.width, messageViewSize.height)];
                         }
                     }
                     completion:nil];
    
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationCurveEaseInOut
                     animations:^{
                         if (messageViewOnScreen == 1) {
                             toggleButton.transform = CGAffineTransformMakeRotation(0);
                             [toggleButton setFrame:CGRectMake(toggleButtonLocation.x, toggleButtonLocation.y, toggleButtonSize.width, toggleButtonSize.height)];
                         }
                         else {
                             toggleButton.transform = CGAffineTransformMakeRotation(-M_PI);
                             [toggleButton setFrame:CGRectMake(toggleButtonLocation.x, 0, toggleButtonSize.width, toggleButtonSize.height)];
                         }
                     }
                     completion:nil];
}

-(void) testSearch {
    NSLog(@"testSearch start");
    // hide navigation bar and message view
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.messageView setHidden:YES];
    [self.toggleButton setHidden:YES];
    // show search bar
    [self showSearchBar];
}

-(void) gotoCurrentLocationWithTimer:(NSTimer *) timer {
    //NSLog(@"calling gotoCurrentLocationWithTimer");
    if (appDelegate.measModel.mappingMode == MAP_MODE_MEAS) {
        [self gotoCurrentLocation];
    }
}

-(void) gotoCurrentLocation {
    NSLog(@"start updating location");
    [locationManager startUpdatingLocation];
    // lookingForLocation = 1;
    
    if (coreLocationFailed == 0) {
        self.messageLabel.hidden = YES;
        self.activityInd.hidden = NO;
        [activityInd startAnimating];
    }
    else {
        messageLabel.text = @"current location not available";
    }
    
    
    if ([self.mapView isUserLocationVisible] == NO) {
        NSLog(@"allow location manager more time to get current location");
        // messageLabel.text = @"acquiring location";
        
        [self.mapView setShowsUserLocation:YES];
        waitForCurrentLocationTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(doneWaiting) userInfo:nil repeats:NO];
        // sleep(3);
    }
    else {
        NSLog(@"pan to current location");
        [self.mapView setShowsUserLocation:YES];
    }
    
    
     NSLog(@"pan to current location");
     [self.mapView setShowsUserLocation:YES];
}

-(void) doneWaiting {
    // NSLog(@"---- doneWaiting timer fired ------");
    doneWaitingForLocationAquire = 1;
    [waitForCurrentLocationTimer invalidate];
    waitForCurrentLocationTimer = nil;
}

-(void) openOptionsMenu {
    if (optionsPopoverOn == 1) {
        [self dismissOptionsPopoverController];
    }
    
    Options *optionsViewController = [[Options alloc] initWithNibName:@"Options" bundle:nil];
    optionsViewController.delegate = self;
    
    if ([appDelegate iPad] == YES) {
        
        if (pinListPopoverOn == 1) {
            [optionsViewController release];
            // remember to release where necessary
            [self.optionsPopover dismissPopoverAnimated:YES];
            [self popoverControllerDidDismissPopover:optionsPopover];
            return;
        }
        
        optionsPopoverOn = 1;
        
        UINavigationController *optionListNav = [[UINavigationController alloc] initWithRootViewController:optionsViewController];
        
        optionsPopover = [[UIPopoverController alloc] initWithContentViewController:optionListNav];
        
        [optionsPopover setPopoverContentSize:CGSizeMake(320, 960)];
        
        optionsPopover.delegate = self;
        [optionsPopover presentPopoverFromBarButtonItem:listButton
                               permittedArrowDirections:UIPopoverArrowDirectionUp
                                               animated:YES];
    }
    else {
        [self.navigationController pushViewController:optionsViewController animated:YES];
    }
    
    [optionsViewController release];
}

// this is a popoverController delegate method
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    
    if (popoverController == optionsPopover) {
        optionsPopoverOn = 0;
        
        [optionsPopover release];
        optionsPopover = nil;
        
        [self viewWillAppear:NO];
        [self viewDidAppear:NO];
    }
    
    if (popoverController == pinListPopover) {
        pinListPopoverOn = 0;
        
        [pinListPopover release];
        pinListPopover = nil;
    }
    
    if (popoverController == detailPopover) {
        detailPopoverOn = 0;
        
        [detailPopover release];
        detailPopover = nil;
    }
}

-(void) dismissOptionsPopoverController {
    [self.optionsPopover dismissPopoverAnimated:YES];
    [self popoverControllerDidDismissPopover:self.optionsPopover];
}

-(void) openPinListTable {
    
    if (detailPopoverOn == 1) {
        [self dismissDetailPopoverController];
    }
    
    PinListTable *pinList = [[PinListTable alloc] initWithNibName:@"PinListTable" bundle:nil];
    pinList.delegate = self;
    
    if ([appDelegate iPad] == YES) {
        
        if (pinListPopoverOn == 1) {
            [pinList release];
            // remember to release where necessary
            [self.pinListPopover dismissPopoverAnimated:YES];
            [self popoverControllerDidDismissPopover:pinListPopover];
            return;
        }
        
        pinListPopoverOn = 1;
        
        UINavigationController *pinListNav = [[UINavigationController alloc] initWithRootViewController:pinList];
        
        pinListPopover = [[UIPopoverController alloc] initWithContentViewController:pinListNav];
        
        [pinListPopover setPopoverContentSize:CGSizeMake(320, 960)];
        
        pinListPopover.delegate = self;
        [pinListPopover presentPopoverFromBarButtonItem:listButton
                               permittedArrowDirections:UIPopoverArrowDirectionUp
                                               animated:YES];
    }
    else {
        [self.navigationController pushViewController:pinList animated:YES];
    }
    
    [pinList release];
}

-(void) dismissPinListPopoverController {
    if (pinListPopoverOn == 1) {
        [self.pinListPopover dismissPopoverAnimated:YES];
        [self popoverControllerDidDismissPopover:pinListPopover];
    }
}

-(void) processDetailAnnotationView:(MapPoint *) mp {
    
    if (searchBarView.hidden == NO) {
        [self searchBarCancelButtonClicked:searchBar];
    }
    
    detailAnnotationView *view = [[detailAnnotationView alloc] init];
    view.mp = mp;
    if ([appDelegate iPad] == YES) {
        
        detailPopoverOn = 1;
        UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:view];
        detailPopover = [[UIPopoverController alloc] initWithContentViewController:detailNav];
        
        [detailPopover setPopoverContentSize:CGSizeMake(320, 960)];
        
        detailPopover.delegate = self;
        [detailPopover presentPopoverFromBarButtonItem:listButton
                              permittedArrowDirections:UIPopoverArrowDirectionAny
                                              animated:YES];
    }
    else {
        [self.navigationController pushViewController:view animated:YES];
    }
    
    [view release];
}

-(void) dismissDetailPopoverController {
    if (detailPopoverOn == 1) {
        [self.detailPopover dismissPopoverAnimated:YES];
        [self popoverControllerDidDismissPopover:detailPopover];
    }
}

/*
 - (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
 if (popoverController == pinListPopover) {
 return YES;
 }
 else {
 return YES;
 }
 }
 */

# pragma mark stuff for zoom level

#define MERCATOR_OFFSET 268435456
#define MERCATOR_RADIUS 85445659.44705395

- (double)longitudeToPixelSpaceX:(double)longitude
{
    return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * M_PI / 180.0);
}

- (double)latitudeToPixelSpaceY:(double)latitude
{
    return round(MERCATOR_OFFSET - MERCATOR_RADIUS * logf((1 + sinf(latitude * M_PI / 180.0)) / (1 - sinf(latitude * M_PI / 180.0))) / 2.0);
}

- (double)pixelSpaceXToLongitude:(double)pixelX
{
    return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / M_PI;
}

- (double)pixelSpaceYToLatitude:(double)pixelY
{
    return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / M_PI;
}

- (MKCoordinateSpan)coordinateSpanWithMapView:(MKMapView *)aMapView
                             centerCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                 andZoomLevel:(NSUInteger)zoomLevel
{
    // convert center coordiate to pixel space
    double centerPixelX = [self longitudeToPixelSpaceX:centerCoordinate.longitude];
    double centerPixelY = [self latitudeToPixelSpaceY:centerCoordinate.latitude];
    
    // determine the scale value from the zoom level
    NSInteger zoomExponent = 20 - zoomLevel;
    double zoomScale = pow(2, zoomExponent);
    
    // scale the map’s size in pixel space
    CGSize mapSizeInPixels = aMapView.bounds.size;
    double scaledMapWidth = mapSizeInPixels.width * zoomScale;
    double scaledMapHeight = mapSizeInPixels.height * zoomScale;
    
    // figure out the position of the top-left pixel
    double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
    double topLeftPixelY = centerPixelY - (scaledMapHeight / 2);
    
    // find delta between left and right longitudes
    CLLocationDegrees minLng = [self pixelSpaceXToLongitude:topLeftPixelX];
    CLLocationDegrees maxLng = [self pixelSpaceXToLongitude:topLeftPixelX + scaledMapWidth];
    CLLocationDegrees longitudeDelta = maxLng - minLng;
    
    // find delta between top and bottom latitudes
    CLLocationDegrees minLat = [self pixelSpaceYToLatitude:topLeftPixelY];
    CLLocationDegrees maxLat = [self pixelSpaceYToLatitude:topLeftPixelY + scaledMapHeight];
    CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);
    
    // create and return the lat/lng span
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    return span;
}

- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated
{
    // clamp large numbers to 28
    zoomLevel = MIN(zoomLevel, 28);
    
    // use the zoom level to compute the region
    MKCoordinateSpan span = [self coordinateSpanWithMapView:self.mapView centerCoordinate:centerCoordinate andZoomLevel:zoomLevel];
    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
    
    // set the region like normal
    [self.mapView setRegion:region animated:animated];
}

/*
 - (void)setCentreCoordinate:(CLLocationCoordinate2D)centreCoordinate zoomScale:(double)zoomScale animated:(BOOL)animated
 {
 [self.mapView setVisibleMapRect:[self mapRectWithCentreCoordinate:centreCoordinate zoomScale:zoomScale] animated:animated];
 }
 */


# pragma mark more view lifecycle stuff

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
