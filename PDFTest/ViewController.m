//
//  ViewController.m
//  PDFTest
//
//  Created by Priya Rajagopal on 4/25/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import "ViewController.h"
#import "PDFView.h"
#import "OverlayView.h"
#import "Element.h"
@import GLKit;

@interface ViewController () <UIScrollViewDelegate, PDFViewProtocol>
@property (nonatomic,strong) NSURL* pdfURL;
@property (nonatomic,strong) NSURL* geomURL;
@property (nonatomic,assign)CGPDFDocumentRef pdf;
@property (weak, nonatomic) IBOutlet UIScrollView *pdfScrollView;
@property CGPDFPageRef page;
@property (nonatomic,strong) PDFView* pdfView;
@property (nonatomic,strong) OverlayView* overlayView;
@property (nonatomic,strong) NSMutableArray* elements;

@end

@implementation ViewController {
    float _viewOrigin[3];
    float _viewDir[3];
    float _viewUpDir[3];
    float _viewCenter[3];
    float _viewOutline[4];
    int _viewScale;
    int _printZoom;
    float _viewOffset[2];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self loadGeomInfo];
    
    //self.pdfURL = [[NSBundle mainBundle]URLForResource:@"floorplan" withExtension:@"pdf"];
    self.pdf = CGPDFDocumentCreateWithURL( (__bridge CFURLRef) self.pdfURL );
    
    if (self.pdf == NULL) {
        CGPDFDocumentRelease(self.pdf);
    }
    else {
        self.page = CGPDFDocumentGetPage( self.pdf, 1 );
//        CGPDFDictionaryRef pageDict = CGPDFPageGetDictionary(self.page);
//        if( self.page != NULL ) {
//            CGPDFPageRetain( self.page );
//        }
        [self loadPdfPageIntoView];
        [self loadGeometries];
    }
}

-(void)convertNSArray:(NSArray*)arr toFloatArray:(float*)out
{
    for (int i=0; i < arr.count; i++)
        out[i] = [[arr objectAtIndex:i] floatValue];
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
        NSDictionary* view = [planViews objectAtIndex:1]; //planViews.firstObject;
        self.pdfURL = [[NSBundle mainBundle]URLForResource:[view valueForKey:@"pdf"] withExtension:nil];
        self.geomURL = [[NSBundle mainBundle]URLForResource:[view valueForKey:@"geom"] withExtension:nil];
        
        [self convertNSArray:[view valueForKey:@"ViewOrigin"] toFloatArray: _viewOrigin];
        [self convertNSArray:[view valueForKey:@"ViewDir"] toFloatArray: _viewDir];
        [self convertNSArray:[view valueForKey:@"ViewUpDir"] toFloatArray: _viewUpDir];
        [self convertNSArray:[view valueForKey:@"ViewCentre"] toFloatArray: _viewCenter];
        [self convertNSArray:[view valueForKey:@"ViewOutline"] toFloatArray: _viewOutline];
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

-(void)loadGeometries {
    self.elements = [[NSMutableArray alloc] init];
    
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
        Element* element = [[Element alloc] initWithId:elemId withViewer:self];
        
        NSArray* geoms = [elem valueForKey:@"geometry"];
        for (NSDictionary* geom in geoms) {
            NSString* data = [geom valueForKey:@"data"];
            [element addGeom:data];
        }

        [self.elements addObject:element];
    }
    
    self.overlayView.elements = self.elements;
    [self.overlayView setNeedsDisplay];
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

-(GLKVector2)convertToPixel:(float*)pt3d
{
    CGRect pageRect = CGPDFPageGetBoxRect( self.page, kCGPDFMediaBox );
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

-(void)dealloc {
    if (self.pdf != NULL) {
        CGPDFDocumentRelease(self.pdf);
    }
    
    if (self.page != NULL) {
        CGPDFPageRelease( self.page );
    }
}

-(void)loadPdfPageIntoView {
    CGRect pageRect = CGPDFPageGetBoxRect( self.page, kCGPDFMediaBox );
    
    self.pdfView = [[PDFView alloc] initWithFrame:pageRect scale:self.pdfScrollView.contentScaleFactor];
    [self.pdfView setPage:self.page];
    [self.pdfScrollView setBackgroundColor:[UIColor grayColor]];
    self.pdfScrollView.delegate = self;
    self.pdfView.delegate = self;
    self.pdfScrollView.minimumZoomScale = 0.25;
    self.pdfScrollView.maximumZoomScale = 5;

    [self.pdfScrollView addSubview:self.pdfView];
    
    self.overlayView = [[OverlayView alloc] initWithFrame:pageRect];
    [self.pdfView addSubview:self.overlayView];
    
}

-(void)restoreView {
    self.pdfScrollView.zoomScale = 1.0;
    
}

-(void)highlightSelectedView {
    
    
}

#pragma maerk - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.pdfView;
}

-(void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view {
   
    NSLog(@"%s",__func__);
    
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale {
    NSLog(@"%s %f",__func__, scale);
}



#pragma mark - PDFViewProtocol 
-(void)onDoubleTapped:(PDFView*)view {
    [self restoreView];
}

-(void)onSingleTapped:(PDFView*)view atLocation:(CGPoint)location {
    NSLog(@"Tapped at location %@", NSStringFromCGPoint(location));
    /* sample code to add overlay view
     Need info to map selected location to element in pdf doc and to add overlay view*/
    //UIView * overlayView = [[UIView alloc]initWithFrame:CGRectMake( location.x-10,location.y-10 , 20, 20)];
    //[overlayView setBackgroundColor:[UIColor yellowColor]];
    //[self.pdfView addSubview:overlayView];
    
    [self highlightSelectedView];
}
@end
