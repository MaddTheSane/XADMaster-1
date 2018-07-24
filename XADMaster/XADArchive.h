#import <Foundation/Foundation.h>

#import "XADArchiveParser.h"
#import "XADUnarchiver.h"
#import "XADException.h"

#ifdef __has_feature
#  if __has_feature(modules)
#    define XAD_NO_DEPRECATED
#  endif
#endif

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, XADAction) {
	XADActionAbort = 0,
	XADActionRetry = 1,
	XADActionSkip = 2,
	XADActionOverwrite = 3,
	XADActionRename = 4
};

//typedef off_t xadSize; // deprecated


extern NSString *const XADResourceDataKey;
extern NSString *const XADResourceForkData UNAVAILABLE_ATTRIBUTE;
extern NSString *const XADFinderFlags;


@class UniversalDetector;
@class XADArchive;
@protocol XADArchiveDelegate <NSObject>
@optional

-(NSStringEncoding)archive:(XADArchive *)archive encodingForData:(NSData *)data guess:(NSStringEncoding)guess confidence:(float)confidence;
-(XADAction)archive:(XADArchive *)archive nameDecodingDidFailForEntry:(NSInteger)n data:(nullable NSData *)data;

-(BOOL)archiveExtractionShouldStop:(XADArchive *)archive;
-(BOOL)archive:(XADArchive *)archive shouldCreateDirectory:(NSString *)directory;
-(XADAction)archive:(XADArchive *)archive entry:(NSInteger)n collidesWithFile:(NSString *)file newFilename:(NSString *__nullable*__nullable)newname;
-(XADAction)archive:(XADArchive *)archive entry:(NSInteger)n collidesWithDirectory:(NSString *)file newFilename:(NSString *__nullable*__nullable)newname;
-(XADAction)archive:(XADArchive *)archive creatingDirectoryDidFailForEntry:(NSInteger)n;

-(void)archiveNeedsPassword:(XADArchive *)archive;

-(void)archive:(XADArchive *)archive extractionOfEntryWillStart:(NSInteger)n;
-(void)archive:(XADArchive *)archive extractionProgressForEntry:(NSInteger)n bytes:(off_t)bytes of:(off_t)total;
-(void)archive:(XADArchive *)archive extractionOfEntryDidSucceed:(NSInteger)n;
-(XADAction)archive:(XADArchive *)archive extractionOfEntryDidFail:(NSInteger)n error:(XADError)error;
-(XADAction)archive:(XADArchive *)archive extractionOfResourceForkForEntryDidFail:(NSInteger)n error:(XADError)error;

-(void)archive:(XADArchive *)archive extractionProgressBytes:(off_t)bytes of:(off_t)total;

@optional
-(void)archive:(XADArchive *)archive extractionProgressFiles:(NSInteger)files of:(NSInteger)total;

@optional
// Deprecated
-(NSStringEncoding)archive:(null_unspecified XADArchive *)archive encodingForName:(null_unspecified const char *)bytes guess:(NSStringEncoding)guess confidence:(float)confidence DEPRECATED_ATTRIBUTE;
-(XADAction)archive:(null_unspecified XADArchive *)archive nameDecodingDidFailForEntry:(NSInteger)n bytes:(null_unspecified const char *)bytes DEPRECATED_ATTRIBUTE;

@end

@interface XADArchive:NSObject <XADArchiveDelegate, XADUnarchiverDelegate, XADArchiveParserDelegate>
{
	XADArchiveParser *parser;
	XADUnarchiver *unarchiver;

	NSTimeInterval update_interval;
	XADError lasterror;

	NSMutableArray *dataentries,*resourceentries;
	NSMutableDictionary *namedict;

	off_t extractsize,totalsize;
	NSInteger extractingentry;
	BOOL extractingresource;
	NSString *immediatedestination;
	BOOL immediatesubarchives,immediatefailed;
	off_t immediatesize;
	XADArchive *parentarchive;
}

+(nullable instancetype)archiveForFile:(NSString *)filename;
+(nullable instancetype)recursiveArchiveForFile:(NSString *)filename;



