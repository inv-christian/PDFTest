//
//  PDFGeometryViewModel.m
//  PDFTest
//
//  Created by Priya Rajagopal on 5/12/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import "PDFGeometryViewModel.h"
#import "PDFView.h"

@import GLKit;

@interface PDFGeometryViewModel()
@property (nonatomic,readwrite) NSURL* geomInfoURL;
@property (nonatomic,readwrite) NSURL* pdfURL;
@property (nonatomic,readwrite) NSURL* geomURL;
@property (nonatomic,readwrite) NSArray <Element*>* elements;
@property (nonatomic, readwrite)UIView* pdfView;

@end
@implementation PDFGeometryViewModel

float _viewOrigin[3];
float _viewDir[3];
float _viewUpDir[3];
float _viewCenter[3];
float _viewOutline[4];
int _viewScale;
int _printZoom;
float _viewOffset[2];

-(instancetype) initWithGeometryURL:(NSURL*)geomInfoURL {
    if (self = [super init]) {
        _geomInfoURL = geomInfoURL;
        [self loadGeomInfo];
    }
    return self;
}

-(void)loadGeomInfo {
    NSURL* geomInfoURL = [[NSBundle mainBundle]URLForResource:@"geomInfo.json" withExtension:nil];
    NSError* error = nil;
    NSData* jsonData = [NSData dataWithContentsOfURL:geomInfoURL options:NSDataReadingUncached error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    error = nil;
    NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    NSArray* planViews = [parsed valueForKey:@"planViews"];
    if (planViews.count > 0) {
        //NSDictionary* view = planViews.firstObject;
        NSDictionary* view = [planViews objectAtIndex:1];
        
        self.pdfURL = [[NSBundle mainBundle]URLForResource:[view valueForKey:@"pdf"] withExtension:nil];
        self.geomURL = [[NSBundle mainBundle]URLForResource:[view valueForKey:@"geom"] withExtension:nil];
        
        NSArray* viewOriginArray = view [@"ViewOrigin"];
        [viewOriginArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            _viewOrigin[idx] = [obj floatValue];
        }];
        
        NSArray* ViewDirArray = view [@"ViewDir"];
        [ViewDirArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            _viewDir[idx] = [obj floatValue];
        }];
        
        NSArray* ViewUpDirArray = view [@"ViewUpDir"];
        [ViewUpDirArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            _viewUpDir[idx] = [obj floatValue];
        }];
        
        NSArray* ViewCentreArray = view [@"ViewCentre"];
        [ViewCentreArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            _viewCenter[idx] = [obj floatValue];
        }];
        
        NSArray* ViewOutlineArray = view[@"ViewOutline"];
        [ViewOutlineArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            _viewOutline[idx] = [obj floatValue];
        }];
        
        

        _viewScale = [[view valueForKey:@"ViewScale"] intValue];
        _printZoom = [[view valueForKey:@"printZoom"] intValue];
        
        GLKVector2 projViewCenter = [self project2d:_viewCenter withOrigin:_viewOrigin withZdir:_viewDir withYdir:_viewUpDir];
        float outlineMid[2] = {(_viewOutline[0] + _viewOutline[2]) / 2, (_viewOutline[1] + _viewOutline[3]) / 2};
        
        _viewOffset[0] = -(outlineMid[0] - projViewCenter.x/_viewScale);
        _viewOffset[1] = (outlineMid[1] - projViewCenter.y/_viewScale);
        
        _viewDir[0] = -_viewDir[0];
        _viewDir[1] = -_viewDir[1];
        _viewDir[2] = -_viewDir[2];
        _viewUpDir[0] = -_viewUpDir[0];
        _viewUpDir[1] = -_viewUpDir[1];
        _viewUpDir[2] = -_viewUpDir[2];
        
        
    }
}


-(NSArray<Element*>*) elements {
    if (!_elements) {
        _elements = [self loadGeometryElements];
    }
    return _elements;
}

-(NSArray<Element*>*)loadGeometryElements {
    NSMutableArray* elements = [[NSMutableArray alloc] init];
    
    NSError* error = nil;
    NSData* jsonData = [NSData dataWithContentsOfURL:self.geomURL options:NSDataReadingUncached error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    error = nil;
    NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    for (NSDictionary* elem in [parsed valueForKey:@"geometries"]) {
        unsigned int elemId = [[elem valueForKey:@"elementId"] intValue];
        Element* element = [[Element alloc] initWithId:elemId andPDFGeomViewModel:self];
        
        NSArray* geoms = [elem valueForKey:@"geometry"];
        for (NSDictionary* geom in geoms) {
            NSString* data = [geom valueForKey:@"data"];
            [element addGeom:data];
        }
        
        [elements addObject:element];
    }
    return  elements;
    
}


-(GLKVector2)project2d:(float*)pt3d
            withOrigin:(float*)o
              withZdir:(float*)z
              withYdir:(float*)y
{
    GLKVector3 origin = GLKVector3MakeWithArray(o ? o : _viewOrigin);
    GLKVector3 zdir = GLKVector3MakeWithArray(z ? z : _viewDir);
    GLKVector3 ydir = GLKVector3MakeWithArray(y ? y : _viewUpDir);
    GLKVector3 xdir = GLKVector3CrossProduct(ydir, zdir);
    
    GLKVector3 p = GLKVector3Subtract(GLKVector3MakeWithArray(pt3d), origin);
    return GLKVector2Make(GLKVector3DotProduct(p, xdir), GLKVector3DotProduct(p, ydir));
}

-(GLKVector2)convertToPixel:(float*)pt3d inView:(UIView*)view
{
    CGRect pageRect = view.bounds;
    
    float midx = pageRect.size.width / 2;
    float midy = pageRect.size.height / 2;
    
    float pageScale = 1.0;
    float viewScale = 1.0/_viewScale;
    float printZoom = _printZoom / 100.0;
    
    int pixelsPerInch = 72;
    float scale = pageScale * 12 * viewScale * printZoom * pixelsPerInch;
    float offsetx = pageScale * 12 * printZoom * pixelsPerInch * _viewOffset[0];
    float offsety = pageScale * 12 * printZoom * pixelsPerInch * _viewOffset[1];
    
    GLKVector2 pt2d = [self project2d:pt3d withOrigin:nil withZdir:nil withYdir:nil];
    pt2d.x *= scale;
    pt2d.y *= scale;
    pt2d.x += midx + offsetx;
    pt2d.y += midy + offsety;
    return pt2d;
}

-(GLKVector2)convertToPixel:(float*)pt3d inRect:(CGRect)rect
{
    CGRect pageRect = rect;
    
    float midx = pageRect.size.width / 2;
    float midy = pageRect.size.height / 2;
    
    float pageScale = 1.0;
    float viewScale = 1.0/_viewScale;
    float printZoom = _printZoom / 100.0;
    
    int pixelsPerInch = 72;
    float scale = pageScale * 12 * viewScale * printZoom * pixelsPerInch;
    float offsetx = pageScale * 12 * printZoom * pixelsPerInch * _viewOffset[0];
    float offsety = pageScale * 12 * printZoom * pixelsPerInch * _viewOffset[1];
    
    GLKVector2 pt2d = [self project2d:pt3d withOrigin:nil withZdir:nil withYdir:nil];
    pt2d.x *= scale;
    pt2d.y *= scale;
    pt2d.x += midx + offsetx;
    pt2d.y += midy + offsety;
    return pt2d;
}


@end
