//
//  PDFGeometryViewModel.h
//  PDFTest
//
//  Created by Priya Rajagopal on 5/12/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Element.h"

@import UIKit;

@interface PDFDetails:NSObject
@property (nonatomic,readonly) NSString* name;
@property (nonatomic,readonly) NSURL* pdfURL;
@property (nonatomic,readonly) NSURL* geomURL;
@property (nonatomic,readonly) BOOL onGeometryProcessed;
@property (nonatomic,readonly) NSArray <Element*>* elements;

-(GLKVector2)convertToPixel:(float*)pt3d inRect:(CGRect)rect;
-(void)loadGeometryElementsWithCompletionHandler:(void(^)(NSArray<Element*>*))handler ;

@end

@interface PDFGeometryViewModel : NSObject

@property (nonatomic,readonly) NSURL* geomInfoURL;
@property (nonatomic, readonly) NSArray<PDFDetails*>* pdfs;

-(instancetype) initWithGeometryURL:(NSURL*)geomInfoURL ;

@end
