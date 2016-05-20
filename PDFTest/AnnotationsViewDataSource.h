//
//  AnnotationsViewDataSource.h
//  PDFTest
//
//  Created by Priya Rajagopal on 5/20/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AnnotationsViewDataSource <NSObject>
@optional
-(NSArray<UIBezierPath*>*)annotationPaths;
@end
