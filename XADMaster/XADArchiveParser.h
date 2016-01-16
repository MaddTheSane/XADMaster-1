#import <Foundation/Foundation.h>
#import "XADException.h"
#import "XADString.h"
#import "XADPath.h"
#import "XADRegex.h"
#import "CSHandle.h"
#import "XADSkipHandle.h"
#import "XADResourceFork.h"
#import "Checksums.h"

extern NSString *XADFileNameKey;
extern NSString *XADCommentKey;
extern NSString *XADFileSizeKey;
extern NSString *XADCompressedSizeKey;
extern NSString *XADCompressionNameKey;

extern NSString *XADLastModificationDateKey;
extern NSString *XADLastAccessDateKey;
extern NSString *XADLastAttributeChangeDateKey;
extern NSString *XADLastBackupDateKey;
extern NSString *XADCreationDateKey;

extern NSString *XADIsDirectoryKey;
extern NSString *XADIsResourceForkKey;
extern NSString *XADIsArchiveKey;
extern NSString *XADIsHiddenKey;
extern NSString *XADIsLinkKey;
extern NSString *XADIsHardLinkKey;
extern NSString *XADLinkDestinationKey;
extern NSString *XADIsCharacterDeviceKey;
extern NSString *XADIsBlockDeviceKey;
extern NSString *XADDeviceMajorKey;
extern NSString *XADDeviceMinorKey;
extern NSString *XADIsFIFOKey;
extern NSString *XADIsEncryptedKey;
extern NSString *XADIsCorruptedKey;

extern NSString *XADExtendedAttributesKey;
extern NSString *XADFileTypeKey;
extern NSString *XADFileCreatorKey;
extern NSString *XADFinderFlagsKey;
extern NSString *XADFinderInfoKey;
extern NSString *XADPosixPermissionsKey;
extern NSString *XADPosixUserKey;
extern NSString *XADPosixGroupKey;
extern NSString *XADPosixUserNameKey;
extern NSString *XADPosixGroupNameKey;
extern NSString *XADDOSFileAttributesKey;
extern NSString *XADWindowsFileAttributesKey;
extern NSString *XADAmigaProtectionBitsKey;

extern NSString *XADIndexKey;
extern NSString *XADDataOffsetKey;
extern NSString *XADDataLengthKey;
extern NSString *XADSkipOffsetKey;
extern NSString *XADSkipLengthKey;

extern NSString *XADIsSolidKey;
extern NSString *XADFirstSolidIndexKey;
extern NSString *XADFirstSolidEntryKey;
extern NSString *XADNextSolidIndexKey;
extern NSString *XADNextSolidEntryKey;
extern NSString *XADSolidObjectKey;
extern NSString *XADSolidOffsetKey;
extern NSString *XADSolidLengthKey;

// Archive properties only
extern NSString *XADArchiveNameKey;
extern NSString *XADVolumesKey;
extern NSString *XADVolumeScanningFailedKey;
extern NSString *XADDiskLabelKey;

@protocol XADArchiveParserDelegate;

@interface XADArchiveParser:NSObject
{
	CSHandle *sourcehandle;
	XADSkipHandle *skiphandle;
	XADResourceFork *resourcefork;

	NSString *password;
	NSString *passwordencodingname;
	BOOL caresaboutpasswordencoding;

	NSMutableDictionary *properties;
	XADStringSource *stringsource;

	int currindex;

	id parsersolidobj;
	NSMutableDictionary *firstsoliddict,*prevsoliddict;
	id currsolidobj;
	CSHandle *currsolidhandle;
	BOOL forcesolid;

	BOOL shouldstop;
}

+(Class)archiveParserClassForHandle:(CSHandle *)handle firstBytes:(NSData *)header
resourceFork:(XADResourceFork *)fork name:(NSString *)name propertiesToAdd:(NSMutableDictionary *)props;
+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle name:(NSString *)name NS_SWIFT_UNAVAILABLE("This function throws exceptions as part of its control flow; use archiveParserForHandle:name:error: instead");
+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle name:(NSString *)name error:(NSError **)errorptr;
+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle resourceFork:(XADResourceFork *)fork name:(NSString *)name NS_SWIFT_UNAVAILABLE("This function throws exceptions as part of its control flow; use archiveParserForHandle:resourceFork:name:error: instead");
+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle resourceFork:(XADResourceFork *)fork name:(NSString *)name error:(NSError **)errorptr;
+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header name:(NSString *)name NS_SWIFT_UNAVAILABLE("This function throws exceptions as part of its control flow; use archiveParserForHandle:firstBytes:name:error: instead");
+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header name:(NSString *)name error:(NSError **)errorptr;
+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header resourceFork:(XADResourceFork *)fork name:(NSString *)name NS_SWIFT_UNAVAILABLE("This function throws exceptions as part of its control flow; use archiveParserForHandle:firstBytes:resourceFork:name:error: instead");
+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header resourceFork:(XADResourceFork *)fork name:(NSString *)name error:(NSError **)errorptr;
+(XADArchiveParser *)archiveParserForPath:(NSString *)filename NS_SWIFT_UNAVAILABLE("This function throws exceptions as part of its control flow; use archiveParserForPath:error: instead");
+(XADArchiveParser *)archiveParserForPath:(NSString *)filename error:(NSError **)errorptr;
+(XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary *)entry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum NS_SWIFT_UNAVAILABLE("This function throws exceptions as part of its control flow; use archiveParserForEntryWithDictionary:archiveParser:wantChecksum:error: instead");
+(XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary *)entry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum error:(NSError **)errorptr;
+(XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary *)entry resourceForkDictionary:(NSDictionary *)forkentry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum NS_SWIFT_UNAVAILABLE("This function throws exceptions as part of its control flow; use archiveParserForEntryWithDictionary:resourceForkDictionary:archiveParser:wantChecksum:error: instead");
+(XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary *)entry resourceForkDictionary:(NSDictionary *)forkentry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum error:(NSError **)errorptr;
 
