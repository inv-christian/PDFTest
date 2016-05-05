//
//  Element.m
//  PDFTest
//
//  Created by Christian Utama on 5/5/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import "Element.h"
#import "CTMDecoder.h"
#import <CoreGraphics/CoreGraphics.h>

@interface Element()

@end

@implementation Element

-(Element*)initWithId:(unsigned int)elementId
{
    self.elementId = elementId;
    self.selected = false;
    self.geometries = [[NSMutableArray alloc] init];
    return self;
}

-(void)addGeom:(NSString*)base64String
{
    NSData* decodedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    CTMDecoder* ctm = [[CTMDecoder alloc] initWithData:decodedData];
    
    NSArray* geom = [ctm copyPoints];
    [self.geometries addObject:geom];
}

-(void)draw:(CGContextRef) context
{
    if (!self.selected) return;
    
    CGContextBeginPath(context);
    
    for (NSArray* geom in self.geometries) {
        for (int i=0; i < geom.count; i+= 6) {
            if (i <= geom.count - 6) {
                //CGContextMoveToPoint(context, geom[0], geom[1]);
                //CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
            }
        }
    }
    CGContextStrokePath(context);
}

@end