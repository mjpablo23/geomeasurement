//
//  MeasModel.h
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapPoint.h"
// #import <LMDirections/LMDirection.h>
#import "LMDirectionFinder.h"

#define MAP_MODE_MEAS 0
#define MAP_MODE_HYBRID 2

#define HYBRID_PATH_ROUTE 0
#define HYBRID_PATH_LINE 1

#define UNIT_M @"meters"    // ind 0
#define UNIT_KM @"km"       // ind 1
#define UNIT_MI @"miles"    // ind 2
#define UNIT_YDS @"yds"     // ind 3
#define UNIT_FT @"ft"       // ind 4
#define UNIT_ACRES @"acres" // ind 5
#define UNIT_HECTARES @"hectares" // ind 6

@interface MeasModel : NSObject {
    LMDirectionFinder *dFinder;
}

@property int mappingMode; // 0 = measure mode, 1 = directions mode, 2 = hybrid mode

@property (nonatomic, retain) NSMutableArray *coordinatePoints;
@property (nonatomic, retain) NSMutableArray *erasedPoints;
@property int mode; // 0 = distance mode, 1 = area mode

@property (nonatomic, retain) NSMutableArray *routePoints;
@property (nonatomic, retain) NSMutableArray *routeErasedPoints;

@property (nonatomic, retain) NSMutableArray *hybridPoints;
@property (nonatomic, retain) NSMutableArray *hybridErasedPoints;
@property int hybridPathMode; 

@property (nonatomic, retain) MKPolygon *currentPolygon;
@property (nonatomic, retain) MKPolyline *currentPolyline;

@property double accumDistanceMeters; 
@property double accumAreaMetersSq; 

@property (readwrite) int unitSelection; 
@property int mapTypeSelection;

@property int trackingSecs;

-(NSArray *) getPointsForMode;
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

-(double) convertMToKm:(double) val power:(double) powVal; 
-(double) convertMToFt:(double) val power:(double) powVal;
-(double) convertMToYds:(double) val power:(double) powVal;
-(double) convertMToMi:(double) val power:(double) powVal; 
-(double) convertDistance:(double) dist power:(double) powVal;
-(NSString *) getUnitStr;
-(NSString *) getConvertedDistanceStr:(double) dist;
-(NSString *) getLatLonStr:(double) lat longitude:(double) lon; 
-(NSString *) getLatLonStr:(double) lat longitude:(double) lon shortVersion:(int)shortVersion;
-(NSString *) convertToDegrees:(double) coordVal;
-(NSString *) convertToDegrees:(double) coordVal shortVersion:(int)shortVersion;

-(double) distanceBetweenMapPoints:(MapPoint *) annotNew oldMapPoint:(MapPoint *) annotOld;
-(double) distanceCumulativeMetersForMapPointArray:(NSMutableArray *) locationPoints;
-(void) updateTotalDistance;
// -(void) updateTotalDistanceForLastAnnotation;
-(double) accumDistanceMetersForAnnot:(MapPoint *) annot;

-(double) distanceRouteBetweenMapPoints:(MapPoint *) annotNew oldMapPoint:(MapPoint *) annotOld;
- (double) currentArea; 

@end
