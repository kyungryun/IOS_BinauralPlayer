//
//  Binaural.m
//  BinauralPlayer
//
//  Created by kyungryun Choi on 2018. 6. 1..
//  Copyright © 2018년 kyungryun Choi. All rights reserved.
//


#import "Binaural.h"
#import "BinauralPlayer-Swift.h"

#pragma mark - Audio Processing

static void CheckError(OSStatus error, const char *operation)
{
    if (error == noErr) return;
    
    char errorString[20];
    // see if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(errorString, "%d", (int)error);
    
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    
    exit(1);
}

@implementation Binaural
static int horiAngle = 0;
static int elev = 0;
static bool isRecording = true;
OSStatus error;

STALibrary *lib;
BinauralRendering *binauralRendering;
VideoViewController *video;
STAMutableAudioMixInputParameters *inputParams;

float input[4096]={0},outL[4096]={0},outR[4096]={0};
Float64 nowFrames = 0;
int nowFrameNumber = 0;
float numberFrame = 0;
bool binauralFlag = true;
FILE *writeFile;

- (void)setBinaural : (NSURL*) url audioAsset:(AVAssetTrack*)audioAsset{
    lib = [[STALibrary alloc]init :2];
    
    video = [[VideoViewController alloc]init];
    
    binauralRendering = [[BinauralRendering alloc] init];
    [binauralRendering setAudio:url];
    [binauralRendering initDictionary];
    inputParams = [STAMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioAsset];
    
    printf("%d %d\n",binauralFlag, isRecording);
}
- (void)modeBinaural{
    binauralFlag = !binauralFlag;
    if(binauralFlag){
        [inputParams changeMode];
        isRecording = true;
    }else{
        [inputParams changeMode];
        isRecording = false;
    }
    printf("%d %d\n",binauralFlag, isRecording);
}
- (void)setMode{
    if(!binauralFlag){
        [inputParams changeMode];
    }
    isRecording = true;
}
- (void)setAngle : (int) angle{
    horiAngle = angle;
    [inputParams setAngle:horiAngle Elevation:elev];
}
- (void)setElev : (int) _elev{
    elev = _elev;
    [inputParams setAngle:horiAngle Elevation:elev];
}
- (void)recordingBinaural {
    isRecording = !isRecording;
}
- (void)renderingBinaural {
    [binauralRendering rendering];
}


//현재 프레임 번호 저장
- (void)setFrames : (Float64) frames {
    nowFrames = frames;
    nowFrameNumber = round(nowFrames/4096);
}
- (STAMutableAudioMixInputParameters*)getAudioParameter{
    [inputParams connectCallbacks];
    [self setWriting];
    return inputParams;
}

- (void)setWriting {
    [inputParams setProcessingBlock:^(MTAudioProcessingTapRef tap, CMItemCount numberFrames, MTAudioProcessingTapFlags flags, AudioBufferList *bufferListInOut, CMItemCount *numberFramesOut, MTAudioProcessingTapFlags *flagsOut) {
        if(isRecording){
            [binauralRendering setDictionary:horiAngle elev:elev frameNumber: nowFrameNumber];
        }
    }];
}

@end

