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
@class PDFGeometryViewModel;

@interface Element : NSObject

@property unsigned int elementId;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, strong) NSMutableArray* geometries;
@property (nonatomic, assign) CGRect boundingBox;
@property (nonatomic, assign) CGPathRef pathRef;


-(Element*)initWithId:(unsigned int)elementId andPDFGeomViewModel:(PDFGeometryViewModel*)viewModel;
-(void)addGeom:(NSString*)base64String;
-(void)draw:(CGContextRef) ctx;
-(float)distanceToPoint:(CGPoint)pt viewRect:(CGRect) rect;
-(BOOL) selectedStateChanged;
@end

#endif /* Element_h */
