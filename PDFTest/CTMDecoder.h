//
//  CTMDecoder.h
//  PDFTest
//
//  Created by Christian Utama on 5/5/16.
//  Copyright © 2016 invicara. All rights reserved.
//

#ifndef CTMDecoder_h
#define CTMDecoder_h

#import <Foundation/Foundation.h>

@interface CTMDecoder : NSObject

-(CTMDecoder*) initWithData:(NSData*)data;
-(const float*) getPoints;
-(unsigned int) getPointCount;
-(NSArray*) copyPoints;
@end


#endif /* CTMDecoder_h */
