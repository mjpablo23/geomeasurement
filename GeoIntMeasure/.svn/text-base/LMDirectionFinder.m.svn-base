//
//  LMDirectionFinder.m
//  LMDirectionFramework
//
//  Created by Beyers, Steven M on 9/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LMDirectionFinder.h"

@implementation LMDirectionFinder

+ (NSString *)mkPolylineKey { return @"LM_MKPolylineKey"; }
+ (NSString *)pointsForPolylineKey { return @"LM_PointsForPolylineKey"; }
+ (NSString *)turnByTurnDirectionsKey { return @"LM_TurnByTurnKey"; }
+ (NSString *)turnLocationsKey { return @"LM_TurnLocationsKey"; }
+ (NSString *)distancesKey { return @"LM_DistancesKey"; }
+ (NSString *)errorKey { return @"LM_ErrorKey"; }

- (id)init
{
    self = [super init];
    if (self) {
        isPolyline = NO;
        readPolylines = NO;
        readInstructions = NO;
        isStep = NO;
        isDistance = NO;
        readDistance = NO;
        isEndLocation = NO;
        readLocation = NO;
    }
    
    return self;
}

- (void)dealloc
{
    [points release];
    [turnLocations release];
    [turnDirections release];
    [distances release];
    [polylinesEncodedString release];
    [characters release];
    [super dealloc];  // added by paul
}

- (NSDictionary *)getDirectionsFrom:(CLLocationCoordinate2D)from To:(CLLocationCoordinate2D)to
{
    MKPolyline *polyline = nil;
    
    NSString *urlString = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/directions/xml?origin=%f,%f&destination=%f,%f&sensor=false", from.latitude, from.longitude, to.latitude, to.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setTimeoutInterval:30.0];
    
    NSURLResponse *response;
    NSError *error;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:responseData];
    [parser setDelegate:self];
    [parser parse];
    [parser release];
    
    if (points && [points count] > 0)
    {
        CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * [points count]);
        for (int i=0; i < [points count]; i++)
        {
            CLLocation *location = (CLLocation *)[points objectAtIndex:i];
            coords[i] = location.coordinate;
        }
        
        polyline = [MKPolyline polylineWithCoordinates:coords count:[points count]];
        
        free(coords);
    }
    
    NSMutableDictionary *returnDict = [NSMutableDictionary dictionary];
    if (polyline != nil) {
        [returnDict setObject:polyline forKey:[LMDirectionFinder mkPolylineKey]];
        [returnDict setObject:points forKey:[LMDirectionFinder pointsForPolylineKey]];
        [returnDict setObject:turnLocations forKey:[LMDirectionFinder turnLocationsKey]];
        [returnDict setObject:turnDirections forKey:[LMDirectionFinder turnByTurnDirectionsKey]];
        [returnDict setObject:distances forKey:[LMDirectionFinder distancesKey]];
    }
    
    [points release];
    points = nil;
    
    if (errors)
    {
        [returnDict setObject:errors forKey:[LMDirectionFinder errorKey]];
        [errors release];
        errors = nil;
    }
    
    [turnLocations release];
    turnLocations = nil;
    [turnDirections release];
    turnDirections = nil;
    [distances release];
    distances = nil;
    
    return returnDict;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"polyline"])
        isPolyline = YES;
    else if ([elementName isEqualToString:@"step"])
        isStep = YES;
    else if ([elementName isEqualToString:@"end_location"] && isStep)
        isEndLocation = YES;
    else if ([elementName isEqualToString:@"points"] && isPolyline)
        readPolylines = YES;
    else if ([elementName isEqualToString:@"distance"] && isStep) 
        isDistance = YES;
    else if ([elementName isEqualToString:@"html_instructions"] && isStep)
    {
        readInstructions = YES;
        characters = [[NSMutableString alloc] init];
    }
    else if (([elementName isEqualToString:@"lat"] || [elementName isEqualToString:@"lng"]) && isStep && isEndLocation)
    {
        readLocation = YES;
        characters = [[NSMutableString alloc] init];
    }
    else if ([elementName isEqualToString:@"value"] && isStep && isDistance) {
        readDistance = YES;
        characters = [[NSMutableString alloc] init];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (readPolylines)
    {
        [polylinesEncodedString release];
        polylinesEncodedString = string;
        [polylinesEncodedString retain];
    }else if (readInstructions || readLocation || readDistance)
        [characters appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"polyline"])
        isPolyline = NO;
    else if ([elementName isEqualToString:@"step"])
        isStep = NO;
    else if ([elementName isEqualToString:@"end_location"] && isStep)
        isEndLocation = NO;
    else if ([elementName isEqualToString:@"distance"] && isStep) 
        isDistance = NO;
    else if ([elementName isEqualToString:@"points"] && isPolyline && polylinesEncodedString)
    {
        if (!points)
            points = [[NSMutableArray alloc] init];
        
        [points addObjectsFromArray:[self decodePolyLine:polylinesEncodedString]];
        [polylinesEncodedString release];
        polylinesEncodedString = nil;
        
        readPolylines = NO;
    }
    else if ([elementName isEqualToString:@"html_instructions"] && readInstructions)
    {
        readInstructions = NO;
        
        if (!turnDirections)
            turnDirections = [[NSMutableArray alloc] init];
        
        [turnDirections addObject:characters];
    }
    else if (([elementName isEqualToString:@"lat"] || [elementName isEqualToString:@"lng"]) && readLocation)
    {
        readLocation = NO;
        
        if (!turnLocations)
            turnLocations = [[NSMutableArray alloc] init];
        
        [turnLocations addObject:characters];
    }
    else if ([elementName isEqualToString:@"value"] && readDistance) {
        readDistance = NO;
        if (!distances) 
            distances = [[NSMutableArray alloc] init];
        [distances addObject:characters];
    }
    
    [characters release];
    characters = nil;
}

