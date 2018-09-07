//
//  KMLParser.h
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

// #import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class KMLPlacemark;
@class KMLStyle;

@interface KMLParser : NSObject <NSXMLParserDelegate> {
    NSMutableDictionary *_styles;
    NSMutableArray *_placemarks;
    
    KMLPlacemark *_placemark;
    KMLStyle *_style;
}

+ (KMLParser *)parseKMLAtURL:(NSURL *)url;
+ (KMLParser *)parseKMLAtPath:(NSString *)path;

@property (nonatomic, readonly) NSArray *overlays;
@property (nonatomic, readonly) NSArray *points;
@property (nonatomic, readonly) NSArray *pointNames; 

- (MKAnnotationView *)viewForAnnotation:(id <MKAnnotation>)point;
- (MKOverlayView *)viewForOverlay:(id <MKOverlay>)overlay;

@end
