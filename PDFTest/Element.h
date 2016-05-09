//
//  Element.h
//  PDFTest
//
//  Created by Christian Utama on 5/5/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#ifndef Element_h
#define Element_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGContext.h>
#import "ViewController.h"

@interface Element : NSObject

@property unsigned int elementId;
@property bool selected;
@property (nonatomic, strong) NSMutableArray* geometries;

-(Element*)initWithId:(unsigned int)elementId withViewer:(ViewController*) viewer;
-(void)addGeom:(NSString*)base64String;
-(void)draw:(CGContextRef) ctx;

@end

#endif /* Element_h */