-(instancetype)init NS_DESIGNATED_INITIALIZER;

@property (NS_NONATOMIC_IOSONLY, copy) XADHandle *handle;
@property (NS_NONATOMIC_IOSONLY, retain) XADResourceFork *resourceFork;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *name;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *filename;
@property (NS_NONATOMIC_IOSONLY, copy) NSArray *allFilenames;

@property (NS_NONATOMIC_IOSONLY, assign) id<XADArchiveParserDelegate> delegate;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDictionary *properties;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *currentFilename;

@property (NS_NONATOMIC_IOSONLY, getter=isEncrypted, readonly) BOOL encrypted;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *password;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasPassword;

@property (NS_NONATOMIC_IOSONLY, copy) NSString *encodingName;
@property (NS_NONATOMIC_IOSONLY, readonly) float encodingConfidence;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL caresAboutPasswordEncoding;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *passwordEncodingName;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADStringSource *stringSource;

-(XADString *)linkDestinationForDictionary:(NSDictionary *)dict NS_SWIFT_UNAVAILABLE("This function throws exceptions as part of its control flow; use linkDestinationForDictionary:error: instead");
-(XADString *)linkDestinationForDictionary:(NSDictionary *)dict error:(NSError **)errorptr;
-(NSDictionary *)extendedAttributesForDictionary:(NSDictionary *)dict;
-(NSData *)finderInfoForDictionary:(NSDictionary *)dict;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL wasStopped;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChecksum;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL testChecksum;
@property (NS_NONATOMIC_IOSONLY, readonly) XADError testChecksumWithoutExceptions;



// Internal functions

+(NSArray *)scanForVolumesWithFilename:(NSString *)filename regex:(XADRegex *)regex;
+(NSArray *)scanForVolumesWithFilename:(NSString *)filename
regex:(XADRegex *)regex firstFileExtension:(NSString *)firstext;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL shouldKeepParsing;

-(CSHandle *)handleAtDataOffsetForDictionary:(NSDictionary *)dict;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADSkipHandle *skipHandle;
-(CSHandle *)zeroLengthHandleWithChecksum:(BOOL)checksum;
-(CSHandle *)subHandleFromSolidStreamForEntryWithDictionary:(NSDictionary *)dict;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *volumes;
-(CSHandle *)currentHandle;
-(off_t)offsetForVolume:(int)disk offset:(off_t)offset;

-(void)setObject:(id)object forPropertyKey:(NSString *)key;
-(void)addPropertiesFromDictionary:(NSDictionary *)dict;
-(void)setIsMacArchive:(BOOL)ismac;

-(void)addEntryWithDictionary:(NSMutableDictionary *)dict;
-(void)addEntryWithDictionary:(NSMutableDictionary *)dict retainPosition:(BOOL)retainpos;

-(XADString *)XADStringWithString:(NSString *)string;
-(XADString *)XADStringWithData:(NSData *)data;
-(XADString *)XADStringWithData:(NSData *)data encodingName:(NSString *)encoding;
-(XADString *)XADStringWithBytes:(const void *)bytes length:(int)length;
-(XADString *)XADStringWithBytes:(const void *)bytes length:(int)length encodingName:(NSString *)encoding;
-(XADString *)XADStringWithCString:(const char *)cstring;
-(XADString *)XADStringWithCString:(const char *)cstring encodingName:(NSString *)encoding;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADPath *XADPath;
-(XADPath *)XADPathWithString:(NSString *)string;
-(XADPath *)XADPathWithUnseparatedString:(NSString *)string;
-(XADPath *)XADPathWithData:(NSData *)data separators:(const char *)separators;
-(XADPath *)XADPathWithData:(NSData *)data encodingName:(NSString *)encoding separators:(const char *)separators;
-(XADPath *)XADPathWithBytes:(const void *)bytes length:(int)length separators:(const char *)separators;
-(XADPath *)XADPathWithBytes:(const void *)bytes length:(int)length encodingName:(NSString *)encoding separators:(const char *)separators;
-(XADPath *)XADPathWithCString:(const char *)cstring separators:(const char *)separators;
-(XADPath *)XADPathWithCString:(const char *)cstring encodingName:(NSString *)encoding separators:(const char *)separators;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSData *encodedPassword;
@property (NS_NONATOMIC_IOSONLY, readonly) const char *encodedCStringPassword;

-(void)reportInterestingFileWithReason:(NSString *)reason,...;



// Subclasses implement these:

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name propertiesToAdd:(NSMutableDictionary *)props;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
resourceFork:(XADResourceFork *)fork name:(NSString *)name propertiesToAdd:(NSMutableDictionary *)props;
+(NSArray *)volumesForHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name;

-(void)parse;
-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *formatName;

-(CSHandle *)handleForSolidStreamWithObject:(id)obj wantChecksum:(BOOL)checksum;

// Exception-free wrappers for subclass methods:
// parseWithoutExceptions will in addition return XADBreakError if the delegate
// requested parsing to stop.

@property (NS_NONATOMIC_IOSONLY, readonly) XADError parseWithoutExceptions;
-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum error:(NSError **)errorptr;

@end

@protocol XADArchiveParserDelegate <NSObject>

-(void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary *)dict;
-(BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser;
@optional
-(void)archiveParserNeedsPassword:(XADArchiveParser *)parser;
-(void)archiveParser:(XADArchiveParser *)parser findsFileInterestingForReason:(NSString *)reason;

@end

NSMutableArray *XADSortVolumes(NSMutableArray *volumes,NSString *firstfileextension);
