#import "../CSByteStreamHandle.h"
#import "../XADPrefixCode.h"

extern NSString *const CCITTCodeException;

@interface CCITTFaxHandle:CSByteStreamHandle
{
	int columns,white;
	int column,colour,bitsleft;
}

-(instancetype)initWithInputBufferForHandle:(CSHandle *)handle columns:(int)cols white:(int)whitevalue;

-(void)resetByteStream;
-(uint8_t)produceByteAtOffset:(off_t)pos;

-(void)startNewLine;
-(void)findNextSpanLength;

@end

@interface CCITTFaxT41DHandle:CCITTFaxHandle
{
	XADPrefixCode *whitecode,*blackcode;
}

-(instancetype)initWithHandle:(CSHandle *)handle columns:(int)cols white:(int)whitevalue;

-(void)startNewLine;
-(void)findNextSpanLength;

@end

@interface CCITTFaxT6Handle:CCITTFaxHandle
{
	int *prevchanges,numprevchanges;
	int *currchanges,numcurrchanges;
	int prevpos,previndex,currpos,currcol,nexthoriz;
	XADPrefixCode *maincode,*whitecode,*blackcode;
}

-(instancetype)initWithHandle:(CSHandle *)handle columns:(int)columns white:(int)whitevalue;

-(void)resetByteStream;
-(void)startNewLine;
-(void)findNextSpanLength;

@end

