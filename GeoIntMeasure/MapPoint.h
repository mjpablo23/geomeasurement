//
//  MapPoint.h
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

/*
@class MapPoint;
// delegate declaration
@protocol MapPointDelegate <NSObject>;
@optional
-(void) updateDraggedMapPoint:(id *) p; 

@end
*/

// class definition
@interface MapPoint : NSObject <MKAnnotation> {

}

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;

// this is the line from the previous point to the current point
@property (nonatomic, retain) MKPolyline *lineFromPrevPoint;  

// type of mapping used from prev point to current point
@property int pathTypeFromPrevPoint;  // 1 = line, 0 = path

// mapping mode when placed
@property int mappingModeWhenPlaced; // either measure or hybrid mode

// this is the array of intermediates points from the prev to current point (for mappingTypeFromPrevPoint == 1 only)
@property (nonatomic, retain) NSMutableArray *intermediatePoints;

// change in distance from prev point
@property double deltaDistanceMeters;

// total distance up to current point
@property double totalDistanceMeters;


@property (nonatomic, readonly) CLLocationCoordinate2D coordinate; 
// @property (nonatomic, assign) id <MapPointDelegate> *delegate;

-(id) initWithCoordinate:(CLLocationCoordinate2D) c title:(NSString *) t subtitle:(NSString *) sub_title; 
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;

@end
