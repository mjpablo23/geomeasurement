//
//  KMLWriter.m
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "KMLWriter.h"

@implementation KMLWriter

- (id) init {
    [super init];
    appDelegate = [[UIApplication sharedApplication] delegate];
    return self;
}

- (NSData *) xmlDataFromRequest 
{
    xmlTextWriterPtr _writer;
    xmlBufferPtr _buf;
    xmlChar *_tmp;
    // NSLog(@"test xmlDataFromRequest");
    
    const char *_UTF8Encoding = "UTF-8";
    
    _buf = xmlBufferCreate();
    _writer = xmlNewTextWriterMemory(_buf, 0);
    
    xmlTextWriterSetIndent(_writer, 4);  
    
    // <?xml version="1.0" encoding="UTF-8"?>
    xmlTextWriterStartDocument(_writer, "1.0", _UTF8Encoding, NULL);
    
    // <kml xmlns="http://www.opengis.net/kml/2.2">
    xmlTextWriterStartElement(_writer, BAD_CAST "kml");
    xmlTextWriterWriteAttribute(_writer, BAD_CAST "xmlns", BAD_CAST "http://www.opengis.net/kml/2.2");
    
    // <Document>
    xmlTextWriterStartElement(_writer, BAD_CAST "Document");
    
    NSString *purpleLine = @"transPurpleLine";
    NSString *bluePoly = @"transBluePoly"; 
    [self writeLineStyle:purpleLine colorHex:@"7fff00ff" writer:_writer withEncoding:_UTF8Encoding];
    
    [self writeAreaStyle:bluePoly colorHex:@"7dff0000" writer:_writer withEncoding:_UTF8Encoding];
    
    // --------- write points, line, and polygon for meas mode --------
    // write Point-type placemarks 
    // get coordinates of current line from measModel
    [self writePoints:appDelegate.measModel.coordinatePoints writer:_writer withEncoding:_UTF8Encoding];
    
    // write polyline or polygon, depending on mode
    if (appDelegate.measModel.mode == 0) {
        [self writeLine:appDelegate.measModel.coordinatePoints writer:_writer withEncoding:_UTF8Encoding];
    }
    else if (appDelegate.measModel.mode == 1) {
        [self writePolygon:appDelegate.measModel.coordinatePoints writer:_writer withEncoding:_UTF8Encoding];
    }
    
    // --------- write points, lines for hybrid route mode ---------
    [self writePoints:appDelegate.measModel.hybridPoints writer:_writer withEncoding:_UTF8Encoding];
    [self writeHybridRouteTotal:appDelegate.measModel.hybridPoints writer:_writer withEncoding:_UTF8Encoding];
    
    xmlTextWriterEndElement(_writer); // closing <Document>
    xmlTextWriterEndElement(_writer); // closing <kml>
    
    xmlTextWriterEndDocument(_writer);
    xmlFreeTextWriter(_writer);
    
    // turn libxml2 buffer into NSData* object
    
    NSData *_xmlData = [NSData dataWithBytes:(_buf->content) length:(_buf->use)];
    
    NSString *str = [self dataFilePath];        
    [_xmlData writeToFile:str atomically:YES];

    //NSString *aURL = @"file://
    //[_xmlData writeToURL:aURL atomically:YES];
    
    // NSLog(@"kml file written: %@", str);
    
    xmlBufferFree(_buf);
    
    return _xmlData;
}

- (NSString *)dataFilePath { 
    
    NSString *fileName = appDelegate.kmlManager.fileNameToSave; 
    
    fileName = [fileName stringByAppendingString:@".kml"];    
    
    // NSLog(@"saveFile: %@", fileName);
        
    return [appDelegate.kmlManager fileWithPath:fileName];
}

