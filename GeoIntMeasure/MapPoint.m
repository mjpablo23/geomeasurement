//
//  MapPoint.m
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MapPoint.h"

@implementation MapPoint

@synthesize coordinate, title, subtitle, totalDistanceMeters, deltaDistanceMeters, lineFromPrevPoint, pathTypeFromPrevPoint, mappingModeWhenPlaced, intermediatePoints;

- (id) initWithCoordinate:(CLLocationCoordinate2D)c title:(NSString *)t subtitle:(NSString *) sub_title
{
    [super init];
    
    coordinate = c;
    [self setTitle:t];
    [self setSubtitle:sub_title];
    totalDistanceMeters = 0;
    deltaDistanceMeters = 0;
    lineFromPrevPoint = nil;
    pathTypeFromPrevPoint = 0;
    mappingModeWhenPlaced = 0;
    
    intermediatePoints = [[NSMutableArray alloc] init];
    return self;
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    coordinate = newCoordinate;
}

-(void) dealloc 
{
    [title release];
    [subtitle release];
    [lineFromPrevPoint release];
    [intermediatePoints release];
    [super dealloc];
}

@end