-(NSMutableArray *)decodePolyLine:(NSString *)encodedStr {  
    NSMutableString *encoded = [[NSMutableString alloc] initWithCapacity:[encodedStr length]];  
    [encoded appendString:encodedStr];  
    [encoded replaceOccurrencesOfString:@"\\\\" withString:@"\\"  
                                options:NSLiteralSearch  
                                  range:NSMakeRange(0, [encoded length])];  
    
    NSInteger len = [encoded length];  
    NSInteger index = 0;  
    NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];  
    
    NSInteger lat=0;  
    NSInteger lng=0;
    
    while (index < len) {  
        NSInteger b;  
        NSInteger shift = 0;  
        NSInteger result = 0; 
        
        do {  
            @try {
                b = [encoded characterAtIndex:index++] - 63;  
                result |= (b & 0x1f) << shift;  
                shift += 5; 
            }
            @catch (NSException *exception) {
                if (!errors)
                    errors = [[NSMutableArray alloc] init];
                
                [errors addObject:exception];
                break;
            }
        } while (b >= 0x20);  
        
        NSInteger dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));  
        lat += dlat;  
        
        shift = 0;  
        result = 0; 
        
        do {  
            @try {
                b = [encoded characterAtIndex:index++] - 63;  
                result |= (b & 0x1f) << shift;  
                shift += 5;
            }
            @catch (NSException *exception) {
                if (!errors)
                    errors = [[NSMutableArray alloc] init];
                
                [errors addObject:exception];
                break;
            }
        } while (b >= 0x20);
        
        NSInteger dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));  
        lng += dlng;  
        
        NSNumber *latitude = [[[NSNumber alloc] initWithFloat:lat * 1e-5] autorelease];  
        NSNumber *longitude = [[[NSNumber alloc] initWithFloat:lng * 1e-5] autorelease];
        
        CLLocation *loc = [[[CLLocation alloc] initWithLatitude:[latitude floatValue] longitude:[longitude floatValue]] autorelease];  
        
        [array addObject:loc];  
    }
    
    [encoded release];  
    
    return array;
}

-(NSMutableArray *)decodePolyLineLevel:(NSString *)encodedStr {  
    NSMutableString *encoded = [[NSMutableString alloc] initWithCapacity:[encodedStr length]];  
    [encoded appendString:encodedStr];  
    [encoded replaceOccurrencesOfString:@"\\\\" withString:@"\\"  
                                options:NSLiteralSearch  
                                  range:NSMakeRange(0, [encoded length])];
    
    NSInteger len = [encoded length];  
    NSInteger index = 0;  
    NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];  
    
    while (index < len) {  
        NSInteger b;  
        NSInteger shift = 0;  
        NSInteger result = 0;
        
        do {  
            @try {
                b = [encoded characterAtIndex:index++] - 63;  
                result |= (b & 0x1f) << shift;  
                shift += 5;
            }
            @catch (NSException *exception) {
                if (!errors)
                    errors = [[NSMutableArray alloc] init];
                
                [errors addObject:exception];
                break;
            }
        } while (b >= 0x20); 
        
        NSNumber *level = [[[NSNumber alloc] initWithFloat:result] autorelease];
        
        [array addObject:level];  
    }  
    
    [encoded release];
    
    return array;  
} 

@end
