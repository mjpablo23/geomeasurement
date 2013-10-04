//
//  KMLWriter.h
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/encoding.h>
#import <libxml/xmlwriter.h>
#import "GeoIntMeasureAppDelegate.h"
#import "MapPoint.h"

@interface KMLWriter : NSObject {
    GeoIntMeasureAppDelegate *appDelegate;
}

-(NSData *) xmlDataFromRequest;
- (NSString *)dataFilePath;
-(xmlChar *) xmlCharPtrForInput:(const char *)_input withEncoding:(const char *)_encoding;

-(void) writePoints:(NSMutableArray *) coordinatePoints writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding;
-(void) writeLine:(NSMutableArray *) coordinatePoints writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding;
-(void) writePolygon:(NSMutableArray *) coordinatePoints writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding;

-(void) writeHybridRouteTotal:(NSMutableArray *) coordinatePoints writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding;
-(void) writeHybridSinglePath:(NSMutableArray *) coordinatePoints writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding;
-(void) writeHybridSingleLine:(NSMutableArray *) coordinatePoints writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding;

-(void) writeLineStyle:(NSString *) colorNameStr colorHex:(NSString *) colorHex writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding;
-(void) writeAreaStyle:(NSString *) colorNameStr colorHex:(NSString *) colorHex writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding;

@end
