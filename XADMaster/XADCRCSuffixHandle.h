#import "CSStreamHandle.h"
#import "Checksums.h"
#import "Progress.h"
#import "CRC.h"

@interface XADCRCSuffixHandle:CSStreamHandle
{
	CSHandle *crcparent;

	int crcsize;
	BOOL bigend;
	uint32_t crc,initcrc,compcrc;
	const uint32_t *table;

	BOOL didtest,wascorrect;
}

+(XADCRCSuffixHandle *)IEEECRC32SuffixHandleWithHandle:(CSHandle *)handle CRCHandle:(CSHandle *)crchandle
bigEndianCRC:(BOOL)bigendian conditioned:(BOOL)conditioned;
+(XADCRCSuffixHandle *)CCITTCRC16SuffixHandleWithHandle:(CSHandle *)handle CRCHandle:(CSHandle *)crchandle
bigEndianCRC:(BOOL)bigendian conditioned:(BOOL)conditioned;

-(instancetype)initWithHandle:(CSHandle *)handle CRCHandle:(CSHandle *)crchandle initialCRC:(uint32_t)initialcrc
CRCSize:(int)crcbytes bigEndianCRC:(BOOL)bigendian CRCTable:(const uint32_t *)crctable;

-(void)resetStream;
-(NSInteger)streamAtMost:(NSInteger)num toBuffer:(void *)buffer;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChecksum;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isChecksumCorrect) BOOL checksumCorrect;

@end

