//
//  CTMDecoder.mm
//  PDFTest
//
//  Created by Christian Utama on 5/5/16.
//  Copyright © 2016 invicara. All rights reserved.
//


#import "CTMDecoder.h"
#import "openctm/openctm.h"

@interface CTMDecoder()
@property (nonatomic,assign) CTMcontext ctmCtx;
@end

@implementation CTMDecoder

struct octm_buffer
{
    char* data;
    unsigned int current;
    
    octm_buffer(size_t len) : data(new char[len]), current(0) {};
    
    ~octm_buffer()
    {
        delete [] data;
    }
};

static CTMuint readfn(void * aBuf, CTMuint aCount, void * aUserData)
{
    octm_buffer* buffer = (octm_buffer*) aUserData;
    memcpy(aBuf, buffer->data + buffer->current, aCount);
    buffer->current += aCount;
    return aCount;
}

-(CTMDecoder*) initWithData:(NSData*)data
{
    self.ctmCtx = ctmNewContext(CTM_IMPORT);
    octm_buffer buffer(data.length);
    //buffer.data = (const char*)[data bytes];
    [data getBytes:buffer.data length:data.length];
    ctmLoadCustom(self.ctmCtx, readfn, &buffer);
    return self;
}

-(const float*) getPoints
{
    return ctmGetFloatArray(self.ctmCtx, CTM_VERTICES);
}

-(unsigned int) getPointCount
{
    return ctmGetInteger(self.ctmCtx, CTM_VERTEX_COUNT);
}

-(NSArray*) copyPoints
{
    const float* pts = [self getPoints];
    unsigned int cnt = [self getPointCount] * 3;
    NSMutableArray* arr = [[NSMutableArray alloc] initWithCapacity: cnt];
    for (int i=0; i < cnt; i++) {
        [arr addObject:[NSNumber numberWithFloat:pts[i]]];
    }
    return arr;
}

-(void)dealloc
{
    if (self.ctmCtx != NULL)
        ctmFreeContext(self.ctmCtx);
}

@end