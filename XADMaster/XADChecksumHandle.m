#import "XADChecksumHandle.h"

@implementation XADChecksumHandle

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length correctChecksum:(int)correct mask:(int)mask
{
	if((self=[super initWithParentHandle:handle length:length]))
	{
		correctchecksum=correct;
		summask=mask;
	}
	return self;
}

-(void)resetStream
{
	[parent seekToFileOffset:0];
	checksum=0;
}

-(NSInteger)streamAtMost:(NSInteger)num toBuffer:(void *)buffer
{
	NSInteger actual=[parent readAtMost:num toBuffer:buffer];

	uint8_t *bytes=buffer;
	for(NSInteger i=0;i<actual;i++) checksum+=bytes[i];

	return actual;
}

-(BOOL)hasChecksum { return YES; }

-(BOOL)isChecksumCorrect
{
	return (checksum&summask)==(correctchecksum&summask);
}

-(double)estimatedProgress { return parent.estimatedProgress; }

@end

