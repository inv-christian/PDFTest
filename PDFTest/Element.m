//
//  Element.m
//  PDFTest
//
//  Created by Christian Utama on 5/5/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import "Element.h"
#import "CTMDecoder.h"

@interface Element()
@property (nonatomic, weak) ViewController* viewer;

@end

@implementation Element

-(Element*)initWithId:(unsigned int)elementId withViewer:(ViewController*) viewer
{
    self = [super init];
    if (self) {
        self.elementId = elementId;
        self.viewer = viewer;
        self.selected = false;
        self.geometries = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)addGeom:(NSString*)base64String
{
    NSData* decodedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    CTMDecoder* ctm = [[CTMDecoder alloc] initWithData:decodedData];
    
    NSArray* geom = [ctm copyPoints];
    [self.geometries addObject:geom];
}

-(void)getPoints:(NSArray*)arr startOffset:(int)offset toArray:(float*)out
{
    for (int i=0; i < 6; i++)
        out[i] = [[arr objectAtIndex:(offset + i)] floatValue];
}

-(void)draw:(CGContextRef) context
{
    for (NSArray* geom in self.geometries) {
        for (int i=0; i < geom.count; i+= 6) {
            if (i <= geom.count - 6) {
                
                float arr[6];
                [self getPoints:geom startOffset:i toArray:arr];
                
                GLKVector2 p1 = [self.viewer convertToPixel:arr];
                GLKVector2 p2 = [self.viewer convertToPixel:(arr+3)];
                
                CGContextMoveToPoint(context, p1.x, p1.y);
                CGContextAddLineToPoint(context, p2.x, p2.y);
            }
        }
    }
}

@end