-(instancetype)init NS_DESIGNATED_INITIALIZER;
-(nullable instancetype)initWithFile:(NSString *)file NS_SWIFT_UNAVAILABLE("Call throws on failure");
-(nullable instancetype)initWithFile:(NSString *)file error:(nullable XADError *)error;
-(nullable instancetype)initWithFile:(NSString *)file delegate:(nullable id<XADArchiveDelegate>)del error:(nullable XADError *)error;
-(nullable instancetype)initWithData:(NSData *)data NS_SWIFT_UNAVAILABLE("Call throws on failure");
-(nullable instancetype)initWithData:(NSData *)data error:(nullable XADError *)error;
-(nullable instancetype)initWithData:(NSData *)data delegate:(nullable id<XADArchiveDelegate>)del error:(nullable XADError *)error;
-(nullable instancetype)initWithArchive:(XADArchive *)archive entry:(NSInteger)n NS_SWIFT_UNAVAILABLE("Call throws on failure");
-(nullable instancetype)initWithArchive:(XADArchive *)archive entry:(NSInteger)n error:(nullable XADError *)error;
-(nullable instancetype)initWithArchive:(XADArchive *)otherarchive entry:(NSInteger)n delegate:(nullable id<XADArchiveDelegate>)del error:(nullable XADError *)error;
-(nullable instancetype)initWithArchive:(XADArchive *)otherarchive entry:(NSInteger)n
     immediateExtractionTo:(NSString *)destination error:(nullable XADError *)error;
-(nullable instancetype)initWithArchive:(nullable XADArchive *)otherarchive entry:(NSInteger)n
     immediateExtractionTo:(NSString *)destination subArchives:(BOOL)sub error:(nullable XADError *)error;

-(nullable instancetype)initWithFile:(NSString *)file nserror:(NSError *_Nullable __autoreleasing *_Nullable)error;
-(nullable instancetype)initWithFile:(NSString *)file delegate:(nullable id<XADArchiveDelegate>)del nserror:(NSError *_Nullable __autoreleasing *_Nullable)error;
-(nullable instancetype)initWithData:(NSData *)data nserror:(NSError *_Nullable __autoreleasing *_Nullable)error;
-(nullable instancetype)initWithData:(NSData *)data delegate:(nullable id<XADArchiveDelegate>)del nserror:(NSError *_Nullable __autoreleasing *_Nullable)error;
-(nullable instancetype)initWithArchive:(XADArchive *)archive entry:(NSInteger)n nserror:(NSError *_Nullable __autoreleasing *_Nullable)error;
-(nullable instancetype)initWithArchive:(XADArchive *)otherarchive entry:(NSInteger)n delegate:(nullable id<XADArchiveDelegate>)del nserror:(NSError *_Nullable __autoreleasing *_Nullable)error;
-(nullable instancetype)initWithArchive:(XADArchive *)otherarchive entry:(NSInteger)n
immediateExtractionTo:(NSString *)destination nserror:(NSError *_Nullable __autoreleasing *_Nullable)error;
-(nullable instancetype)initWithArchive:(nullable XADArchive *)otherarchive entry:(NSInteger)n
immediateExtractionTo:(NSString *)destination subArchives:(BOOL)sub nserror:(NSError *_Nullable __autoreleasing *_Nullable)error;

-(nullable instancetype)initWithFileURL:(NSURL *)file delegate:(nullable id<XADArchiveDelegate>)del error:(NSError *_Nullable __autoreleasing *_Nullable)error;


-(BOOL)_parseWithErrorPointer:(nullable XADError *)error;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *filename;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<NSString*> *allFilenames;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *formatName;
@property (NS_NONATOMIC_IOSONLY, getter=isEncrypted, readonly) BOOL encrypted;
@property (NS_NONATOMIC_IOSONLY, getter=isSolid, readonly) BOOL solid;
@property (NS_NONATOMIC_IOSONLY, getter=isCorrupted, readonly) BOOL corrupted;
@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfEntries;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL immediateExtractionFailed;
@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSString *commonTopDirectory;
@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSString *comment;

@property (NS_NONATOMIC_IOSONLY, weak, nullable) id<XADArchiveDelegate> delegate;

@property (NS_NONATOMIC_IOSONLY, copy, nullable) NSString *password;

