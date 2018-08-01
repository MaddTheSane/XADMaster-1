#import <Foundation/Foundation.h>
#import "CSHandle.h"

#define CSMemoryHandle XADMemoryHandle

@interface CSMemoryHandle:CSHandle
{
	NSData *backingdata;
	off_t memorypos;
}

+(CSMemoryHandle *)memoryHandleForReadingData:(NSData *)data;
+(CSMemoryHandle *)memoryHandleForReadingBuffer:(const void *)buf length:(unsigned)len;
+(CSMemoryHandle *)memoryHandleForReadingMappedFile:(NSString *)filename;
+(CSMemoryHandle *)memoryHandleForWriting;

// Initializers
-(instancetype)initWithData:(NSData *)dataobj;
-(instancetype)initAsCopyOf:(CSMemoryHandle *)other;

// Public methods
@property (NS_NONATOMIC_IOSONLY, readonly, strong) NSData *data;
-(NSMutableData *)mutableData;

// Implemented by this class
@property (NS_NONATOMIC_IOSONLY, readonly) off_t fileSize;
@property (NS_NONATOMIC_IOSONLY, readonly) off_t offsetInFile;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL atEndOfFile;

-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
//-(void)pushBackByte:(int)byte;
-(NSInteger)readAtMost:(NSInteger)num toBuffer:(void *)buffer;
-(void)writeBytes:(NSInteger)num fromBuffer:(const void *)buffer;

-(NSData *)fileContents;
-(NSData *)remainingFileContents;
-(NSData *)readDataOfLength:(NSInteger)length;
-(NSData *)readDataOfLengthAtMost:(NSInteger)length;
-(NSData *)copyDataOfLength:(NSInteger)length;
-(NSData *)copyDataOfLengthAtMost:(NSInteger)length;

-(NSString *)name;

@end
