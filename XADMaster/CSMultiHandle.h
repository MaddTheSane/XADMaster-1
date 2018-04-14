#import "CSSegmentedHandle.h"

#define CSMultiHandle XADMultiHandle

@interface CSMultiHandle:CSSegmentedHandle
{
    NSArray<CSHandle*> *handles;
}

+(CSHandle *)handleWithHandleArray:(NSArray<CSHandle*> *)handlearray;
+(CSHandle *)handleWithHandles:(CSHandle *)firsthandle,... NS_REQUIRES_NIL_TERMINATION;

// Initializers
-(instancetype)initWithHandles:(NSArray<CSHandle*> *)handlearray;
-(instancetype)initAsCopyOf:(CSMultiHandle *)other;

// Public methods
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<CSHandle*> *handles;

// Implemented by this class
-(NSInteger)numberOfSegments;
-(off_t)segmentSizeAtIndex:(NSInteger)index;
-(CSHandle *)handleAtIndex:(NSInteger)index;

@end
