//
//  MeasModel.m
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MeasModel.h"

@implementation MeasModel

@synthesize coordinatePoints, accumDistanceMeters, accumAreaMetersSq, mapTypeSelection, unitSelection, erasedPoints, mode, currentPolygon, currentPolyline, routePoints, routeErasedPoints, mappingMode, hybridPathMode, hybridPoints, hybridErasedPoints, trackingSecs; 

- (id) init {
    [super init];
    coordinatePoints = [[NSMutableArray alloc] init];
    // lines = [[NSMutableArray alloc] init];  // no longer used
    erasedPoints = [[NSMutableArray alloc] init];
    // deltaDistMetersArray = [[NSMutableArray alloc] init]; // no longer used
    
    routePoints = [[NSMutableArray alloc] init];
    // routeLines = [[NSMutableArray alloc] init];
    routeErasedPoints = [[NSMutableArray alloc] init];
    // routeDeltaMeters = [[NSMutableArray alloc] init];
    
    hybridPathMode = 0;
    hybridPoints = [[NSMutableArray alloc] init];
    hybridErasedPoints = [[NSMutableArray alloc] init];
    
    dFinder = [[LMDirectionFinder alloc] init];
    
    currentPolygon = nil; 
    currentPolyline = nil;
        
    mappingMode = 0;
    mode = 0; 
    accumAreaMetersSq = 0; 
    
    mapTypeSelection = 0;
    unitSelection = 2;  // initialize to miles
    
    trackingSecs = 15;
    
    // NSLog(@"measModel init:: mapTypeSelection: %d", mapTypeSelection);
    
    return self;
}

-(void) dealloc 
{
    [coordinatePoints release];
    // [lines release];
    [erasedPoints release];
    // [deltaDistMetersArray release];
    [super dealloc];
}

# pragma mark points for mode
-(NSArray *) getPointsForMode {
    NSArray *points = nil;
    if (mappingMode == MAP_MODE_MEAS) {
        points = coordinatePoints;
    }
    else if (mappingMode == MAP_MODE_HYBRID) {
        points = hybridPoints;
    }
    return points;
}

# pragma mark image resize
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();
    return newImage;
}

# pragma mark conversions

-(double) convertMToKm:(double) val power:(double) powVal {
    return val * pow(0.001, powVal) ; 
}

-(double) convertMToFt:(double) val power:(double) powVal {
    return val * pow(3.2808399, powVal);
}

-(double) convertMToYds:(double) val power:(double) powVal {
    return val * pow(1.0936133, powVal);
}

-(double) convertMToMi:(double) val power:(double) powVal {
    return val * pow(0.000621371192, powVal);
}

// with power 1, this conversion is to root acres
-(double) convertMToAcres:(double) val power:(double) powVal {
    return val * pow(0.0157195859, powVal);
}

// with power 1, this conversion is to root hectares
-(double) convertMToHectares:(double) val power:(double) powVal {
    return val * pow(0.01, powVal);
}

// dist is in meters
-(double) convertDistance:(double) dist power:(double) powVal {
    // NSLog(@"unit selection: %d", unitSelection);
    double convertedDist = 0;
    switch (unitSelection) {
        case 0:
            convertedDist = dist;
            break;
        case 1:
            convertedDist = [self convertMToKm:dist power:powVal];
            break;
        case 2:
            convertedDist = [self convertMToMi:dist power:powVal];
            break;
        case 3:
            convertedDist = [self convertMToYds:dist power:powVal];
            break;
        case 4:
            convertedDist = [self convertMToFt:dist power:powVal];
            break;
        case 5:
            convertedDist = [self convertMToAcres:dist power:powVal];
            break;
        case 6:
            convertedDist = [self convertMToHectares:dist power:powVal];
            break;
        default:
            break;
    }
    return convertedDist; 
}

-(NSString *) getUnitStr {
    // NSLog(@"str unit selection: %d", unitSelection);
    NSString *unitStr = nil; 
    switch (unitSelection) {
        case 0:
            unitStr = UNIT_M;
            break;
        case 1:
            unitStr = UNIT_KM;
            break;
        case 2:
            unitStr = UNIT_MI;
            break;
        case 3:
            unitStr = UNIT_YDS;
            break;
        case 4:
            unitStr = UNIT_FT;
            break;
        case 5:
            unitStr = UNIT_ACRES;
            break;
        case 6:
            unitStr = UNIT_HECTARES;
            break;
        default:
            break;
    }
    return [unitStr autorelease]; 
}

