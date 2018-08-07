#import "CSMemoryHandle.h"
#import "CSInputBuffer.h"
#include "libxad/include/xadmaster.h"

#define XIDBUFSIZE 10240


typedef NS_OPTIONS(xadUINT32, xadIOFlag) {
	/*! allocate input buffer */
	xadIOFlagAllocInBuffer = 1 << 0,
	/*! allocate output buffer */
	xadIOFlagAllocOutBuffer = 1 << 1,
	/*! \c xadIOGetChar does not produce err at buffer end */
	xadIOFlagNoInEndError = 1 << 2,
	/*! \c xadIOPutChar does not check out size */
	xadIOFlagNoOutEndError = 1 << 3,
	/*! last byte was read, set by \c xadIOGetChar */
	xadIOFlagLastInByte = 1 << 4,
	/*! output length was reached, set by \c xadIOPutChar */
	xadIOFlagLastOutByte = 1 << 5,
	/*! an error occured */
	xadIOFlagError = 1 << 6,
	/*! calculate no CRC16 */
	xadIOFlagNoCRC16 = 1 << 7,
	/*! calculate no CRC32 */
	xadIOFlagNoCRC32 = 1 << 8,
	/*! outfunc completely replaces write stuff */
	xadIOFlagCompleteOutFunc = 1 << 9
};

struct xadInOut {
  struct xadArchiveInfo * xio_ArchiveInfo;   /* filled by xadIOAlloc */
  struct xadMasterBase *  xio_xadMasterBase; /* filled by xadIOAlloc */
  xadERROR                xio_Error;         /* cleared */
  xadIOFlag               xio_Flags;         /* filled by xadIOAlloc, functions or user */

  /* xio_GetFunc and xio_PutFunc are filled by xadIOAlloc or user */
  xadUINT8 (*xio_GetFunc)(struct xadInOut *);
  xadPTR                  xio_GetFuncPrivate;
  xadUINT8 (*xio_PutFunc)(struct xadInOut *, xadUINT8);
  xadPTR                  xio_PutFuncPrivate;

  void (*xio_InFunc)(struct xadInOut *, xadUINT32);
  xadPTR                  xio_InFuncPrivate;
  xadSize                 xio_InSize;
  xadSize                 xio_InBufferSize;
  xadSize                 xio_InBufferPos;
  xadUINT8 *              xio_InBuffer;
  xadUINT32               xio_BitBuf;        /* for xadIOGetBits functions */
  xadUINT16               xio_BitNum;        /* for xadIOGetBits functions */

  xadUINT16               xio_CRC16;         /* crc16 from output functions */
  xadUINT32               xio_CRC32;         /* crc32 from output functions */

  void (*xio_OutFunc)(struct xadInOut *, xadUINT32);
  xadPTR                  xio_OutFuncPrivate;
  xadSize                 xio_OutSize;
  xadSize                 xio_OutBufferSize;
  xadSize                 xio_OutBufferPos;
  xadUINT8 *              xio_OutBuffer;

  /* These 3 can be reused. Algorithms should be prepared to find this
     initialized! The window, alloc always has to use xadAllocVec. */
  xadSize                 xio_WindowSize;
  xadSize                 xio_WindowPos;
  xadUINT8 *              xio_Window;

  /* If the algorithms need to remember additional data for next run, this
     should be passed as argument structure of type (void **) and allocated
     by the algorithms themself using xadAllocVec(). */

	// Extra fields for use by the xadIO emulation
	CSHandle *inputhandle;
	NSMutableData *outputdata;
};

/* setting BufferPos to buffer size activates first time read! */

#define XADIOF_ALLOCINBUFFER   xadIOFlagAllocInBuffer	/* allocate input buffer */
#define XADIOF_ALLOCOUTBUFFER  xadIOFlagAllocOutBuffer	/* allocate output buffer */
#define XADIOF_NOINENDERR      xadIOFlagNoInEndError	/* xadIOGetChar does not produce err at buffer end */
#define XADIOF_NOOUTENDERR     xadIOFlagNoOutEndError	/* xadIOPutChar does not check out size */
#define XADIOF_LASTINBYTE      xadIOFlagLastInByte		/* last byte was read, set by xadIOGetChar */
#define XADIOF_LASTOUTBYTE     xadIOFlagLastOutByte		/* output length was reached, set by xadIOPutChar */
#define XADIOF_ERROR           xadIOFlagError			/* an error occured */
#define XADIOF_NOCRC16         xadIOFlagNoCRC16			/* calculate no CRC16 */
#define XADIOF_NOCRC32         xadIOFlagNoCRC32			/* calculate no CRC32 */
#define XADIOF_COMPLETEOUTFUNC xadIOFlagCompleteOutFunc	/* outfunc completely replaces write stuff */

