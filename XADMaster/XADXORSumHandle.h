#import "CSStreamHandle.h"
#import "Checksums.h"
#import "Progress.h"

@interface XADXORSumHandle:CSStreamHandle
{
	uint8_t correctchecksum,checksum;
}

-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length correctChecksum:(uint8_t)correct;

-(void)resetStream;
-(NSInteger)streamAtMost:(NSInteger)num toBuffer:(void *)buffer;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChecksum;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isChecksumCorrect) BOOL checksumCorrect;

@end
