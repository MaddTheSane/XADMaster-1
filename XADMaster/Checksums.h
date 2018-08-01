#import "CSHandle.h"
#import "CSSubHandle.h"
#import "CSStreamHandle.h"

@interface CSHandle (Checksums)

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChecksum;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isChecksumCorrect) BOOL checksumCorrect;

@end

@interface CSSubHandle (Checksums)

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChecksum;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isChecksumCorrect) BOOL checksumCorrect;

@end

@interface CSStreamHandle (Checksums)

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChecksum;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isChecksumCorrect) BOOL checksumCorrect;

@end

#define CSChecksumWrapperHandle XADChecksumWrapperHandle

@interface CSChecksumWrapperHandle:CSHandle
{
	CSHandle *checksum;
}

-(instancetype)initWithHandle:(CSHandle *)handle checksumHandle:(CSHandle *)checksumhandle;

@property (NS_NONATOMIC_IOSONLY, readonly) off_t fileSize;
@property (NS_NONATOMIC_IOSONLY, readonly) off_t offsetInFile;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL atEndOfFile;
-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
-(void)pushBackByte:(int)byte;
-(NSInteger)readAtMost:(NSInteger)num toBuffer:(void *)buffer;
-(void)writeBytes:(NSInteger)num fromBuffer:(const void *)buffer;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChecksum;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isChecksumCorrect) BOOL checksumCorrect;

@end
