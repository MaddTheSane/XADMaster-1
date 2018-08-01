#import "CSBlockStreamHandle.h"

@interface XAD7ZipBranchHandle:CSBlockStreamHandle
{
	off_t startoffs;
	uint8_t inbuffer[4096];
	NSInteger leftoverstart,leftoverlength;
	uint32_t baseoffset;
}

-(instancetype)initWithHandle:(CSHandle *)handle;
-(instancetype)initWithHandle:(CSHandle *)handle propertyData:(NSData *)propertydata;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length propertyData:(NSData *)propertydata;

-(void)resetBlockStream;
-(NSInteger)produceBlockAtOffset:(off_t)pos;

-(NSInteger)decodeBlock:(uint8_t *)block length:(NSInteger)length offset:(off_t)pos;

@end

@interface XAD7ZipBCJHandle:XAD7ZipBranchHandle { uint32_t state; }
@end

@interface XAD7ZipPPCHandle:XAD7ZipBranchHandle
@end

@interface XAD7ZipIA64Handle:XAD7ZipBranchHandle
@end

@interface XAD7ZipARMHandle:XAD7ZipBranchHandle
@end

@interface XAD7ZipThumbHandle:XAD7ZipBranchHandle
@end

@interface XAD7ZipSPARCHandle:XAD7ZipBranchHandle
@end
