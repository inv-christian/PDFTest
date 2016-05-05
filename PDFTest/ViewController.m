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

@property (nonatomic,strong) NSArray* viewOrigin;
@property (nonatomic,strong) NSArray* viewDir;
@property (nonatomic,strong) NSArray* viewUpDir;
@property (nonatomic,strong) NSArray* viewCenter;
@property (nonatomic,strong) NSArray* viewOutline;
@property int viewScale;
@property int printZoom;

@property (nonatomic,strong) NSMutableArray* elements;
@end

@implementation ViewController

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
    }
    
    [self loadGeometries];
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
        NSDictionary* view = planViews.firstObject;
        self.pdfURL = [[NSBundle mainBundle]URLForResource:[view valueForKey:@"pdf"] withExtension:nil];
        self.geomURL = [[NSBundle mainBundle]URLForResource:[view valueForKey:@"geom"] withExtension:nil];
        self.viewOrigin = [view valueForKey:@"ViewOrigin"];
        self.viewDir = [view valueForKey:@"ViewDir"];
        self.viewUpDir = [view valueForKey:@"ViewUpDir"];
        self.viewCenter = [view valueForKey:@"ViewCentre"];
        self.viewOutline = [view valueForKey:@"ViewOutline"];
        self.viewScale = [[view valueForKey:@"ViewScale"] intValue];
        self.printZoom = [[view valueForKey:@"printZoom"] intValue];
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
        Element* element = [[Element alloc] initWithId:elemId];
        
        NSArray* geoms = [elem valueForKey:@"geometry"];
        for (NSDictionary* geom in geoms) {
            NSString* data = [geom valueForKey:@"data"];
            [element addGeom:data];
        }

        [self.elements addObject:element];
    }
    
    [self.overlayView setElements:self.elements];
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
    //[self.pdfView setScale:scale];
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
