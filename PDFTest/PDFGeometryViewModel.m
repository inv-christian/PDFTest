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


#pragma mark - PDFDetails

@interface PDFDetails() {
    
    float _viewOrigin[3];
    float _viewDir[3];
    float _viewUpDir[3];
    float _viewCenter[3];
    float _viewOutline[4];
    int _viewScale;
    float _printZoom;
    float _viewOffset[2];
}
@property (nonatomic,readwrite) NSString* name;
@property (nonatomic,readwrite) NSURL* pdfURL;
@property (nonatomic,readwrite) NSURL* geomURL;
@property (nonatomic,readwrite) NSArray <Element*>* elements;

-(instancetype)initWithPlanView:(NSDictionary*)planView;
-(GLKVector2)project2d:(float*)pt3d
            withOrigin:(float*)o
              withZdir:(float*)z
              withYdir:(float*)y;

@end



@implementation PDFDetails


-(instancetype)initWithPlanView:(NSDictionary*)planView{
    self = [super init];
    if (self) {

        self.name = [planView valueForKey:@"pdf"];
        // Right now, loading from bundle.Eventually will fetch from server
        NSURL* pdlUrlInBundle = [[NSBundle mainBundle]URLForResource:self.name withExtension:nil];
         self.pdfURL = [self copyFileIntoDocumentsFolder:pdlUrlInBundle]; // This allows us to edit them
         self.geomURL = [[NSBundle mainBundle]URLForResource:[planView valueForKey:@"geom"] withExtension:nil];
        NSArray* viewOriginArray = planView [@"ViewOrigin"];
        [viewOriginArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            _viewOrigin[idx] = [obj floatValue];
        }];
        
        NSArray* ViewDirArray = planView [@"ViewDir"];
        [ViewDirArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            _viewDir[idx] = [obj floatValue];
        }];
        
        NSArray* ViewUpDirArray = planView [@"ViewUpDir"];
        [ViewUpDirArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            _viewUpDir[idx] = [obj floatValue];
        }];
        
        NSArray* ViewCentreArray = planView [@"ViewCentre"];
        [ViewCentreArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            _viewCenter[idx] = [obj floatValue];
        }];
        
        NSArray* ViewOutlineArray = planView[@"ViewOutline"];
        [ViewOutlineArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            _viewOutline[idx] = [obj floatValue];
        }];
        
        
        
        _viewScale = [[planView valueForKey:@"ViewScale"] intValue];
        _printZoom = [[planView valueForKey:@"printZoom"] floatValue];
        
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
    return  self;
}

-(GLKVector2)project2d:(float*)pt3d
            withOrigin:(float*)o
              withZdir:(float*)z
              withYdir:(float*)y
{
    GLKVector3 origin = GLKVector3MakeWithArray(o ? o : _viewCenter);
    GLKVector3 zdir = GLKVector3MakeWithArray(z ? z : _viewDir);
    GLKVector3 ydir = GLKVector3MakeWithArray(y ? y : _viewUpDir);
    GLKVector3 xdir = GLKVector3CrossProduct(ydir, zdir);
    
    GLKVector3 p = GLKVector3Subtract(GLKVector3MakeWithArray(pt3d), origin);
    return GLKVector2Make(GLKVector3DotProduct(p, xdir), GLKVector3DotProduct(p, ydir));
}


-(NSArray<Element*>*) elements {
    if (!_elements) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
         [self loadGeometryElements];
        // TODO: Have a completion handler to indicate when elements are loaded so it can be highlighted
    });
       
    }
    return _elements;
}

-(void)loadGeometryElements {
    NSMutableArray* mutElements = [[NSMutableArray alloc] init];
    
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
        NSLog(@"%s : element Id :%d",__func__,elemId);
        Element* element = [[Element alloc] initWithId:elemId andPDFGeomViewModel:self];
        
        NSArray* geoms = [elem valueForKey:@"geometry"];
        for (NSDictionary* geom in geoms) {
            NSString* data = [geom valueForKey:@"data"];
            [element addGeom:data];
        }
        
        [mutElements addObject:element];
    }
    self.elements = [mutElements copy];
    
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


#pragma mark - helper
-(NSURL*)copyFileIntoDocumentsFolder:(NSURL*)fileUrl {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docUrl = paths[0];
    NSURL* newUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",docUrl,self.name]];
    NSError* error;
    [[NSFileManager defaultManager]copyItemAtURL:fileUrl toURL:newUrl error:&error];
    if (error) {
        if (error.code == 516) {
            return newUrl;
        }
        NSLog(@"Failed to copy file %@ over with error;%@",fileUrl,error);
        return nil;
    }
    return  newUrl;
}

@end


#pragma mark - PDFGeometryViewModel

@interface PDFGeometryViewModel()
@property (nonatomic,readwrite) NSURL* geomInfoURL;
@property (nonatomic,readwrite) NSURL* pdfURL;
@property (nonatomic,readwrite) NSURL* geomURL;
@property (nonatomic, readwrite)UIView* pdfView;
@property (nonatomic, readwrite) NSArray<PDFDetails*>* pdfs;

@end

@implementation PDFGeometryViewModel

float _viewOrigin[3];
float _viewDir[3];
float _viewUpDir[3];
float _viewCenter[3];
float _viewOutline[4];
int _viewScale;
float _printZoom;
float _viewOffset[2];

-(instancetype) initWithGeometryURL:(NSURL*)geomInfoURL {
    if (self = [super init]) {
        _geomInfoURL = geomInfoURL;
        [self loadGeomInfo];
    }
    return self;
}

-(void)loadGeomInfo {
    NSError* error = nil;
    NSData* jsonData = [NSData dataWithContentsOfURL:self.geomInfoURL options:NSDataReadingUncached error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    error = nil;
    NSDictionary *parsed = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    NSMutableArray* pdfDetailsArray = [[NSMutableArray alloc]initWithCapacity:0];
    
    NSArray* planViews = [parsed valueForKey:@"planViews"];
    
    [planViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      
        [pdfDetailsArray addObject:[[PDFDetails alloc]initWithPlanView:obj]];
        
  
    }];
    self.pdfs = pdfDetailsArray;

}




@end
