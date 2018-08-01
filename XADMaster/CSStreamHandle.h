#import <Foundation/Foundation.h>
#import "CSHandle.h"
#import "CSInputBuffer.h"

#define CSStreamHandle XADStreamHandle

@interface CSStreamHandle:CSHandle
{
	off_t streampos,streamlength;
	BOOL needsreset,endofstream;
	int nextstreambyte;

	@public
	CSInputBuffer *input;
}

// Initializers
//-(instancetype)initWithName:(NSString *)descname;
//-(instancetype)initWithName:(NSString *)descname length:(off_t)length;
-(instancetype)initWithParentHandle:(CSHandle *)handle;
-(instancetype)initWithParentHandle:(CSHandle *)handle length:(off_t)length;
-(instancetype)initWithInputBufferForHandle:(CSHandle *)handle;
-(instancetype)initWithInputBufferForHandle:(CSHandle *)handle length:(off_t)length;
-(instancetype)initWithInputBufferForHandle:(CSHandle *)handle bufferSize:(NSInteger)buffersize;
-(instancetype)initWithInputBufferForHandle:(CSHandle *)handle length:(off_t)length bufferSize:(NSInteger)buffersize;
-(instancetype)initAsCopyOf:(CSStreamHandle *)other;

// Implemented by this class
@property (NS_NONATOMIC_IOSONLY, readonly) off_t fileSize;
@property (NS_NONATOMIC_IOSONLY, readonly) off_t offsetInFile;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL atEndOfFile;
-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
-(NSInteger)readAtMost:(NSInteger)num toBuffer:(void *)buffer;

// Implemented by subclasses
-(void)resetStream;
-(NSInteger)streamAtMost:(NSInteger)num toBuffer:(void *)buffer;

// Called by subclasses
-(void)endStream;
-(BOOL)_prepareStreamSeekTo:(off_t)offs;
-(void)setStreamLength:(off_t)length;
-(void)setInputBuffer:(CSInputBuffer *)inputbuffer;

@end