/* allocates the xadInOut structure and the buffers */
struct xadInOut *xadIOAlloc(xadIOFlag flags,
struct xadArchiveInfo *ai, struct xadMasterBase *xadMasterBase);

/* writes the buffer out */
xadERROR xadIOWriteBuf(struct xadInOut *io);

#define xadIOGetChar(io)   (*((io)->xio_GetFunc))((io))      /* reads one byte */
#define xadIOPutChar(io,a) (*((io)->xio_PutFunc))((io), (a)) /* stores one byte */

/* This skips any left bits and rounds up the whole to next byte boundary. */
/* Sometimes needed for block-based algorithms, where there blocks are byte aligned. */
#define xadIOByteBoundary(io) ((io)->xio_BitNum = 0)

/* The read bits function only read the bits without flushing from buffer. This is
done by DropBits. Some compressors need this method, as the flush different amount
of data than they read in. Normally the GetBits functions are used.
When including the source file directly, do not forget to set the correct defines
to include the necessary functions. */

/* new bytes inserted from left, get bits from right end, max 32 bits, no checks */
xadUINT32 xadIOGetBitsLow(struct xadInOut *io, xadUINT8 bits);
/* new bytes inserted from left, get bits from right end, max 32 bits, no checks, bits reversed */
xadUINT32 xadIOGetBitsLowR(struct xadInOut *io, xadUINT8 bits);

xadUINT32 xadIOReadBitsLow(struct xadInOut *io, xadUINT8 bits);
void xadIODropBitsLow(struct xadInOut *io, xadUINT8 bits);

/* new bytes inserted from right, get bits from left end, max 32 bits, no checks */
xadUINT32 xadIOGetBitsHigh(struct xadInOut *io, xadUINT8 bits);

xadUINT32 xadIOReadBitsHigh(struct xadInOut *io, xadUINT8 bits);
void xadIODropBitsHigh(struct xadInOut *io, xadUINT8 bits);




@interface XADLibXADIOHandle:CSMemoryHandle
{
	BOOL unpacked;

	off_t inlen,outlen;
	uint8_t inbuf[XIDBUFSIZE],outbuf[XIDBUFSIZE];
	struct xadInOut iostruct;
}

-(instancetype)initWithHandle:(CSHandle *)handle;
-(instancetype)initWithHandle:(CSHandle *)handle length:(off_t)outlength;

@property (NS_NONATOMIC_IOSONLY, readonly) off_t fileSize;
@property (NS_NONATOMIC_IOSONLY, readonly) off_t offsetInFile;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL atEndOfFile;

-(void)seekToFileOffset:(off_t)offs;
-(void)seekToEndOfFile;
//-(void)pushBackByte:(int)byte;
-(int)readAtMost:(int)num toBuffer:(void *)buffer;
-(void)writeBytes:(int)num fromBuffer:(const void *)buffer;

-(NSData *)fileContents;
-(NSData *)remainingFileContents;
-(NSData *)readDataOfLength:(int)length;
-(NSData *)readDataOfLengthAtMost:(int)length;
-(NSData *)copyDataOfLength:(int)length;
-(NSData *)copyDataOfLengthAtMost:(int)length;

-(void)runUnpacker;
-(struct xadInOut *)ioStructWithFlags:(xadIOFlag)flags;
-(xadINT32)unpackData;

@end




#undef XADM
#define XADM
#define XADMEMF_ANY     (0)
#define XADMEMF_CLEAR   (1L << 16)
#define XADMEMF_PUBLIC  (1L << 0)

#define xadAllocVec _xadAllocVec
#define xadFreeObject _xadFreeObject
#define xadFreeObjectA _xadFreeObjectA
#define xadCopyMem _xadCopyMem
static inline xadPTR xadAllocVec(xadSize size, xadUINT32 flags) { return calloc((int)size,1); }
static inline void xadFreeObject(xadPTR object,xadTag tag, ...) { free(object); }
static inline void xadFreeObjectA(xadPTR object,xadTAGPTR tags) { free(object); }
static inline void xadCopyMem(const void *s,xadPTR d,xadSize size) { memmove(d,s,(size_t)size); }

