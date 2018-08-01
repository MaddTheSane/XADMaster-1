#import "CSStreamHandle.h"
#import "Checksums.h"
#import "Progress.h"

@interface XADChecksumHandle:CSStreamHandle
{
	uint32_t correctchecksum,summask,checksum;
}

-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length correctChecksum:(int)correct mask:(int)mask;

-(void)resetStream;
-(NSInteger)streamAtMost:(NSInteger)num toBuffer:(void *)buffer;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChecksum;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isChecksumCorrect) BOOL checksumCorrect;

@end
