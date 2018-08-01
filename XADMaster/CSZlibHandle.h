#import <Foundation/Foundation.h>
#import "CSStreamHandle.h"

#define CSZlibHandle XADZlibHandle

extern NSExceptionName const CSZlibException;

@interface CSZlibHandle:CSStreamHandle

+(CSZlibHandle *)zlibHandleWithHandle:(CSHandle *)handle;
+(CSZlibHandle *)zlibHandleWithHandle:(CSHandle *)handle length:(off_t)length;
+(CSZlibHandle *)deflateHandleWithHandle:(CSHandle *)handle;
+(CSZlibHandle *)deflateHandleWithHandle:(CSHandle *)handle length:(off_t)length;

// Intializers
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)length header:(BOOL)header ;
-(instancetype)initAsCopyOf:(CSZlibHandle *)other;

// Public methods
-(void)setSeekBackAtEOF:(BOOL)seekateof;
-(void)setEndStreamAtInputEOF:(BOOL)endateof;

// Implemented by this class
-(void)resetStream;
-(NSInteger)streamAtMost:(NSInteger)num toBuffer:(void *)buffer;

// Internal methods
-(void)_raiseZlib NS_SWIFT_UNAVAILABLE("Call throws");

@end
