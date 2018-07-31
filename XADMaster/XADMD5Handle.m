#import "XADMD5Handle.h"
#if defined(USE_COMMON_CRYPTO) && USE_COMMON_CRYPTO
#include <CommonCrypto/CommonDigest.h>
typedef CC_MD5_CTX XADMD5;
#define XADMD5_Init CC_MD5_Init
#define XADMD5_Update CC_MD5_Update
#define XADMD5_Final CC_MD5_Final
#define XADMD5_DIGEST_LENGTH CC_MD5_DIGEST_LENGTH
#else
#include "Crypto/md5.h"
typedef MD5_CTX XADMD5;
#define XADMD5_Init MD5_Init
#define XADMD5_Update MD5_Update
#define XADMD5_Final MD5_Final
#define XADMD5_DIGEST_LENGTH MD5_DIGEST_LENGTH
#endif

@implementation XADMD5Handle
{
	NSData *digest;
	
	XADMD5 context;
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length correctDigest:(NSData *)correctdigest;
{
	if((self=[super initWithParentHandle:handle length:length]))
	{
		digest=[correctdigest copy];
	}
	return self;
}

-(void)dealloc
{
	[digest release];
	[super dealloc];
}

-(void)resetStream
{
	XADMD5_Init(&context);
	[parent seekToFileOffset:0];
}

-(int)streamAtMost:(int)num toBuffer:(void *)buffer
{
	int actual=[parent readAtMost:num toBuffer:buffer];
	XADMD5_Update(&context,buffer,actual);
	return actual;
}

-(BOOL)hasChecksum { return YES; }

-(BOOL)isChecksumCorrect
{
	if(digest.length!=XADMD5_DIGEST_LENGTH) return NO;

	XADMD5 copy;
	copy=context;

	uint8_t buf[XADMD5_DIGEST_LENGTH];
	XADMD5_Final(buf,&copy);

	return memcmp(digest.bytes,buf,XADMD5_DIGEST_LENGTH)==0;
}

-(double)estimatedProgress { return parent.estimatedProgress; }

@end


