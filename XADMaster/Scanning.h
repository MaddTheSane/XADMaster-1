#import "CSHandle.h"

typedef int (*CSByteMatchingFunctionPointer)(const uint8_t *bytes,NSInteger available,off_t offset,void *state);

@interface CSHandle (Scanning)

-(BOOL)scanForByteString:(const void *)bytes length:(NSInteger)length;
-(int)scanUsingMatchingFunction:(CSByteMatchingFunctionPointer)function
maximumLength:(NSInteger)maximumlength;
-(int)scanUsingMatchingFunction:(CSByteMatchingFunctionPointer)function
maximumLength:(NSInteger)maximumlength context:(void *)contextptr;

@end
