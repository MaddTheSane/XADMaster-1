#import "XADRARAESHandle.h"
#import "RARBug.h"

#if defined(USE_COMMON_CRYPTO) && USE_COMMON_CRYPTO
#include <CommonCrypto/CommonDigest.h>
//TODO: implement
//#include <CommonCrypto/CommonCryptor.h>
typedef CC_SHA1_CTX XADSHA1;
#define XADSHA1_Init CC_SHA1_Init
#define XADSHA1_Final CC_SHA1_Final
#define XADSHA1_Update CC_SHA1_Update
#define XADSHA1_DIGEST_LENGTH CC_SHA1_DIGEST_LENGTH
#define XADSHA1_Update_WithRARBug CC_SHA1_Update_WithRARBug
#else
#include "Crypto/sha.h"
typedef SHA_CTX XADSHA1;
#define XADSHA1_Init SHA1_Init
#define XADSHA1_Final SHA1_Final
#define XADSHA1_Update SHA1_Update
#define XADSHA1_DIGEST_LENGTH SHA1_DIGEST_LENGTH
#define XADSHA1_Update_WithRARBug SHA1_Update_WithRARBug
#endif

@implementation XADRARAESHandle

+(NSData *)keyForPassword:(NSString *)password salt:(NSData *)salt brokenHash:(BOOL)brokenhash
{
	uint8_t keybuf[2*16];

	NSInteger length=password.length;
	if(length>126) length=126;

	uint8_t passbuf[length*2+8];
	for(NSInteger i=0;i<length;i++)
	{
		unichar c=[password characterAtIndex:i];
		passbuf[2*i]=c & 0xFF;
		passbuf[2*i+1]=c>>8;
	}

	NSInteger buflength=length*2;

	if(salt)
	{
		memcpy(passbuf+2*length,[salt bytes],8);
		buflength+=8;
	}

	XADSHA1 sha;
	XADSHA1_Init(&sha);

	for(int i=0;i<0x40000;i++)
	{
		XADSHA1_Update_WithRARBug(&sha,passbuf,buflength,brokenhash);

		uint8_t num[3]={i,i>>8,i>>16};
		XADSHA1_Update_WithRARBug(&sha,num,3,brokenhash);

		if(i%0x4000==0)
		{
			XADSHA1 tmpsha=sha;
			uint8_t digest[XADSHA1_DIGEST_LENGTH];
			XADSHA1_Final(digest,&tmpsha);
			keybuf[i/0x4000]=digest[19];
		}
	}

	uint8_t digest[XADSHA1_DIGEST_LENGTH];
	XADSHA1_Final(digest,&sha);

	for(int i=0;i<16;i++) keybuf[i+16]=digest[i^3];

	return [NSData dataWithBytes:keybuf length:sizeof(keybuf)];
}

-(id)initWithHandle:(CSHandle *)handle key:(NSData *)keydata
{
	return [self initWithHandle:handle length:CSHandleMaxLength key:keydata];
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length key:(NSData *)keydata
{
	if((self=[super initWithParentHandle:handle length:length]))
	{
		startoffs=[handle offsetInFile];

		const uint8_t *keybytes=keydata.bytes;
		memcpy(iv,&keybytes[0],16);
		aes_decrypt_key128(&keybytes[16],&aes);
	}
	return self;
}

-(id)initWithHandle:(CSHandle *)handle RAR5Key:(NSData *)keydata IV:(NSData *)ivdata
{
	return [self initWithHandle:handle length:CSHandleMaxLength RAR5Key:keydata IV:ivdata];
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length RAR5Key:(NSData *)keydata IV:(NSData *)ivdata
{
	if(self=[super initWithParentHandle:handle length:length])
	{
		startoffs=[handle offsetInFile];

		memcpy(iv,[ivdata bytes],16);
		aes_decrypt_key256(keydata.bytes,&aes);
	}
	return self;
}

-(void)resetStream
{
	[parent seekToFileOffset:startoffs];
	memcpy(block,iv,sizeof(iv));
}

-(int)streamAtMost:(int)num toBuffer:(void *)buffer
{
	uint8_t *bytebuffer=buffer;
	int bufferpos=streampos&15;
	int bufferlength=(-streampos)&15;
	int total=0;

	if(num<=bufferlength)
	{
		memcpy(&bytebuffer[total],&blockbuffer[bufferpos],num);
		return num;
	}

	memcpy(&bytebuffer[total],&blockbuffer[bufferpos],bufferlength);
	total+=bufferlength;

	int remaining=num-total;
	int remainingblocklength=remaining&~15;

	if(remainingblocklength)
	{
		int actual=[parent readAtMost:remainingblocklength toBuffer:&bytebuffer[total]];
		int actualblocklength=actual&~15;
		aes_cbc_decrypt(&bytebuffer[total],&bytebuffer[total],actualblocklength,block,&aes);
		total+=actualblocklength;

		if(actualblocklength!=remainingblocklength)
		{
			[self endStream];
			return total;
		}
	}

	int endlength=num-total;
	if(endlength)
	{
		int actual=[parent readAtMost:16 toBuffer:blockbuffer];
		if(actual!=16)
		{
			[self endStream];
			return total;
		}

		aes_cbc_decrypt(blockbuffer,blockbuffer,16,block,&aes);

		memcpy(&bytebuffer[total],&blockbuffer[0],endlength);
		total+=endlength;
	}

	return total;
}

@end
