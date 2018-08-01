#import "Scanning.h"

typedef struct ByteString
{
	const uint8_t *bytes;
	NSInteger length;
} ByteString;

static int MatchByteString(const uint8_t *bytes,NSInteger available,off_t offset,void *context)
{
	ByteString *bs=context;
	if(available<bs->length) return NO;
	return memcmp(bytes,bs->bytes,bs->length)==0;
}


@implementation CSHandle (Scanning)

-(BOOL)scanForByteString:(const void *)bytes length:(NSInteger)length
{
	ByteString bs={ .bytes=bytes, .length=length };
	return [self scanUsingMatchingFunction:MatchByteString maximumLength:length context:&bs];
}

-(int)scanUsingMatchingFunction:(CSByteMatchingFunctionPointer)function
maximumLength:(NSInteger)maximumlength
{
	return [self scanUsingMatchingFunction:function maximumLength:maximumlength context:NULL];
}

-(int)scanUsingMatchingFunction:(CSByteMatchingFunctionPointer)function
maximumLength:(NSInteger)maximumlength context:(void *)contextptr
{
	uint8_t buffer[65536];

	off_t pos=0;
	NSInteger actual=[self readAtMost:sizeof(buffer) toBuffer:buffer];

	while(actual>=maximumlength)
	{
		for(int i=0;i<=actual-maximumlength;i++)
		{
			int res=function(&buffer[i],actual-i,pos++,contextptr);
			if(res)
			{
				[self skipBytes:i-actual];
				return res;
			}
		}

		memcpy(buffer,&buffer[actual-maximumlength+1],maximumlength-1);
		actual=[self readAtMost:sizeof(buffer)-maximumlength+1 toBuffer:&buffer[maximumlength-1]]+maximumlength-1;
	}

	for(int i=0;i<actual;i++)
	{
		int res=function(&buffer[i],actual-i,pos++,contextptr);
		if(res)
		{
			[self skipBytes:i-actual];
			return res;
		}
	}

	return 0;
}

@end

