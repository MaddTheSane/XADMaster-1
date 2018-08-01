#import "CSHandle.h"

#define CSSegmentedHandle XADSegmentedHandle

extern NSExceptionName const CSNoSegmentsException;
extern NSExceptionName const CSSizeOfSegmentUnknownException;

@interface CSSegmentedHandle:CSHandle
{
	NSInteger count;
	NSInteger currindex;
	CSHandle *currhandle;
	off_t *segmentends;
	NSArray *segmentsizes;
}

// Initializers
-(instancetype)init;
-(instancetype)initAsCopyOf:(CSSegmentedHandle *)other;

// Public methods
@property (NS_NONATOMIC_IOSONLY, readonly) CSHandle *currentHandle;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<NSNumber*> *segmentSizes;

// Implemented by this class
@property (NS_NONATOMIC_IOSONLY, readonly) off_t fileSize;
@property (NS_NONATOMIC_IOSONLY, readonly) off_t offsetInFile;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL atEndOfFile;

-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
-(NSInteger)readAtMost:(NSInteger)num toBuffer:(void *)buffer;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *name;

// Implemented by subclasses
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfSegments;
-(off_t)segmentSizeAtIndex:(NSInteger)index;
-(CSHandle *)handleAtIndex:(NSInteger)index;

// Internal methods
-(void)_open;
-(void)_setCurrentIndex:(NSInteger)newindex;
-(void)_raiseNoSegments;
-(void)_raiseSizeUnknownForSegment:(NSInteger)i;

@end
