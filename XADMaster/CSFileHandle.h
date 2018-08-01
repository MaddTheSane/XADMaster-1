#import <Foundation/Foundation.h>
#import "CSHandle.h"

#import <stdio.h>

#define CSFileHandle XADFileHandle

extern NSExceptionName const CSCannotOpenFileException;
extern NSExceptionName const CSFileErrorException;

@interface CSFileHandle:CSHandle
{
	FILE *fh;
	NSString *path;
	BOOL close;

	NSLock *multilock;
	CSFileHandle *fhowner;
	off_t pos;
}

+(CSFileHandle *)fileHandleForReadingAtPath:(NSString *)path;
+(CSFileHandle *)fileHandleForWritingAtPath:(NSString *)path;
+(CSFileHandle *)fileHandleForPath:(NSString *)path modes:(NSString *)modes;
+(CSFileHandle *)fileHandleForReadingAtFileURL:(NSURL *)path;
+(CSFileHandle *)fileHandleForWritingAtFileURL:(NSURL *)path;
+(CSFileHandle *)fileHandleForFileURL:(NSURL *)path modes:(NSString *)modes;
+(CSFileHandle *)fileHandleForStandardInput;
+(CSFileHandle *)fileHandleForStandardOutput;
+(CSFileHandle *)fileHandleForStandardError;

// Initializers
-(instancetype)initWithFilePointer:(FILE *)file closeOnDealloc:(BOOL)closeondealloc path:(NSString *)filepath;
-(instancetype)initAsCopyOf:(CSFileHandle *)other;
-(void)close;

// Public methods
@property (NS_NONATOMIC_IOSONLY, readonly) FILE *filePointer;

// Implemented by this class
@property (NS_NONATOMIC_IOSONLY, readonly) off_t fileSize;
@property (NS_NONATOMIC_IOSONLY, readonly) off_t offsetInFile;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL atEndOfFile;

-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
-(void)pushBackByte:(int)byte;
-(NSInteger)readAtMost:(NSInteger)num toBuffer:(void *)buffer;
-(void)writeBytes:(NSInteger)num fromBuffer:(const void *)buffer;

-(NSString *)name;

// Internal methods
-(void)_raiseError NS_SWIFT_UNAVAILABLE("Call throws exception");
-(void)_setMultiMode;

@end
