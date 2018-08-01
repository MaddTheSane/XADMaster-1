#import "CSStreamHandle.h"
#import "Checksums.h"
#import "Progress.h"


@interface XADMD5Handle:CSStreamHandle

-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length correctDigest:(NSData *)correctdigest;

-(void)resetStream;
-(NSInteger)streamAtMost:(NSInteger)num toBuffer:(void *)buffer;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChecksum;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isChecksumCorrect) BOOL checksumCorrect;

@property (readonly) double estimatedProgress;

@end

