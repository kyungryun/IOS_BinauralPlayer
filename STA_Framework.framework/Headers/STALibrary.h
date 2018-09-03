//
//  STALibrary.h
//  vDSP_Framework
//
//  Created by sonic on 2018. 1. 24..
//  Copyright © 2018년 sonic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>

@interface STALibrary : NSObject
- (instancetype) init:(int)channelCount;
- (void) monoBinauralRendering:(int16_t *)inputFrame outBufferL:(int16_t *)outBufferL outBufferR:(int16_t *)outBufferR horiAngle:(int)horiAngle elevAngle:(int)elevAngle channel:(int)channel;
- (void) monoBinauralRenderingF:(float *)inputFrame outBufferL:(float *)outBufferL outBufferR:(float *)outBufferR horiAngle:(int)horiAngle elevAngle:(int)elevAngle channel:(int)channel;
- (void) bufferFlush;
@end
