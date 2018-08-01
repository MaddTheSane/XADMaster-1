#import <Foundation/Foundation.h>
#import "CSStreamHandle.h"

#define CSBlockStreamHandle XADBlockStreamHandle

@interface CSBlockStreamHandle:CSStreamHandle
{
	uint8_t *_currblock;
	off_t _blockstartpos;
	NSInteger _blocklength;
	BOOL _endofblocks;
}

// Intializers
//-(instancetype)initWithName:(NSString *)descname length:(off_t)length;
-(instancetype)initWithInputBufferForHandle:(CSHandle *)handle length:(off_t)length bufferSize:(NSInteger)buffersize;
-(instancetype)initAsCopyOf:(CSBlockStreamHandle *)other;

// Implemented by this class
-(void)seekToFileOffset:(off_t)offs;
-(void)resetStream;
-(NSInteger)streamAtMost:(NSInteger)num toBuffer:(void *)buffer;

// Internal methods
-(void)_readNextBlock;

// Implemented by subclasses
-(void)resetBlockStream;
-(NSInteger)produceBlockAtOffset:(off_t)pos;

// Called by subclasses
-(void)setBlockPointer:(uint8_t *)blockpointer;
-(void)endBlockStream;

@end