-(NSString *) getConvertedDistanceStr:(double) dist {
    double convertedDist = dist; 
    NSString *unitStr;
    unitStr = [self getUnitStr];
    
    NSString *totalStr;
    convertedDist = [self convertDistance:convertedDist power:1];
    totalStr = [NSString stringWithFormat:@"%.2f %@", convertedDist, unitStr];
    return totalStr;
}

-(NSString *) getLatLonStr:(double) lat longitude:(double) lon {
    return [self getLatLonStr:lat longitude:lon shortVersion:0];
}

-(NSString *) getLatLonStr:(double) lat longitude:(double) lon shortVersion:(int)shortVersion {
    BOOL coordsInDegrees = [[NSUserDefaults standardUserDefaults] boolForKey:@"coordsDegrees"];
    NSString *str; 
    if (coordsInDegrees == YES) {
        // int degValLat = 
        if (shortVersion == 1) {
            str = [NSString stringWithFormat:@"%@, %@", [self convertToDegrees:lat shortVersion:shortVersion], [self convertToDegrees:lon shortVersion:shortVersion]];
        }
        else {
            str = [NSString stringWithFormat:@"%@, %@", [self convertToDegrees:lat], [self convertToDegrees:lon]];
        }
    }
    else {
        if (shortVersion == 1)
            str = [NSString stringWithFormat:@"lat: %.4f, lon: %.4f", lat, lon];
        else
            str = [NSString stringWithFormat:@"lat: %.8f, lon: %.8f", lat, lon];
    }
    return str;
}

-(NSString *) convertToDegrees:(double) coordVal {
    return [self convertToDegrees:coordVal shortVersion:0];
}

-(NSString *) convertToDegrees:(double) coordVal shortVersion:(int)shortVersion {
    double sign = 1;
    if (coordVal < 0) {
        sign = -1;
    }
    double absVal = fabs(coordVal);
    double degrees = floor(absVal);
    double decimalVal = absVal - degrees;
    double minutesWithDecimal = decimalVal * 60;
    double minutes = floor(minutesWithDecimal);
    double decimalVal2 = minutesWithDecimal - minutes;
    double seconds = decimalVal2 * 60;
    
    NSString *str;
    if (shortVersion == 1) {
        str = [NSString stringWithFormat:@"%.0f° %.0f' %.0f\"", sign * degrees, minutes, seconds]; 
    }
    else {
        str = [NSString stringWithFormat:@"%.0f° %.0f' %.5f\"", sign * degrees, minutes, seconds]; 
    }
    return str;
}

# pragma mark distance and area calculation

// return value is in meters
-(double) distanceBetweenMapPoints:(MapPoint *) annotNew oldMapPoint:(MapPoint *) annotOld {
    CLLocation *newLocation = [[CLLocation alloc] initWithCoordinate:annotNew.coordinate altitude:1 horizontalAccuracy:1 verticalAccuracy:-1 timestamp:nil];
    CLLocation *oldLocation = [[CLLocation alloc] initWithCoordinate:annotOld.coordinate altitude:1 horizontalAccuracy:1 verticalAccuracy:-1 timestamp:nil];
    double deltaMeters = [newLocation distanceFromLocation:oldLocation];
    [newLocation release];
    [oldLocation release];
    return deltaMeters; 
}

-(double) distanceCumulativeMetersForMapPointArray:(NSMutableArray *) locationPoints {
    // assume that it's an array of MapPoints
    double distanceMeters = 0;
    // CLLocationCoordinate2D
    NSUInteger numPoints = [locationPoints count];
    for (int i=1; i<numPoints; i++) {
        MapPoint *locOld = [locationPoints objectAtIndex:i-1];
        MapPoint *locNew = [locationPoints objectAtIndex:i];
        distanceMeters += [self distanceBetweenMapPoints:locNew oldMapPoint:locOld];
    }
    return distanceMeters;
}


-(void) updateTotalDistance {
    NSUInteger numPoints = [coordinatePoints count];
    if (numPoints <= 1) {
        accumDistanceMeters = 0; 
        // deltaDistMeters = 0;
    }
    else {
        MapPoint *annotNew = [coordinatePoints lastObject];
        accumDistanceMeters = [self accumDistanceMetersForAnnot:annotNew];
    }
}
 

