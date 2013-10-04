//
//  LMDirectionFinder.h
//  LMDirectionFramework
//
//  Created by Beyers, Steven M on 9/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface LMDirectionFinder : NSObject <NSXMLParserDelegate>
{
@private
    NSMutableArray *points;
    NSMutableArray *turnLocations;
    NSMutableArray *turnDirections;
    NSMutableArray *distances;
    NSMutableArray *errors;
    
    BOOL isPolyline;
    BOOL readPolylines;
    BOOL readInstructions;
    BOOL isStep;
    BOOL isDistance;
    BOOL readDistance;
    BOOL isEndLocation;
    BOOL readLocation;
    
    NSString *polylinesEncodedString;
    NSMutableString *characters;
}

-(NSMutableArray *)decodePolyLine:(NSString *)encodedStr;
-(NSMutableArray *)decodePolyLineLevel:(NSString *)encodedStr;

+ (NSString *)mkPolylineKey;
+ (NSString *)pointsForPolylineKey;  
+ (NSString *)turnByTurnDirectionsKey;
+ (NSString *)turnLocationsKey;
+ (NSString *)distancesKey;
+ (NSString *)errorKey;


/**
 Finds directions from one latitude/longitude coordinate to another.
 
 @param from The starting location of the directions
 @param to The ending location of the directions
 @returns NSDictionary with three pieces of information:
 1: An MKPolyline that can be placed on a map. (Key = [LMDirectionFinder mkPolylineKey])
 2: An NSArray of NSStrings that are the list of turn by turn directions. (Key = [LMDirectionFinder turnByTurnDirectionsKey])
 3: An NSArray of NSStrings that are the latitude/longitude of each step in the turn by turn directions list. (Key = [LMDirectionFinder turnLocationsKey])
 *Note: Each latitude and longitude stored in this array are seperate values. The NSArray has the format {latitude, longitude, latitude, longitude, ...}
 4: An NSArray of NSException objects that were thrown while trying to determine directions. If errors are found the framework will make a "best effort" to continue with the directions although they may not be 100% accurate. (Key = [LMDirectionFinder errorKey])
 *NOTE: This will only be in the dictionary if there was at least one error thrown.
 */
- (NSDictionary *)getDirectionsFrom:(CLLocationCoordinate2D)from To:(CLLocationCoordinate2D)to;

@end
