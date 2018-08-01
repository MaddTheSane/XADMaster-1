#import <Foundation/Foundation.h>
#import "CSHandle.h"

@interface XADBlockHandle:CSHandle
{
	off_t currpos,length;

	int numblocks,blocksize;
	off_t *blockoffsets;
}

-(instancetype)initWithHandle:(CSHandle *)handle blockSize:(int)size;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)maxlength blockSize:(int)size;

//-(void)addBlockAt:(off_t)start;
-(void)setBlockChain:(uint32_t *)blocktable numberOfBlocks:(int)totalblocks
firstBlock:(uint32_t)first headerSize:(off_t)headersize;

@property (NS_NONATOMIC_IOSONLY, readonly) off_t fileSize;
@property (NS_NONATOMIC_IOSONLY, readonly) off_t offsetInFile;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL atEndOfFile;

-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
-(NSInteger)readAtMost:(NSInteger)num toBuffer:(void *)buffer;

@end