# pragma mark call to LM Direction finder
/**
 
 key: LM_MKPolylineKey
 key: LM_TurnLocationsKey
 key: LM_TurnByTurnKey
 
 Finds directions from one latitude/longitude coordinate to another.
 
 @param from The starting location of the directions
 @param to The ending location of the directions
 @returns NSDictionary with three pieces of information:
 1: An MKPolyline that can be placed on a map. (Key = [LMDirectionFinder mkPolylineKey])
 2: An NSArray of NSStrings that are the list of turn by turn directions. (Key = [LMDirectionFinder turnByTurnDirectionsKey])
 3: An NSArray of NSStrings that are the latitude/longitude of each step in the turn by turn directions list. (Key = [LMDirectionFinder turnLocationsKey])
 *Note: Each latitude and longitude stored in this array are seperate values. The NSArray has the format {latitude, longitude, latitude, longitude, ...}
 */
// - (NSDictionary *)getDirectionsFrom:(CLLocationCoordinate2D)from To:(CLLocationCoordinate2D)to;

// this will calculate the route distance between the two mapPoints, and will also save the MKPolyline of the route into annotNew
-(double) distanceRouteBetweenMapPoints:(MapPoint *) annotNew oldMapPoint:(MapPoint *) annotOld {
    CLLocationCoordinate2D from = [annotOld coordinate];
    CLLocationCoordinate2D to = [annotNew coordinate];
    
    // NSLog(@"calling LM direction finder::\n from: (%.6f, %.6f)\n to: (%.6f, %.6f)", from.latitude, from.longitude, to.latitude, to.longitude);
    
    NSDictionary *routeItems = [dFinder getDirectionsFrom:from To:to];
    
    //key: LM_MKPolylineKey
    //key: LM_TurnLocationsKey
    //key: LM_TurnByTurnKey
    
    MKPolyline *routeLine = [routeItems objectForKey:@"LM_MKPolylineKey"];
    NSArray *pointsForPolyline = [routeItems objectForKey:@"LM_PointsForPolylineKey"];
    //NSArray *turnLocations = [routeItems objectForKey:@"LM_TurnLocationsKey"];
    // NSArray *turnDirections = [routeItems objectForKey:@"LM_TurnByTurnKey"];
    NSArray *distances = [routeItems objectForKey:@"LM_DistancesKey"];
    
    //int runTestPoints = 0;
    //if (runTestPoints == 1) {
    //    CLLocationCoordinate2D fromTest = CLLocationCoordinate2DMake(39.1108, -116.7633);
    //    CLLocationCoordinate2D toTest = CLLocationCoordinate2DMake(30.5745, -97.5265);
        //NSDictionary *testItems = [dFinder getDirectionsFrom:fromTest To:toTest];
    //}
    
    if (routeLine == nil) {
        NSLog(@"routeLine is nil, exiting route distance calculation");
        return -1;
    }
    else {
        // NSLog(@"routeLine found");
    }
    
    // NSLog(@"saving MKPolyline for routeLine to MapPoint");
    annotNew.lineFromPrevPoint = routeLine;
    [annotNew.intermediatePoints removeAllObjects];
    
    // pointsForPolyline contains CLLocation objects
    for (CLLocation *loc in pointsForPolyline) {
        MapPoint *interPoint = [[MapPoint alloc] initWithCoordinate:loc.coordinate title:nil subtitle:nil];
        [annotNew.intermediatePoints addObject:interPoint];
        [interPoint release];
    }
    
    // new calculation for route distance: sum distances returned from google for each step
    double pathDistance = 0;
    for (NSString *interDistStr in distances) {
        pathDistance += [interDistStr doubleValue];
    }
    
    
    return pathDistance;
}


-(double) accumDistanceMetersForAnnot:(MapPoint *) annot {
    NSUInteger annotIndex = [coordinatePoints indexOfObject:annot];
    if (annotIndex == 0) {
        return 0;
    }
    double accumDist = 0;
    for (int i=0; i<annotIndex; i++) {
        MapPoint *annotNew = [coordinatePoints objectAtIndex:i+1];
        MapPoint *annotOld = [coordinatePoints objectAtIndex:i];
        double deltaDist = [self distanceBetweenMapPoints:annotNew oldMapPoint:annotOld];
        accumDist += deltaDist;
        annotNew.deltaDistanceMeters = deltaDist;
        annotNew.totalDistanceMeters = accumDist; 
    }
    return accumDist; 
}

# pragma mark calculate area