@property (NS_NONATOMIC_IOSONLY) NSStringEncoding nameEncoding NS_REFINED_FOR_SWIFT;

@property (NS_NONATOMIC_IOSONLY, readonly) XADError lastError;
-(void)clearLastError;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString * _Nullable describeLastError;
-(nullable NSString *)describeError:(XADError)error;

@property (readonly, copy) NSString *description;



-(nullable NSDictionary<XADArchiveKeys,id> *)dataForkParserDictionaryForEntry:(NSInteger)n;
-(nullable NSDictionary<XADArchiveKeys,id> *)resourceForkParserDictionaryForEntry:(NSInteger)n;
-(nullable NSDictionary<XADArchiveKeys,id> *)combinedParserDictionaryForEntry:(NSInteger)n;

-(nullable NSString *)nameOfEntry:(NSInteger)n;
-(BOOL)entryHasSize:(NSInteger)n;
-(off_t)uncompressedSizeOfEntry:(NSInteger)n;
-(off_t)compressedSizeOfEntry:(NSInteger)n;
-(off_t)representativeSizeOfEntry:(NSInteger)n;
-(BOOL)entryIsDirectory:(NSInteger)n;
-(BOOL)entryIsLink:(NSInteger)n;
-(BOOL)entryIsEncrypted:(NSInteger)n;
-(BOOL)entryIsArchive:(NSInteger)n;
-(BOOL)entryHasResourceFork:(NSInteger)n;
-(NSString *)commentForEntry:(NSInteger)n;
-(NSDictionary<NSFileAttributeKey,id> *)attributesOfEntry:(NSInteger)n;
-(NSDictionary<NSFileAttributeKey,id> *)attributesOfEntry:(NSInteger)n withResourceFork:(BOOL)resfork;
-(CSHandle *)handleForEntry:(NSInteger)n NS_SWIFT_UNAVAILABLE("Use error-throwing type instead");
-(nullable CSHandle *)handleForEntry:(NSInteger)n error:(nullable XADError *)error NS_REFINED_FOR_SWIFT;
-(nullable CSHandle *)handleForEntry:(NSInteger)n nserror:(NSError *_Nullable __autoreleasing *_Nullable)error;
-(CSHandle *)resourceHandleForEntry:(NSInteger)n NS_SWIFT_UNAVAILABLE("Use error-throwing type instead");
-(nullable CSHandle *)resourceHandleForEntry:(NSInteger)n error:(nullable XADError *)error NS_REFINED_FOR_SWIFT;
-(nullable CSHandle *)resourceHandleForEntry:(NSInteger)n nserror:(NSError *_Nullable __autoreleasing *_Nullable)error;
-(nullable NSData *)contentsOfEntry:(NSInteger)n NS_REFINED_FOR_SWIFT;
//-(NSData *)resourceContentsOfEntry:(int)n;

-(BOOL)extractTo:(NSString *)destination;
-(BOOL)extractTo:(NSString *)destination subArchives:(BOOL)sub;
-(BOOL)extractEntries:(NSIndexSet *)entryset to:(NSString *)destination;
-(BOOL)extractEntries:(NSIndexSet *)entryset to:(NSString *)destination subArchives:(BOOL)sub;
-(BOOL)extractEntry:(NSInteger)n to:(NSString *)destination;
-(BOOL)extractEntry:(NSInteger)n to:(NSString *)destination deferDirectories:(BOOL)defer;
-(BOOL)extractEntry:(NSInteger)n to:(NSString *)destination deferDirectories:(BOOL)defer
resourceFork:(BOOL)resfork;
-(BOOL)extractEntry:(NSInteger)n to:(NSString *)destination deferDirectories:(BOOL)defer
dataFork:(BOOL)datafork resourceFork:(BOOL)resfork;
-(BOOL)extractArchiveEntry:(NSInteger)n to:(NSString *)destination;

-(BOOL)_extractEntry:(NSInteger)n as:(NSString *)destfile deferDirectories:(BOOL)defer
dataFork:(BOOL)datafork resourceFork:(BOOL)resfork;

-(void)updateAttributesForDeferredDirectories;

//Tim Oliver
- (BOOL)extractContentsOfEntry:(NSInteger)n toPath:(NSString *)destination;

