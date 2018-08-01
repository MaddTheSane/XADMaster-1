#import "XADRC4Handle.h"



@implementation XADRC4Handle

-(instancetype)initWithHandle:(CSHandle *)handle key:(NSData *)keydata
{
	if(self=[super initWithParentHandle:handle length:[handle fileSize]])
	{
		startoffs=[parent offsetInFile];
		key=[keydata retain];
		rc4=nil;
	}
	return self;
}

-(void)dealloc
{
	[key release];
	[rc4 release];
	[super dealloc];
}

-(void)resetStream
{
	[parent seekToFileOffset:startoffs];
	[rc4 release];
	rc4=[(XADRC4Engine *)[XADRC4Engine alloc] initWithKey:key];
}

-(NSInteger)streamAtMost:(NSInteger)num toBuffer:(void *)buffer
{
	NSInteger actual=[parent readAtMost:num toBuffer:buffer];
	[rc4 encryptBytes:buffer length:actual];
	return actual;
}

@end





@implementation XADRC4Engine

+(XADRC4Engine *)engineWithKey:(NSData *)key
{
	return [[(XADRC4Engine *)[[self class] alloc] initWithKey:key] autorelease];
}

-(instancetype)initWithKey:(NSData *)key
{
	if((self=[super init]))
	{
		const uint8_t *keybytes=key.bytes;
		NSInteger keylength=key.length;

		for(i=0;i<256;i++) s[i]=i;

		j=0;
		for(i=0;i<256;i++)
		{
			j=(j+s[i]+keybytes[i%keylength])&255;
			int tmp=s[i]; s[i]=s[j]; s[j]=tmp;
		}

		i=j=0;
	}
	return self;
}

-(NSData *)encryptedData:(NSData *)data
{
	NSMutableData *res=[NSMutableData dataWithData:data];
	[self encryptBytes:res.mutableBytes length:(int)res.length];
	return [NSData dataWithData:res];
}

-(void)encryptBytes:(unsigned char *)bytes length:(NSInteger)length
{
	for(int n=0;n<length;n++)
	{
		i=(i+1)&255;
		j=(j+s[i])&255;
		int tmp=s[i]; s[i]=s[j]; s[j]=tmp;
		bytes[n]^=s[(s[i]+s[j])&255];
	}
}

-(void)skipBytes:(NSInteger)length
{
	for(int n=0;n<length;n++)
	{
		i=(i+1)&255;
		j=(j+s[i])&255;
		int tmp=s[i]; s[i]=s[j]; s[j]=tmp;
	}
}

@end

