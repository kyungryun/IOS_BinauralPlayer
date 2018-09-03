//
//  BinauralRendering.m
//  BinauralPlayer
//
//  Created by kyungryun Choi on 2018. 6. 1..
//  Copyright © 2018년 kyungryun Choi. All rights reserved.
//

#import "BinauralRendering.h"
@implementation BinauralRendering

NSMutableDictionary *frameList;
NSURL* sourceURL;
NSURL *recordFile;

ExtAudioFileRef sourceFile = 0;
AudioFileID audioFile;
OSStatus error = noErr;
- (void)initDictionary{
    frameList = [NSMutableDictionary dictionary];
    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    recordFile = [NSURL URLWithString:[documentsDirectory stringByAppendingPathComponent: @"audio.caf"]];
    NSLog(@"recordFile : %@",recordFile);
    lib = [[STALibrary alloc] init:(2)];

}
- (void)setAudio : (NSURL*) URL{
    sourceURL = URL;
    NSLog(@"sourceURL : %@",sourceURL);
}
- (void)setDictionary: (int)angle elev:(int)elev frameNumber:(int)frameNumber{
    [frameList setObject:@{@"angle" : [NSNumber numberWithInt:angle], @"elev" : [NSNumber numberWithInt:elev]} forKey:[NSNumber numberWithInt:frameNumber]];
}


- (void)rendering{
    /*AudioFile Open*/
    error = ExtAudioFileOpenURL((__bridge CFURLRef _Nonnull)(sourceURL), &sourceFile);
    if(error != noErr){
        printf("open error \n");
    }

    AudioStreamBasicDescription sourceFormat = {};
    UInt32 size = sizeof(sourceFormat);
    error = ExtAudioFileGetProperty(sourceFile, kExtAudioFileProperty_FileDataFormat, &size, &sourceFormat);
    if(error != noErr){
        printf("error\n");
    }// Setup the output file format.
    AudioStreamBasicDescription destinationFormat = {};
    destinationFormat.mSampleRate = 44100;
    destinationFormat.mFormatID = kAudioFormatLinearPCM;
    destinationFormat.mChannelsPerFrame = sourceFormat.mChannelsPerFrame;
    destinationFormat.mBitsPerChannel = 16;
    destinationFormat.mBytesPerPacket = 4;
    destinationFormat.mBytesPerFrame = 4;
    destinationFormat.mFramesPerPacket = 1;
    destinationFormat.mFormatFlags =  kLinearPCMFormatFlagIsSignedInteger;

    // Create the destination audio file.
    ExtAudioFileRef destinationFile = 0;
    ExtAudioFileCreateWithURL((__bridge CFURLRef)recordFile, kAudioFileCAFType, &destinationFormat, NULL, kAudioFileFlags_EraseFile, &destinationFile);
    /*
     set the client format - The format must be linear PCM (kAudioFormatLinearPCM)
     You must set this in order to encode or decode a non-PCM file data format
     You may set this on PCM files to specify the data format used in your calls to read/write
     */
    AudioStreamBasicDescription clientFormat;

    clientFormat = destinationFormat;

    size = sizeof(clientFormat);
    ExtAudioFileSetProperty(sourceFile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat);

    size = sizeof(clientFormat);
    ExtAudioFileSetProperty(destinationFile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat);

    // Get the audio converter.
    AudioConverterRef converter = 0;

    size = sizeof(converter);
    ExtAudioFileGetProperty(destinationFile, kExtAudioFileProperty_AudioConverter, &size, &converter);

    // Setup buffers
    UInt16 bufferByteSize = 16384;
    int16_t sourceBuffer[8192]={0};
    int framecnt = 0;

    SInt64 sourceFrameOffset = 0;

    // Do the read and write - the conversion is done on and by the write call.

    printf("Converting...\n");


    while (YES) {

        // Set up output buffer list.
        AudioBufferList fillBufferList = {};

        fillBufferList.mNumberBuffers = 1;
        fillBufferList.mBuffers[0].mNumberChannels = clientFormat.mChannelsPerFrame;
        fillBufferList.mBuffers[0].mDataByteSize = bufferByteSize;
        fillBufferList.mBuffers[0].mData = sourceBuffer;

        /*
         The client format is always linear PCM - so here we determine how many frames of lpcm
         we can read/write given our buffer size
         */
        UInt32 numberOfFrames = 0;
        if (clientFormat.mBytesPerFrame > 0) {
            // Handles bogus analyzer divide by zero warning mBytesPerFrame can't be a 0 and is protected by an Assert.
            numberOfFrames = bufferByteSize / clientFormat.mBytesPerFrame;
        }

        ExtAudioFileRead(sourceFile, &numberOfFrames, &fillBufferList);

        if (!numberOfFrames) {
            break;
        }

        /**********************************************************************************************/
        int angle = 0;
        int elev = 0;
        // framecnt 값으로 Binaural을 적용할 프레임 결정
        if([frameList objectForKey:[NSNumber numberWithInt:framecnt]]){
            sourceFrameOffset = 0;
            angle = [frameList[[NSNumber numberWithInt:framecnt]][@"angle"] intValue];
            elev = [frameList[[NSNumber numberWithInt:framecnt]][@"elev"] intValue];
            for(int i=0 ; i<framecnt ; i++){
                sourceFrameOffset +=4096;
            }
        }else{
            angle = elev = 0;
        }

        for(int k=0;k<4096;k++){
            input[k] = *((int16_t *)(fillBufferList.mBuffers[0].mData)+2*k)*0.2 + *((int16_t *)(fillBufferList.mBuffers[0].mData)+2*k+1)*0.2;
        }
        for(int k=0;k<4;k++){
            memset(outR, 0, sizeof(outR));
            memset(outL, 0, sizeof(outL));

            [lib monoBinauralRendering:(input+1024*k) outBufferL:outL outBufferR:outR horiAngle:angle elevAngle:elev channel:0];

            for(int i=0 ; i<1024 ; i++){
                *((int16_t*)fillBufferList.mBuffers[0].mData + 2048*k + 2*i) = 3*outL[i];
                *((int16_t*)fillBufferList.mBuffers[0].mData + 2048*k + 2*i + 1) = 3*outR[i];
            }

        }
        
        /**********************************************************************************************/
        framecnt++;
        sourceFrameOffset += numberOfFrames;

        ExtAudioFileWrite(destinationFile, numberOfFrames, &fillBufferList);

    }

    // Cleanup


    ExtAudioFileDispose(destinationFile);
    ExtAudioFileDispose(sourceFile);
    AudioConverterDispose(converter);
}

@end