-(void) writePoints:(NSMutableArray *) coordinatePoints writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding {
    xmlChar *_tmp;
    int numPoints = [coordinatePoints count];
    for (int i=0; i<numPoints; i++) {
        MapPoint *mp = [coordinatePoints objectAtIndex:i];
        CLLocationCoordinate2D coord = [[coordinatePoints objectAtIndex:i] coordinate];
        NSString *coordStr = [NSString stringWithFormat:@"%.6f,%.6f", coord.longitude, coord.latitude];
        NSString *coordName = [NSString stringWithFormat:@"%d, %d, %d", i, mp.mappingModeWhenPlaced, mp.pathTypeFromPrevPoint];
        
        xmlTextWriterStartElement(_writer, BAD_CAST "Placemark");
        xmlTextWriterStartElement(_writer, BAD_CAST "name");
        _tmp = [self xmlCharPtrForInput:[coordName cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
        xmlTextWriterWriteString(_writer, _tmp);
        xmlTextWriterEndElement(_writer); // end <name>
        xmlFree(_tmp);
        
        xmlTextWriterStartElement(_writer, BAD_CAST "Point");
        xmlTextWriterStartElement(_writer, BAD_CAST "coordinates");
        _tmp = [self xmlCharPtrForInput:[coordStr cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
        xmlTextWriterWriteString(_writer, _tmp);
        xmlTextWriterEndElement(_writer); // end <coordinates>
        xmlFree(_tmp);
        xmlTextWriterEndElement(_writer); // end <Point>
        xmlTextWriterEndElement(_writer); // end <Placemark>        
    }
}

-(void) writeHybridRouteTotal:(NSMutableArray *) hybridPoints writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding {
    int numPoints = [hybridPoints count];
    if (numPoints <= 1) {
        return;
    }
    for (int i=1; i<numPoints; i++) {
        MapPoint *mp = [hybridPoints objectAtIndex:i];
        if (mp.pathTypeFromPrevPoint == HYBRID_PATH_LINE) {
            // write hybrid single line
            NSMutableArray *endPts = [NSMutableArray arrayWithObjects:[hybridPoints objectAtIndex:i-1], mp, nil];
            [self writeLine:endPts writer:_writer withEncoding:_encoding];
        }
        else if (mp.pathTypeFromPrevPoint == HYBRID_PATH_ROUTE) {
            // write hybrid path line
            NSMutableArray *routePts = [[NSMutableArray alloc] init];
            [routePts addObject:[hybridPoints objectAtIndex:i-1]];

            // add intermediate points
            for (CLLocation *interPt in mp.intermediatePoints) {
                MapPoint *interMapPt = [[MapPoint alloc] initWithCoordinate:[interPt coordinate]  title:nil subtitle:nil];
                [routePts addObject:interMapPt];
                [interMapPt release];
            }
            
            [routePts addObject:mp];
            [self writeLine:routePts writer:_writer withEncoding:_encoding];
            
            [routePts release];
        }
    }
}

-(void) writeHybridSinglePath:(NSMutableArray *) pathPoints writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding {
    
}

-(void) writeHybridSingleLine:(NSMutableArray *) linePoints writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding {
    
}

-(void) writeLine:(NSMutableArray *) coordinatePoints writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding {
    xmlChar *_tmp;
    int numPoints = [coordinatePoints count];
    NSString *style = @"#transPurpleLine";
    
    xmlTextWriterStartElement(_writer, BAD_CAST "Placemark");
    xmlTextWriterStartElement(_writer, BAD_CAST "styleUrl");
    _tmp = [self xmlCharPtrForInput:[style cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
    xmlTextWriterWriteString(_writer, _tmp);
    xmlTextWriterEndElement(_writer); // end <styleUrl>
    xmlFree(_tmp);
    
    xmlTextWriterStartElement(_writer, BAD_CAST "LineString");
    xmlTextWriterStartElement(_writer, BAD_CAST "coordinates");
    
    for (int i=0; i<numPoints; i++) {
        CLLocationCoordinate2D coord = [[coordinatePoints objectAtIndex:i] coordinate];
        NSString *coordStr = [NSString stringWithFormat:@"\n\t%.6f,%.6f,0,", coord.longitude, coord.latitude];
        _tmp = [self xmlCharPtrForInput:[coordStr cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
        xmlTextWriterWriteString(_writer, _tmp);
        xmlFree(_tmp);
    }
    
    xmlTextWriterEndElement(_writer); // end <coordinates>
    xmlTextWriterEndElement(_writer); // end <LineString>
    xmlTextWriterEndElement(_writer); // end <Placemark>
}

-(void) writePolygon:(NSMutableArray *) coordinatePoints writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding {
    xmlChar *_tmp;
    int numPoints = [coordinatePoints count];
    NSString *style = @"#transBluePoly";
    
    xmlTextWriterStartElement(_writer, BAD_CAST "Placemark");
    
    xmlTextWriterStartElement(_writer, BAD_CAST "name");
    _tmp = [self xmlCharPtrForInput:[[NSString stringWithFormat:@"GeoIntArea"] cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
    xmlTextWriterWriteString(_writer, _tmp);
    xmlTextWriterEndElement(_writer); // end <name>
    xmlFree(_tmp);
    
    xmlTextWriterStartElement(_writer, BAD_CAST "visibility");
    _tmp = [self xmlCharPtrForInput:[[NSString stringWithFormat:@"1"] cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
    xmlTextWriterWriteString(_writer, _tmp);
    xmlTextWriterEndElement(_writer); // end <visibility>
    xmlFree(_tmp);
    
    xmlTextWriterStartElement(_writer, BAD_CAST "styleUrl");
    _tmp = [self xmlCharPtrForInput:[style cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
    xmlTextWriterWriteString(_writer, _tmp);
    xmlTextWriterEndElement(_writer); // end <styleUrl>
    xmlFree(_tmp);

    xmlTextWriterStartElement(_writer, BAD_CAST "Polygon");
    xmlTextWriterStartElement(_writer, BAD_CAST "tessellate");
    _tmp = [self xmlCharPtrForInput:[[NSString stringWithFormat:@"1"] cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
    xmlTextWriterWriteString(_writer, _tmp);
    xmlTextWriterEndElement(_writer); // end <tessellate>
    xmlFree(_tmp);
    
    xmlTextWriterStartElement(_writer, BAD_CAST "altitudeMode");
    _tmp = [self xmlCharPtrForInput:[[NSString stringWithFormat:@"clampToGround"] cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
    xmlTextWriterWriteString(_writer, _tmp);
    xmlTextWriterEndElement(_writer); // end <altitudeMode>
    xmlFree(_tmp);
    
    xmlTextWriterStartElement(_writer, BAD_CAST "outerBoundaryIs");
    xmlTextWriterStartElement(_writer, BAD_CAST "LinearRing");
    xmlTextWriterStartElement(_writer, BAD_CAST "coordinates");
    
    for (int i=0; i<numPoints; i++) {
        CLLocationCoordinate2D coord = [[coordinatePoints objectAtIndex:i] coordinate];
        NSString *coordStr = [NSString stringWithFormat:@"\n\t%.6f,%.6f,0,", coord.longitude, coord.latitude];
        _tmp = [self xmlCharPtrForInput:[coordStr cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
        xmlTextWriterWriteString(_writer, _tmp);
        xmlFree(_tmp);
    }

    xmlTextWriterEndElement(_writer); // end <coordinates> 
    xmlTextWriterEndElement(_writer); // end <LinearRing>    
    xmlTextWriterEndElement(_writer); // end <outerBoundaryIs>
    
    xmlTextWriterEndElement(_writer); // end <Polygon>
    xmlTextWriterEndElement(_writer); // end <Placemark>
    
}

-(void) writeLineStyle:(NSString *) colorNameStr colorHex:(NSString *) colorHex writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding {
    xmlChar *_tmp;
    // ------ style for line --------
    // <Style id="transPurpleLine"> .. </Style>
    xmlTextWriterStartElement(_writer, BAD_CAST "Style");
    // xmlTextWriterWriteAttribute(_writer, BAD_CAST "id", BAD_CAST "transPurpleLine");
    xmlTextWriterWriteAttribute(_writer, BAD_CAST "id", BAD_CAST [colorNameStr cStringUsingEncoding:NSUTF8StringEncoding]);
    xmlTextWriterStartElement(_writer, BAD_CAST "LineStyle");
    xmlTextWriterStartElement(_writer, BAD_CAST "color");
    _tmp = [self xmlCharPtrForInput:[colorHex cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
    xmlTextWriterWriteString(_writer, _tmp);
    xmlTextWriterEndElement(_writer); // end <color>
    xmlFree(_tmp);
    
    xmlTextWriterStartElement(_writer, BAD_CAST "width");
    _tmp = [self xmlCharPtrForInput:[[NSString stringWithFormat:@"3"] cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
    xmlTextWriterWriteString(_writer, _tmp);
    xmlTextWriterEndElement(_writer); // end <width>
    xmlFree(_tmp);
    
    xmlTextWriterEndElement(_writer); // end <LineStyle>
    xmlTextWriterEndElement(_writer); // end <Style>
}

-(void) writeAreaStyle:(NSString *) colorNameStr colorHex:(NSString *) colorHex writer:(xmlTextWriterPtr) _writer withEncoding:(const char *)_encoding {
    
    xmlChar *_tmp;
    xmlTextWriterStartElement(_writer, BAD_CAST "Style");
    // xmlTextWriterWriteAttribute(_writer, BAD_CAST "id", BAD_CAST "transBluePoly");
    xmlTextWriterWriteAttribute(_writer, BAD_CAST "id", BAD_CAST [colorNameStr cStringUsingEncoding:NSUTF8StringEncoding]);
    xmlTextWriterStartElement(_writer, BAD_CAST "LineStyle");
    xmlTextWriterStartElement(_writer, BAD_CAST "color");
    _tmp = [self xmlCharPtrForInput:[[NSString stringWithFormat:@"7fff00ff"] cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
    xmlTextWriterWriteString(_writer, _tmp);
    xmlTextWriterEndElement(_writer); // end <color>
    xmlFree(_tmp);
    
    xmlTextWriterStartElement(_writer, BAD_CAST "width");
    _tmp = [self xmlCharPtrForInput:[[NSString stringWithFormat:@"3"] cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
    xmlTextWriterWriteString(_writer, _tmp);
    xmlTextWriterEndElement(_writer); // end <width>
    xmlFree(_tmp);
    
    xmlTextWriterEndElement(_writer); // end <LineStyle>
    
    xmlTextWriterStartElement(_writer, BAD_CAST "PolyStyle");
    xmlTextWriterStartElement(_writer, BAD_CAST "color");
    _tmp = [self xmlCharPtrForInput:[colorHex cStringUsingEncoding:NSUTF8StringEncoding] withEncoding:_encoding];
    xmlTextWriterWriteString(_writer, _tmp);
    xmlTextWriterEndElement(_writer); // end <color>
    xmlFree(_tmp);
    
    xmlTextWriterEndElement(_writer); // end <PolyStyle>
    xmlTextWriterEndElement(_writer); // end <Style>
}

- (xmlChar *) xmlCharPtrForInput:(const char *)_input withEncoding:(const char *)_encoding 
{
    xmlChar *_output;
    int _ret;
    int _size;
    int _outputSize;
    int _temp;
    xmlCharEncodingHandlerPtr _handler;
    
    if (_input == 0)
        return 0;
    
    _handler = xmlFindCharEncodingHandler(_encoding);
    
    if (!_handler) {
        NSLog(@"convertInput: no encoding handler found for '%s'\n", (_encoding ? _encoding : ""));
        return 0;
    }
    
    _size = (int) strlen(_input) + 1;
    _outputSize = _size * 2 - 1;
    _output = (unsigned char *) xmlMalloc((size_t) _outputSize);
    
    if (_output != 0) {
        _temp = _size - 1;
        _ret = _handler->input(_output, &_outputSize, (const xmlChar *) _input, &_temp);
        if ((_ret < 0) || (_temp - _size + 1)) {
            if (_ret < 0) {
                NSLog(@"convertInput: conversion wasn't successful.\n");
            } else {
                NSLog(@"convertInput: conversion wasn't successful. Converted: %i octets.\n", _temp);
            }   
            xmlFree(_output);
            _output = 0;
        } else {
            _output = (unsigned char *) xmlRealloc(_output, _outputSize + 1);
            _output[_outputSize] = 0;  /*null terminating out */
        }
    } else {
        NSLog(@"convertInput: no memory\n");
    }
    
    return _output;
}

@end
