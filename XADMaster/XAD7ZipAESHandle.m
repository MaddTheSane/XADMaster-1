#import "XAD7ZipAESHandle.h"

#if defined(USE_COMMON_CRYPTO) && USE_COMMON_CRYPTO
#include <CommonCrypto/CommonCrypto.h>
typedef CC_SHA256_CTX XADSHA256;
#define XADSHA256_Init CC_SHA256_Init
#define XADSHA256_Final CC_SHA256_Final
#define XADSHA256_Update CC_SHA256_Update
#else
#include "Crypto/sha.h"
typedef SHA_CTX XADSHA256;
#define XADSHA256_Init SHA256_Init
#define XADSHA256_Final SHA256_Final
#define XADSHA256_Update SHA256_Update
#endif

@implementation XAD7ZipAESHandle

+(int)logRoundsForPropertyData:(NSData *)propertydata
{
	NSInteger length=propertydata.length;
	const uint8_t *bytes=propertydata.bytes;

	if(length<1) return -1;

	return bytes[0]&0x3f;
}

+(NSData *)saltForPropertyData:(NSData *)propertydata
{
	NSInteger length=propertydata.length;
	const uint8_t *bytes=propertydata.bytes;

	if(length<1) return nil;

	uint8_t flags=bytes[0];
	if(flags&0xc0)
	{
		if(length<2) return nil;

		if(flags&0x80)
		{
			int saltlength=(bytes[1]>>4)+1;
			if(length<2+saltlength) return nil;
			return [NSData dataWithBytes:&bytes[2] length:saltlength];
		}
	}

	return [NSData data];
}

+(NSData *)IVForPropertyData:(NSData *)propertydata
{
	NSInteger length=propertydata.length;
	const uint8_t *bytes=propertydata.bytes;

	if(length<1) return nil;

	uint8_t flags=bytes[0];
	if(flags&0xc0)
	{
		if(length<2) return nil;

		int saltlength=0;
		if(flags&0x80) saltlength=(bytes[1]>>4)+1;

		if(flags&0x40)
		{
			int ivlength=(bytes[1]&0x0f)+1;
			if(length<2+saltlength+ivlength) return nil;

			return [NSData dataWithBytes:&bytes[2+saltlength] length:ivlength];
		}
	}

	return [NSData data];
}

+(NSData *)keyForPassword:(NSString *)password salt:(NSData *)salt logRounds:(int)logrounds
{
	uint8_t key[32];

	NSInteger passchars=password.length;
	NSInteger passlength=passchars*2;
	uint8_t passbytes[passlength];
	for(int i=0;i<passchars;i++)
	{
		unichar c=[password characterAtIndex:i];
		passbytes[2*i]=c;
		passbytes[2*i+1]=c>>8;
	}

	NSInteger saltlength=salt.length;
	const uint8_t *saltbytes=salt.bytes;

	if(logrounds==0x3f)
	{
		NSInteger passcopylength=passlength;
		if(passcopylength+saltlength>sizeof(key)) passcopylength=sizeof(key)-saltlength;

		memset(key,0,sizeof(key));
		memcpy(&key[0],saltbytes,saltlength);
		memcpy(&key[saltlength],passbytes,passcopylength);
	}
	else
	{
		XADSHA256 sha;
		XADSHA256_Init(&sha);

		uint64_t numrounds=1LL<<logrounds;

		for(uint64_t i=0;i<numrounds;i++)
		{
			XADSHA256_Update(&sha,saltbytes,(CC_LONG)saltlength);
			XADSHA256_Update(&sha,passbytes,(CC_LONG)passlength);
			XADSHA256_Update(&sha,(uint8_t[8]) {
				i&0xff,(i>>8)&0xff,(i>>16)&0xff,(i>>24)&0xff,
				(i>>32)&0xff,(i>>40)&0xff,(i>>48)&0xff,(i>>56)&0xff,
			},8);
		}

		XADSHA256_Final(key,&sha);
	}

	return [NSData dataWithBytes:key length:sizeof(key)];
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length key:(NSData *)keydata IV:(NSData *)ivdata
{
	if(self=[super initWithParentHandle:handle length:length])
	{
		startoffs=[handle offsetInFile];

		NSInteger ivlength=ivdata.length;
		const uint8_t *ivbytes=ivdata.bytes;
		memset(iv,0,sizeof(iv));
		memcpy(iv,ivbytes,ivlength);

		const uint8_t *keybytes=keydata.bytes;
		aes_decrypt_key256(keybytes,&aes);
	}

	return self;
}

-(void)resetBlockStream
{
	[parent seekToFileOffset:startoffs];
	[self setBlockPointer:buffer];
	memcpy(block,iv,sizeof(iv));
}

-(int)produceBlockAtOffset:(off_t)pos
{
	NSInteger actual=[parent readAtMost:sizeof(buffer) toBuffer:buffer];
	if(actual==0) return -1;

	aes_cbc_decrypt(buffer,buffer,actual&~15,block,&aes);

	return (int)actual;
}

@end
