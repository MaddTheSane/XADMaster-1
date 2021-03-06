#import "CSStreamHandle.h"

#if !__LP64__
#define _LZMA_UINT32_IS_ULONG
#endif

#define Byte LzmaByte
#define UInt16 LzmaUInt16
#define UInt32 LzmaUInt32
#define UInt64 LzmaUInt64
#import "lzma/LzmaDec.h"
#undef Byte
#undef UInt32
#undef UInt16
#undef UInt64

@interface XADLZMAHandle:CSStreamHandle
{
	off_t startoffs;

	CLzmaDec lzma;

	uint8_t inbuffer[16*1024];
	int bufbytes,bufoffs;
}

-(instancetype)initWithHandle:(CSHandle *)handle propertyData:(NSData *)propertydata;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length propertyData:(NSData *)propertydata;

-(void)resetStream;
-(int)streamAtMost:(int)num toBuffer:(void *)buffer;

@end
