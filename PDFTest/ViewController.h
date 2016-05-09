//
//  ViewController.h
//  PDFTest
//
//  Created by Priya Rajagopal on 4/25/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLKit/GLKVector2.h"

@interface ViewController : UIViewController

-(GLKVector2)convertToPixel:(float*)pt3d;
@end