- (double) currentArea {
    // take current coordinates and convert them to MKMapPoints
    NSUInteger numPoints = [coordinatePoints count];
    
    if (numPoints <= 2) {
        return 0;
    }
    
    MKMapPoint mkMapPoints[numPoints];
    for (int i=0; i<numPoints; i++) {
        CLLocationCoordinate2D coord = [[coordinatePoints objectAtIndex:i] coordinate];
        mkMapPoints[i] = MKMapPointForCoordinate(coord);
        // NSLog(@"[%.6f, %.6f]", coord.latitude, coord.longitude);
    }
    
    // radius of earth in meters
    double R = 6378137;  
    
    double areaSum = 0;
    for (int i=0; i<numPoints; i++) {
        CLLocationCoordinate2D coord = [[coordinatePoints objectAtIndex:i] coordinate];
        double toRads = (M_PI / 180); 
        double sigma_i = toRads * coord.latitude; 
        double lambda_iPlus1 = 0;
        double lambda_iMinus1 = 0;
        
        CLLocationCoordinate2D coord_iPlus1;
        CLLocationCoordinate2D coord_iMinus1;
        if (i > 0 && i < numPoints - 1) {
            coord_iPlus1 = [[coordinatePoints objectAtIndex:i+1] coordinate];
            coord_iMinus1 = [[coordinatePoints objectAtIndex:i-1] coordinate];
        }
        else if (i == numPoints - 1) {
            coord_iPlus1 = [[coordinatePoints objectAtIndex:0] coordinate];
            coord_iMinus1 = [[coordinatePoints objectAtIndex:i-1] coordinate];
        }
        else if (i == 0) {
            coord_iPlus1 = [[coordinatePoints objectAtIndex:i+1] coordinate];
            coord_iMinus1 = [[coordinatePoints objectAtIndex:numPoints-1] coordinate];
        }
        lambda_iPlus1 = toRads * coord_iPlus1.longitude;
        lambda_iMinus1 = toRads * coord_iMinus1.longitude;
        
        areaSum = areaSum + (lambda_iPlus1 - lambda_iMinus1) * sin(sigma_i);
    }
    
    double area = (pow(R, 2) / 2.0) * fabs(areaSum);
    
    return area; 
}

- (double) currentAreaPixel {
    // take current coordinates and convert them to MKMapPoints
    NSUInteger numPoints = [coordinatePoints count];
    
    if (numPoints <= 2) {
        return 0;
    }
    
    MKMapPoint mkMapPoints[numPoints];
    for (int i=0; i<numPoints; i++) {
        CLLocationCoordinate2D coord = [[coordinatePoints objectAtIndex:i] coordinate];
        mkMapPoints[i] = MKMapPointForCoordinate(coord);
        // NSLog(@"[%.6f, %.6f]", coord.latitude, coord.longitude);
    }
    
    // this is in meters -- use this to convert from pixels into meters

    // find minimum distance to do pixel conversion
    
    /*
    MKMapPoint p1 = mkMapPoints[0];
    MKMapPoint p2 = mkMapPoints[1];
    double dist1_meters = MKMetersBetweenMapPoints(p1, p2);
    double dist1_pixels = sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
    double metersPerPixel = dist1_meters / dist1_pixels; 
    */
    
    double metersPerPixel = 1;
    double minDistance = MAXFLOAT;
    for (int i=0; i<numPoints-1; i++) {
        MKMapPoint p1 = mkMapPoints[i];
        MKMapPoint p2 = mkMapPoints[i+1];
        double dist1_meters = MKMetersBetweenMapPoints(p1, p2);
        if (dist1_meters < minDistance) {
            minDistance = dist1_meters;
            double dist1_pixels = sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
            metersPerPixel = dist1_meters / dist1_pixels; 
            // NSLog(@"new minDistance: %.0f, metersPerPixel: %.6f", minDistance, metersPerPixel);
        }
    }
    
    double numeratorSum = 0;
    
    // use area of polygon formula
    for (int i=0; i<numPoints; i++) {
        // NSLog(@"pixel: [%.6f, %.6f]", mkMapPoints[i].x, mkMapPoints[i].y);
        if (i < numPoints-1) {
            MKMapPoint pt1 = mkMapPoints[i];
            MKMapPoint pt2 = mkMapPoints[i+1];
            numeratorSum += (pt1.x * pt2.y - pt1.y * pt2.x);
        }
        else {
            MKMapPoint pt1 = mkMapPoints[numPoints-1];
            MKMapPoint pt2 = mkMapPoints[0];
            numeratorSum += (pt1.x * pt2.y - pt1.y * pt2.x);
        }
    }
    
    double areaInSqPixels = fabs(numeratorSum) / 2;
    double areaInSqMeters = areaInSqPixels * pow(metersPerPixel, 2);
    
    return areaInSqMeters;
}

@end
