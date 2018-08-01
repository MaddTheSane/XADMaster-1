#import <Foundation/Foundation.h>
#import "CSStreamHandle.h"

#define CSBzip2Handle XADBzip2Handle

extern NSExceptionName const CSBzip2Exception;

@interface CSBzip2Handle:CSStreamHandle

+(CSBzip2Handle *)bzip2HandleWithHandle:(CSHandle *)handle;
+(CSBzip2Handle *)bzip2HandleWithHandle:(CSHandle *)handle length:(off_t)length;

// Initializers.
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length;

// Implemented by this class.
-(void)resetStream;
-(NSInteger)streamAtMost:(NSInteger)num toBuffer:(void *)buffer;

// Checksum functions for XADMaster.
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChecksum;
@property (NS_NONATOMIC_IOSONLY, readonly, getter=isChecksumCorrect) BOOL checksumCorrect;

// Internal methods.
-(void)_raiseBzip2:(int)error NS_SWIFT_UNAVAILABLE("Call throws");

@end
