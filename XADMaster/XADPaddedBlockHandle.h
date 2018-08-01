#import "CSHandle.h"


@interface XADPaddedBlockHandle:CSHandle
{
	off_t startoffset;
	int logicalsize,physicalsize;
}

-(instancetype)initWithHandle:(CSHandle *)handle startOffset:(off_t)start
logicalBlockSize:(int)logical physicalBlockSize:(int)physical;

@property (NS_NONATOMIC_IOSONLY, readonly) off_t fileSize;
@property (NS_NONATOMIC_IOSONLY, readonly) off_t offsetInFile;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL atEndOfFile;

-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
-(NSInteger)readAtMost:(NSInteger)num toBuffer:(void *)buffer;

@end
