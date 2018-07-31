#import <Foundation/Foundation.h>
#import "XADException.h"
#import "XADString.h"
#import "XADPath.h"
#import "XADRegex.h"
#import "CSHandle.h"
#import "XADSkipHandle.h"
#import "XADResourceFork.h"
#import "Checksums.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString *XADArchiveKeys NS_TYPED_EXTENSIBLE_ENUM;

extern XADArchiveKeys const XADFileNameKey;
extern XADArchiveKeys const XADCommentKey;
extern XADArchiveKeys const XADFileSizeKey;
extern XADArchiveKeys const XADCompressedSizeKey;
extern XADArchiveKeys const XADCompressionNameKey;

extern XADArchiveKeys const XADLastModificationDateKey;
extern XADArchiveKeys const XADLastAccessDateKey;
extern XADArchiveKeys const XADLastAttributeChangeDateKey;
extern XADArchiveKeys const XADLastBackupDateKey;
extern XADArchiveKeys const XADCreationDateKey;

extern XADArchiveKeys const XADIsDirectoryKey;
extern XADArchiveKeys const XADIsResourceForkKey;
extern XADArchiveKeys const XADIsArchiveKey;
extern XADArchiveKeys const XADIsHiddenKey;
extern XADArchiveKeys const XADIsLinkKey;
extern XADArchiveKeys const XADIsHardLinkKey;
extern XADArchiveKeys const XADLinkDestinationKey;
extern XADArchiveKeys const XADIsCharacterDeviceKey;
extern XADArchiveKeys const XADIsBlockDeviceKey;
extern XADArchiveKeys const XADDeviceMajorKey;
extern XADArchiveKeys const XADDeviceMinorKey;
extern XADArchiveKeys const XADIsFIFOKey;
extern XADArchiveKeys const XADIsEncryptedKey;
extern XADArchiveKeys const XADIsCorruptedKey;

extern XADArchiveKeys const XADExtendedAttributesKey;
extern XADArchiveKeys const XADFileTypeKey;
extern XADArchiveKeys const XADFileCreatorKey;
extern XADArchiveKeys const XADFinderFlagsKey;
extern XADArchiveKeys const XADFinderInfoKey;
extern XADArchiveKeys const XADPosixPermissionsKey;
extern XADArchiveKeys const XADPosixUserKey;
extern XADArchiveKeys const XADPosixGroupKey;
extern XADArchiveKeys const XADPosixUserNameKey;
extern XADArchiveKeys const XADPosixGroupNameKey;
extern XADArchiveKeys const XADDOSFileAttributesKey NS_SWIFT_NAME(dosFileAttributesKey);
extern XADArchiveKeys const XADWindowsFileAttributesKey;
extern XADArchiveKeys const XADAmigaProtectionBitsKey;

extern XADArchiveKeys const XADIndexKey;
extern XADArchiveKeys const XADDataOffsetKey;
extern XADArchiveKeys const XADDataLengthKey;
extern XADArchiveKeys const XADSkipOffsetKey;
extern XADArchiveKeys const XADSkipLengthKey;

extern XADArchiveKeys const XADIsSolidKey;
extern XADArchiveKeys const XADFirstSolidIndexKey;
extern XADArchiveKeys const XADFirstSolidEntryKey;
extern XADArchiveKeys const XADNextSolidIndexKey;
extern XADArchiveKeys const XADNextSolidEntryKey;
extern XADArchiveKeys const XADSolidObjectKey;
extern XADArchiveKeys const XADSolidOffsetKey;
extern XADArchiveKeys const XADSolidLengthKey;

// Archive properties only
extern XADArchiveKeys const XADArchiveNameKey;
extern XADArchiveKeys const XADVolumesKey;
extern XADArchiveKeys const XADVolumeScanningFailedKey;
extern XADArchiveKeys const XADDiskLabelKey;

@protocol XADArchiveParserDelegate;

@interface XADArchiveParser:NSObject
{
	CSHandle *sourcehandle;
	XADSkipHandle *skiphandle;
	XADResourceFork *resourcefork;

	NSString *password;
	NSString *passwordencodingname;
	BOOL caresaboutpasswordencoding;

	NSMutableDictionary<XADArchiveKeys,id> *properties;
	XADStringSource *stringsource;

	int currindex;

	id parsersolidobj;
	NSMutableDictionary *firstsoliddict,*prevsoliddict;
	id currsolidobj;
	CSHandle *currsolidhandle;
	BOOL forcesolid;

	BOOL shouldstop;
}