// Deprecated

+(null_unspecified NSArray *)volumesForFile:(null_unspecified NSString *)filename DEPRECATED_ATTRIBUTE;

-(int)sizeOfEntry:(int)n DEPRECATED_ATTRIBUTE;
-(null_unspecified void *)xadFileInfoForEntry:(int)n NS_RETURNS_INNER_POINTER DEPRECATED_ATTRIBUTE;
-(BOOL)extractEntry:(int)n to:(null_unspecified NSString *)destination overrideWritePermissions:(BOOL)override DEPRECATED_ATTRIBUTE;
-(BOOL)extractEntry:(int)n to:(null_unspecified NSString *)destination overrideWritePermissions:(BOOL)overrided resourceFork:(BOOL)resfork DEPRECATED_ATTRIBUTE;
-(void)fixWritePermissions DEPRECATED_ATTRIBUTE;

@end


#ifndef XAD_NO_DEPRECATED

#define XADAbort XADAbortAction
#define XADRetry XADRetryAction
#define XADSkip XADSkipAction
#define XADOverwrite XADOverwriteAction
#define XADRename XADRenameAction

typedef XADError xadERROR;
typedef off_t xadSize;

#define XADERR_NO XADNoError
#if 0
#define XADUnknownError          0x0001 /* unknown error */
#define XADInputError            0x0002 /* input data buffers border exceeded */
#define XADOutputError           0x0003 /* output data buffers border exceeded */
#define XADBadParametersError    0x0004 /* function called with illegal parameters */
#define XADOutOfMemoryError      0x0005 /* not enough memory available */
#define XADIllegalDataError      0x0006 /* data is corrupted */
#define XADNotSupportedError     0x0007 /* command is not supported */
#define XADResourceError         0x0008 /* required resource missing */
#define XADDecrunchError         0x0009 /* error on decrunching */
#define XADFiletypeError         0x000A /* unknown file type */
#define XADOpenFileError         0x000B /* opening file failed */
#define XADSkipError             0x000C /* file, disk has been skipped */
#define XADBreakError            0x000D /* user break in progress hook */
#define XADFileExistsError       0x000E /* file already exists */
#define XADPasswordError         0x000F /* missing or wrong password */
#define XADMakeDirectoryError    0x0010 /* could not create directory */
#define XADChecksumError         0x0011 /* wrong checksum */
#define XADVerifyError           0x0012 /* verify failed (disk hook) */
#define XADGeometryError         0x0013 /* wrong drive geometry */
#define XADDataFormatError       0x0014 /* unknown data format */
#define XADEmptyError            0x0015 /* source contains no files */
#define XADFileSystemError       0x0016 /* unknown filesystem */
#define XADFileDirectoryError    0x0017 /* name of file exists as directory */
#define XADShortBufferError      0x0018 /* buffer was too short */
#define XADEncodingError         0x0019 /* text encoding was defective */
#endif

#define XADAbort XADAbortAction
#define XADRetry XADRetryAction
#define XADSkip XADSkipAction
#define XADOverwrite XADOverwriteAction
#define XADRename XADRenameAction

#endif

static const XADAction XADAbortAction API_DEPRECATED_WITH_REPLACEMENT("XADActionAbort", macosx(10.0, 10.8), ios(3.0, 8.0)) = XADActionAbort;
static const XADAction XADRetryAction API_DEPRECATED_WITH_REPLACEMENT("XADActionRetry", macosx(10.0, 10.8), ios(3.0, 8.0)) = XADActionRetry;
static const XADAction XADSkipAction API_DEPRECATED_WITH_REPLACEMENT("XADActionSkip", macosx(10.0, 10.8), ios(3.0, 8.0)) = XADActionSkip;
static const XADAction XADOverwriteAction API_DEPRECATED_WITH_REPLACEMENT("XADActionOverwrite", macosx(10.0, 10.8), ios(3.0, 8.0)) = XADActionOverwrite;
static const XADAction XADRenameAction API_DEPRECATED_WITH_REPLACEMENT("XADActionRename", macosx(10.0, 10.8), ios(3.0, 8.0)) = XADActionRename;

NS_ASSUME_NONNULL_END
