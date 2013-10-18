//
//  KMLManager.m
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/20/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "KMLManager.h"

@implementation KMLManager

@synthesize filePathToLoad, fileNameToLoad, needToLoadFileOnMap, emailLoadMode, fileNameToSave, needToSaveFile;

- (id) init {
    [super init];
    filePathToLoad = @"";
    fileNameToLoad = @"";
    needToLoadFileOnMap = 0;
    emailLoadMode = 0;
    fileNameToSave = @"";
    needToSaveFile = 0;
    return self;
}

-(NSArray *) filePathsArray {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *filePathsArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentsDirectory  error:nil];
    return filePathsArray;
}

-(NSString *) fileWithPath:(NSString *) file {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:file];
    return filePath;
}

-(NSString *) fileWithPathInDocuments:(NSUInteger) row {
    NSArray *filePathsArray = [self filePathsArray];
    NSString *fileName = [filePathsArray objectAtIndex:row];
    return [self fileWithPath:fileName];
}

@end
