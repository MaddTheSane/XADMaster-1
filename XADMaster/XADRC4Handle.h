#import <Foundation/Foundation.h>
#import "CSStreamHandle.h"

@class XADRC4Engine;

@interface XADRC4Handle:CSStreamHandle
{
	off_t startoffs;
	NSData *key;
	XADRC4Engine *rc4;
}

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
-(instancetype)initWithHandle:(CSHandle *)handle key:(NSData *)keydata NS_DESIGNATED_INITIALIZER;

-(void)resetStream;
-(NSInteger)streamAtMost:(NSInteger)num toBuffer:(void *)buffer;

@end

@interface XADRC4Engine:NSObject
{
	uint8_t s[256];
	int i,j;
}

+(XADRC4Engine *)engineWithKey:(NSData *)key;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
-(instancetype)initWithKey:(NSData *)key NS_DESIGNATED_INITIALIZER;

-(NSData *)encryptedData:(NSData *)data;

-(void)encryptBytes:(unsigned char *)bytes length:(NSInteger)length;
-(void)skipBytes:(NSInteger)length;

@end

