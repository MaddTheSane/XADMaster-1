#import "CSStreamHandle.h"

#if !__LP64__
#define _LZMA_UINT32_IS_ULONG
#endif

#define Byte LzmaByte
#define UInt16 LzmaUInt16
#define UInt32 LzmaUInt32
#define UInt64 LzmaUInt64
#import "lzma/Lzma2Dec.h"
#undef Byte
#undef UInt32
#undef UInt16
#undef UInt64

@interface XADLZMA2Handle:CSStreamHandle
{
	off_t startoffs;

	CLzma2Dec lzma;

	uint8_t inbuffer[16*1024];
	int bufbytes,bufoffs;
	BOOL seekback;
}

-(instancetype)initWithHandle:(CSHandle *)handle propertyData:(NSData *)propertydata;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length propertyData:(NSData *)propertydata;

-(void)setSeekBackAtEOF:(BOOL)seekateof;

-(void)resetStream;
-(NSInteger)streamAtMost:(NSInteger)num toBuffer:(void *)buffer;

@end