+(nullable Class)archiveParserClassForHandle:(CSHandle *)handle firstBytes:(NSData *)header
resourceFork:(nullable XADResourceFork *)fork name:(NSString *)name propertiesToAdd:(NSMutableDictionary<XADArchiveKeys,id> *)props;
+(nullable XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle name:(NSString *)name NS_SWIFT_UNAVAILABLE("Throws uncaught exception!");
+(nullable XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle name:(NSString *)name error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;
+(nullable XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle resourceFork:(nullable XADResourceFork *)fork name:(NSString *)name NS_SWIFT_UNAVAILABLE("Throws uncaught exception!");
+(nullable XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle resourceFork:(nullable XADResourceFork *)fork name:(NSString *)name error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;
+(nullable XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header name:(NSString *)name NS_SWIFT_UNAVAILABLE("Uncaught exception!");
+(nullable XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header name:(NSString *)name error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;
+(nullable XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header resourceFork:(nullable XADResourceFork *)fork name:(NSString *)name NS_SWIFT_UNAVAILABLE("Throws uncaught exception!");
+(nullable XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header resourceFork:(nullable XADResourceFork *)fork name:(NSString *)name error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;
+(nullable XADArchiveParser *)archiveParserForPath:(NSString *)filename NS_SWIFT_UNAVAILABLE("Throws uncaught exception!");
+(nullable XADArchiveParser *)archiveParserForPath:(NSString *)filename error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;
+(nullable XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)entry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum NS_SWIFT_UNAVAILABLE("Throws uncaught exception!");
+(nullable XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)entry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;
+(nullable XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)entry resourceForkDictionary:(nullable NSDictionary *)forkentry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum NS_SWIFT_UNAVAILABLE("Throws uncaught exception!");
+(nullable XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)entry resourceForkDictionary:(nullable NSDictionary<XADArchiveKeys,id> *)forkentry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;

+(nullable XADArchiveParser *)archiveParserForFileURL:(NSURL *)filename NS_SWIFT_UNAVAILABLE("Throws uncaught exception!");

#pragma mark NSError functions
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle name:(NSString *)name nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(for:name:));
+(nullable __kindof XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)entry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(with:archiveParser:wantChecksum:));
+(nullable __kindof XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)entry resourceForkDictionary:(nullable NSDictionary<XADArchiveKeys,id> *)forkentry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(with:resourceForkDictionary:archiveParser:wantChecksum:));
+(nullable __kindof XADArchiveParser *)archiveParserForPath:(NSString *)filename nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(forPath:));
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header resourceFork:(nullable XADResourceFork *)fork name:(NSString *)name nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(for:firstBytes:resourceFork:name:));
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle resourceFork:(nullable XADResourceFork *)fork name:(NSString *)name nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(for:resourceFork:name:));
+(nullable __kindof XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header name:(NSString *)name nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(for:firstBytes:name:));
+(nullable __kindof XADArchiveParser *)archiveParserForFileURL:(NSURL *)filename error:(NSError *_Nullable __autoreleasing *_Nullable)errorptr NS_SWIFT_NAME(archiveParser(for:));


-(instancetype)init NS_DESIGNATED_INITIALIZER;

@property (nonatomic, retain) XADHandle *handle;
@property (NS_NONATOMIC_IOSONLY, retain, nullable) XADResourceFork *resourceFork;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *name;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *filename;
@property (NS_NONATOMIC_IOSONLY, copy) NSArray<NSString*> *allFilenames;

@property (NS_NONATOMIC_IOSONLY, assign, nullable) id<XADArchiveParserDelegate> delegate;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDictionary<XADArchiveKeys,id> *properties;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *currentFilename;

@property (NS_NONATOMIC_IOSONLY, getter=isEncrypted, readonly) BOOL encrypted;
@property (NS_NONATOMIC_IOSONLY, copy, nullable) NSString *password;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasPassword;

@property (NS_NONATOMIC_IOSONLY, copy) XADStringEncodingName encodingName;
@property (NS_NONATOMIC_IOSONLY, readonly) float encodingConfidence;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL caresAboutPasswordEncoding;
@property (nonatomic, copy, nullable) XADStringEncodingName passwordEncodingName;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADStringSource *stringSource;

-(nullable XADString *)linkDestinationForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict NS_SWIFT_UNAVAILABLE("Call throws on failure");
-(nullable XADString *)linkDestinationForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict error:(XADError *)errorptr NS_REFINED_FOR_SWIFT;
-(nullable XADString *)linkDestinationForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict nserror:(NSError *__autoreleasing __nullable*__nullable)errorptr;
-(nullable NSDictionary<NSString*,id> *)extendedAttributesForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;
-(NSData *)finderInfoForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;
#if __APPLE__
+(NSString*)possibleUTIForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;
#endif

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL wasStopped;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasChecksum;
-(BOOL)testChecksum NS_SWIFT_UNAVAILABLE("throws exception");
-(XADError)testChecksumWithoutExceptions NS_REFINED_FOR_SWIFT;
-(BOOL)testChecksumWithError:(NSError**)error NS_REFINED_FOR_SWIFT;



// Internal functions

+(NSArray<NSString*> *)scanForVolumesWithFilename:(NSString *)filename regex:(XADRegex *)regex;
+(NSArray<NSString*> *)scanForVolumesWithFilename:(NSString *)filename
regex:(XADRegex *)regex firstFileExtension:(nullable NSString *)firstext;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL shouldKeepParsing;

-(CSHandle *)handleAtDataOffsetForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;
@property (NS_NONATOMIC_IOSONLY, readonly, retain) XADSkipHandle *skipHandle;
-(CSHandle *)zeroLengthHandleWithChecksum:(BOOL)checksum;
-(nullable CSHandle *)subHandleFromSolidStreamForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasVolumes;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<NSNumber*> *volumeSizes;
@property (NS_NONATOMIC_IOSONLY, readonly, retain) CSHandle *currentHandle;

-(void)setObject:(id)object forPropertyKey:(XADArchiveKeys)key;
-(void)addPropertiesFromDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;
-(void)setIsMacArchive:(BOOL)ismac;

-(void)addEntryWithDictionary:(NSMutableDictionary<XADArchiveKeys,id> *)dict;
-(void)addEntryWithDictionary:(NSMutableDictionary<XADArchiveKeys,id> *)dict retainPosition:(BOOL)retainpos;

-(XADString *)XADStringWithString:(NSString *)string;
-(nullable XADString *)XADStringWithData:(NSData *)data;
-(nullable XADString *)XADStringWithData:(NSData *)data encodingName:(XADStringEncodingName)encoding;
-(nullable XADString *)XADStringWithBytes:(const void *)bytes length:(NSInteger)length;
-(nullable XADString *)XADStringWithBytes:(const void *)bytes length:(NSInteger)length encodingName:(XADStringEncodingName)encoding;
-(nullable XADString *)XADStringWithCString:(const char *)cstring;
-(nullable XADString *)XADStringWithCString:(const char *)cstring encodingName:(XADStringEncodingName)encoding;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADPath *XADPath;
-(XADPath *)XADPathWithString:(NSString *)string;
-(XADPath *)XADPathWithUnseparatedString:(NSString *)string;
-(XADPath *)XADPathWithData:(NSData *)data separators:(XADPathSeparator)separators;
-(XADPath *)XADPathWithData:(NSData *)data encodingName:(XADStringEncodingName)encoding separators:(XADPathSeparator)separators;
-(XADPath *)XADPathWithBytes:(const void *)bytes length:(NSInteger)length separators:(XADPathSeparator)separators;
-(XADPath *)XADPathWithBytes:(const void *)bytes length:(NSInteger)length encodingName:(XADStringEncodingName)encoding separators:(XADPathSeparator)separators;
-(XADPath *)XADPathWithCString:(const char *)cstring separators:(XADPathSeparator)separators;
-(XADPath *)XADPathWithCString:(const char *)cstring encodingName:(XADStringEncodingName)encoding separators:(XADPathSeparator)separators;

@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSData *encodedPassword;
@property (NS_NONATOMIC_IOSONLY, readonly, nullable) const char *encodedCStringPassword;

-(void)reportInterestingFileWithReason:(NSString *)reason,... NS_FORMAT_FUNCTION(1,2);
-(void)reportInterestingFileWithReason:(NSString *)reason format:(va_list)args NS_FORMAT_FUNCTION(1,0);



// Subclasses implement these:

#if __has_feature(objc_class_property)
@property (class, readonly) int requiredHeaderSize;
#else
+(int)requiredHeaderSize;
#endif
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name propertiesToAdd:(NSMutableDictionary<XADArchiveKeys,id> *)props;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
resourceFork:(XADResourceFork *)fork name:(NSString *)name propertiesToAdd:(NSMutableDictionary<XADArchiveKeys,id> *)props;
+(nullable NSArray<NSString*> *)volumesForHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name;

-(void)parse NS_SWIFT_UNAVAILABLE("Call throws on failure");
-(nullable CSHandle *)handleForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict wantChecksum:(BOOL)checksum NS_SWIFT_UNAVAILABLE("Call throws on failure");;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *formatName;

-(nullable CSHandle *)handleForSolidStreamWithObject:(id)obj wantChecksum:(BOOL)checksum;

//! Exception-free wrapper for subclass method.<br>
//! Will, in addition, return \c XADBreakError if the delegate
//! requested parsing to stop.
-(XADError)parseWithoutExceptions NS_REFINED_FOR_SWIFT;

//! Exception-free wrapper for subclass method.<br>
//! Will, in addition, pass \c XADBreakError and return \c NO if the delegate
//! requested parsing to stop.
-(BOOL)parseWithError:(NSError *__autoreleasing __nullable*__nullable)error;

//! Exception-free wrapper for subclass method.
-(nullable CSHandle *)handleForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict wantChecksum:(BOOL)checksum error:(nullable XADError *)errorptr NS_REFINED_FOR_SWIFT;
//! Exception-free wrapper for subclass method.
-(nullable CSHandle *)handleForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict wantChecksum:(BOOL)checksum nserror:(NSError *__autoreleasing __nullable*__nullable)errorptr ;

@end

@protocol XADArchiveParserDelegate <NSObject>
@optional

-(void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;
-(BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser;
-(void)archiveParserNeedsPassword:(XADArchiveParser *)parser;
-(void)archiveParser:(XADArchiveParser *)parser findsFileInterestingForReason:(NSString *)reason;

@end

NSMutableArray *XADSortVolumes(NSMutableArray *volumes,NSString *firstfileextension) UNAVAILABLE_ATTRIBUTE;

NS_ASSUME_NONNULL_END
