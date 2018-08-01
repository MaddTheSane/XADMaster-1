#import "XADLZSSHandle.h"
#import "XADPrefixCode.h"

typedef NS_ENUM(int, XADDeflateVariant) {
	XADDeflateVariantNormal = 0,
	XADDeflateVariantDeflate64 = 1,
	XADDeflateVariantStuffitX = 2,
	XADDeflateVariantNSIS = 3
};
#define XADNormalDeflateVariant XADDeflateVariantNormal
#define XADDeflate64DeflateVariant XADDeflateVariantDeflate64
#define XADStuffItXDeflateVariant XADDeflateVariantStuffitX
#define XADNSISDeflateVariant XADDeflateVariantNSIS

@interface XADDeflateHandle:XADLZSSHandle
{
	XADDeflateVariant variant;

	XADPrefixCode *literalcode,*distancecode;
	XADPrefixCode *fixedliteralcode,*fixeddistancecode;
	BOOL storedblock,lastblock;
	int storedcount;

	int order[19];
}

-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length variant:(XADDeflateVariant)deflatevariant;

-(void)setMetaTableOrder:(const int *)order;

-(void)resetLZSSHandle;
-(int)nextLiteralOrOffset:(int *)offset andLength:(int *)length atPosition:(off_t)pos;

-(void)readBlockHeader;
-(XADPrefixCode *)allocAndParseMetaCodeOfSize:(int)size;
-(XADPrefixCode *)fixedLiteralCode;
-(XADPrefixCode *)fixedDistanceCode;

@end
