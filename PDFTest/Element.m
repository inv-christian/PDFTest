//
//  Element.m
//  PDFTest
//
//  Created by Christian Utama on 5/5/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import "Element.h"
#import "CTMDecoder.h"
#import "PDFGeometryViewModel.h"
@import GLKit;

@interface Element()
@property (nonatomic, strong) PDFGeometryViewModel* viewModel;
@property (nonatomic, assign) BOOL prevSelection;
@end

@implementation Element

-(Element*)initWithId:(unsigned int)elementId andPDFGeomViewModel:(PDFGeometryViewModel*)viewModel
{
    self = [super init];
    if (self) {
        self.elementId = elementId;
        self.viewModel = viewModel;
        self.selected = false;
        self.geometries = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)setSelected:(BOOL)selected {
    _prevSelection = _selected;
    _selected = selected;
    
}

-(BOOL) selectedStateChanged {
    return self.prevSelection != self.selected;
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
    if (self.selected) {
        CGContextSetStrokeColorWithColor(context, [UIColor yellowColor].CGColor);
     
    }else {
         CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
    }
    
    for (NSArray* geom in self.geometries) {
        for (int i=0; i < geom.count; i+= 6) {
            if (i <= geom.count - 6) {
                
                float arr[6];
                [self getPoints:geom startOffset:i toArray:arr];
                
                GLKVector2 p1 = [self.viewModel convertToPixel:arr inRect:CGContextGetClipBoundingBox(context)];
                GLKVector2 p2 = [self.viewModel convertToPixel:(arr+3) inRect:CGContextGetClipBoundingBox(context)];
                
                
                CGContextMoveToPoint(context, p1.x, p1.y);
                CGContextAddLineToPoint(context, p2.x, p2.y);
            }
        }
    }
}

-(float)distanceToPoint:(CGPoint)pt viewRect:(CGRect) rect
{
    float minDistance = FLT_MAX;
    for (NSArray* geom in self.geometries) {
        for (int i=0; i < geom.count; i+= 6) {
            if (i <= geom.count - 6) {
                
                float arr[6];
                [self getPoints:geom startOffset:i toArray:arr];
                
                GLKVector2 p1 = [self.viewModel convertToPixel:arr inRect:rect];
                GLKVector2 p2 = [self.viewModel convertToPixel:(arr+3) inRect:rect];
                
                float distance = [self lineDistanceToPoint:pt withLineStartPoint:p1 andLineEndPoint:p2];
                if (distance < minDistance)
                    minDistance = distance;
            }
        }
    }
    return minDistance;
}

-(float)lineDistanceToPoint:(CGPoint)pt
         withLineStartPoint:(GLKVector2)start
            andLineEndPoint:(GLKVector2)end
{
    // http://geomalgorithms.com/a07-_distance.html#dist3D_Segment_to_Segment
    
    GLKVector3 p1 = GLKVector3Make(start.x, start.y, 0.0);
    GLKVector3 p2 = GLKVector3Make(end.x, end.y, 0.0);
    
    GLKVector3 u = GLKVector3Make(0.0, 0.0, -10000.0);
    GLKVector3 v = GLKVector3Subtract(p2, p1);
    GLKVector3 w = GLKVector3Subtract(GLKVector3Make(pt.x, pt.y, 10000), p1);
    
    float a = GLKVector3DotProduct(u,u);         // always >= 0
    float b = GLKVector3DotProduct(u,v);
    float c = GLKVector3DotProduct(v,v);         // always >= 0
    float d = GLKVector3DotProduct(u,w);
    float e = GLKVector3DotProduct(v,w);
    float D = a*c - b*b;        // always >= 0
    float sc, sN, sD = D;       // sc = sN / sD, default sD = D >= 0
    float tc, tN, tD = D;       // tc = tN / tD, default tD = D >= 0
    
    // compute the line parameters of the two closest points
    if (D < FLT_EPSILON) { // the lines are almost parallel
        sN = 0.0;         // force using point P0 on segment S1
        sD = 1.0;         // to prevent possible division by 0.0 later
        tN = e;
        tD = c;
    }
    else {                 // get the closest points on the infinite lines
        sN = (b*e - c*d);
        tN = (a*e - b*d);
        if (sN < 0.0) {        // sc < 0 => the s=0 edge is visible
            sN = 0.0;
            tN = e;
            tD = c;
        }
        else if (sN > sD) {  // sc > 1  => the s=1 edge is visible
            sN = sD;
            tN = e + b;
            tD = c;
        }
    }
    
    if (tN < 0.0) {            // tc < 0 => the t=0 edge is visible
        tN = 0.0;
        // recompute sc for this edge
        if (-d < 0.0)
            sN = 0.0;
        else if (-d > a)
            sN = sD;
        else {
            sN = -d;
            sD = a;
        }
    }
    else if (tN > tD) {      // tc > 1  => the t=1 edge is visible
        tN = tD;
        // recompute sc for this edge
        if ((-d + b) < 0.0)
            sN = 0;
        else if ((-d + b) > a)
            sN = sD;
        else {
            sN = (-d +  b);
            sD = a;
        }
    }
    // finally do the division to get sc and tc
    sc = (fabs(sN) < FLT_EPSILON ? 0.0 : sN / sD);
    tc = (fabs(tN) < FLT_EPSILON ? 0.0 : tN / tD);
    
    // get the difference of the two closest points
    //Vector   dP = w + (sc * u) - (tc * v);  // =  S1(sc) - S2(tc)
    GLKVector3 S1 = GLKVector3MultiplyScalar(u, sc);
    GLKVector3 S2 = GLKVector3MultiplyScalar(v, tc);
    GLKVector3 dP = GLKVector3Add(w, S1);
    dP = GLKVector3Subtract(dP, S2);
    
    return GLKVector3Length(dP);
}

@end