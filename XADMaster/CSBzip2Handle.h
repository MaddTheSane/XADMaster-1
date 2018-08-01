#import <Foundation/Foundation.h>
#import "CSStreamHandle.h"

#define CSBzip2Handle XADBzip2Handle

extern NSExceptionName const CSBzip2Exception;
extern NSErrorDomain const CSBzip2ErrorDomain;

typedef NS_ERROR_ENUM(CSBzip2ErrorDomain, CSBzip2Error) {
	CSBzip2ErrorSequence = -1, //!< BZ_SEQUENCE_ERROR
	CSBzip2ErrorParameter = -2, //!< BZ_PARAM_ERROR
	CSBzip2ErrorMemory = -3, //!< BZ_MEM_ERROR
	CSBzip2ErrorData = -4, //!< BZ_DATA_ERROR
	CSBzip2ErrorInvalidMagic = -5, //!< BZ_DATA_ERROR_MAGIC
	CSBzip2ErrorIO = -6, //!< BZ_IO_ERROR
	CSBzip2ErrorUnexpectedEndOfFile = -7, //!< BZ_UNEXPECTED_EOF
	CSBzip2ErrorOutBufferFull = -8, //!< BZ_OUTBUFF_FULL
	CSBzip2ErrorConfiguration = -9 //!< BZ_CONFIG_ERROR
};

@interface CSBzip2Handle:CSStreamHandle

+(CSBzip2Handle *)bzip2HandleWithHandle:(CSHandle *)handle;
+(CSBzip2Handle *)bzip2HandleWithHandle:(CSHandle *)handle length:(off_t)length;

// Initializers.
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;

// Implemented by this class.
-(void)resetStream;
-(int)streamAtMost:(int)num toBuffer:(void *)buffer;

// Checksum functions for XADMaster.
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChecksum;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isChecksumCorrect) BOOL checksumCorrect;

// Internal methods.
-(void)_raiseBzip2:(int)error NS_SWIFT_UNAVAILABLE("Call throws");

@end
