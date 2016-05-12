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

@interface PDFGeometryViewModel : NSObject

@property (nonatomic,readonly) NSURL* geomInfoURL;
@property (nonatomic,readonly) NSURL* pdfURL;
@property (nonatomic,readonly) NSURL* geomURL;

@property (nonatomic,readonly) NSArray <Element*>* elements;

-(instancetype) initWithGeometryURL:(NSURL*)geomInfoURL ;

-(GLKVector2)project2d:(float*)pt3d
            withOrigin:(float*)o
              withZdir:(float*)z
              withYdir:(float*)y;

//-(GLKVector2)convertToPixel:(float*)pt3d inView:(UIView*)view;
-(GLKVector2)convertToPixel:(float*)pt3d inRect:(CGRect)rect;

@end
