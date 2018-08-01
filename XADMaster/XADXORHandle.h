#import "CSHandle.h"

@interface XADXORHandle:CSHandle
{
	NSData *password;
	const uint8_t *passwordbytes;
	NSInteger passwordlength;
}

-(instancetype)initWithHandle:(CSHandle *)handle password:(NSData *)passdata;
-(instancetype)initAsCopyOf:(XADXORHandle *)other;

@property (NS_NONATOMIC_IOSONLY, readonly) off_t fileSize;
@property (NS_NONATOMIC_IOSONLY, readonly) off_t offsetInFile;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL atEndOfFile;

-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
-(NSInteger)readAtMost:(NSInteger)num toBuffer:(void *)buffer;

@end
