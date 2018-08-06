#import <Foundation/Foundation.h>

#import "XADArchiveParser.h"
#import "XADUnarchiver.h"
#import "XADRegex.h"

#define XADNeverCreateEnclosingDirectory 0
#define XADAlwaysCreateEnclosingDirectory 1
#define XADCreateEnclosingDirectoryWhenNeeded 2

NS_ASSUME_NONNULL_BEGIN

@protocol XADSimpleUnarchiverDelegate;

@interface XADSimpleUnarchiver:NSObject<XADArchiveParserDelegate, XADUnarchiverDelegate>
{
	XADArchiveParser *parser;
	XADUnarchiver *unarchiver,*subunarchiver;

	BOOL shouldstop;

	NSString *destination,*enclosingdir;
	BOOL extractsubarchives,removesolo;
	BOOL overwrite,rename,skip;
	BOOL copydatetoenclosing,copydatetosolo,resetsolodate;
	BOOL propagatemetadata;

	NSMutableArray<XADRegex*> *regexes;
	NSMutableIndexSet *indices;

	NSMutableArray<NSDictionary<XADArchiveKeys,id>*> *entries;
	NSMutableArray<NSString*> *reasonsforinterest;
	NSMutableDictionary *renames;
	NSMutableSet *resourceforks;
	id metadata;
	NSString *unpackdestination,*finaldestination,*overridesoloitem;
	NSInteger numextracted;

	NSString *toplevelname;
	BOOL lookslikesolo;

	off_t totalsize,currsize,totalprogress;
}

+(nullable instancetype)simpleUnarchiverForPath:(NSString *)path NS_SWIFT_UNAVAILABLE("Call may throw exceptions, use init(for:error:) instead");
+(nullable instancetype)simpleUnarchiverForPath:(NSString *)path error:(nullable XADError *)errorptr;
+(nullable instancetype)simpleUnarchiverForPath:(NSString *)path nserror:(NSError *__autoreleasing _Nullable*_Nullable)errorptr;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
-(instancetype)initWithArchiveParser:(XADArchiveParser *)archiveparser;
-(instancetype)initWithArchiveParser:(XADArchiveParser *)archiveparser entries:(nullable NSArray<NSDictionary<XADArchiveKeys,id> *> *)entryarray NS_DESIGNATED_INITIALIZER;

@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADArchiveParser *archiveParser;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADArchiveParser *outerArchiveParser;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) XADArchiveParser *innerArchiveParser;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<NSString*> *reasonsForInterest;

@property (NS_NONATOMIC_IOSONLY, weak, nullable) id<XADSimpleUnarchiverDelegate> delegate;

// TODO: Encoding wrappers?

@property (NS_NONATOMIC_IOSONLY, copy, nullable) NSString *password;

@property (NS_NONATOMIC_IOSONLY, copy, nullable) NSString *destination;

@property (NS_NONATOMIC_IOSONLY, copy, nullable) NSString *enclosingDirectoryName;

@property (NS_NONATOMIC_IOSONLY) BOOL removesEnclosingDirectoryForSoloItems;

@property (NS_NONATOMIC_IOSONLY) BOOL alwaysOverwritesFiles;

@property (NS_NONATOMIC_IOSONLY) BOOL alwaysRenamesFiles;

@property (NS_NONATOMIC_IOSONLY) BOOL alwaysSkipsFiles;

@property (NS_NONATOMIC_IOSONLY) BOOL extractsSubArchives;

@property (NS_NONATOMIC_IOSONLY) BOOL copiesArchiveModificationTimeToEnclosingDirectory;

@property (NS_NONATOMIC_IOSONLY) BOOL copiesArchiveModificationTimeToSoloItems;

@property (NS_NONATOMIC_IOSONLY) BOOL resetsDateForSoloItems;

@property (NS_NONATOMIC_IOSONLY) BOOL propagatesRelevantMetadata;

@property (NS_NONATOMIC_IOSONLY) XADForkStyle macResourceForkStyle;

@property (NS_NONATOMIC_IOSONLY) BOOL preservesPermissions;
-(void)setPreserevesPermissions:(BOOL)preserve API_DEPRECATED_WITH_REPLACEMENT("setPreservesPermissions", macosx(10.0, 10.8), ios(3.0, 8.0));

@property (NS_NONATOMIC_IOSONLY) double updateInterval;

-(void)addGlobFilter:(NSString *)wildcard;
-(void)addRegexFilter:(XADRegex *)regex;
-(void)addIndexFilter:(NSInteger)index;
-(void)setIndices:(NSIndexSet *)indices;

@property (NS_NONATOMIC_IOSONLY, readonly) off_t predictedTotalSize;
-(off_t)predictedTotalSizeIgnoringUnknownFiles:(BOOL)ignoreunknown;

@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger numberOfItemsExtracted;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL wasSoloItem;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *actualDestination;
@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSString *soloItem;
@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSString *createdItem;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *createdItemOrActualDestination;



-(XADError)parse NS_REFINED_FOR_SWIFT;
-(XADError)_setupSubArchiveForEntryWithDataFork:(NSDictionary<XADArchiveKeys,id> *)datadict resourceFork:(nullable NSDictionary<XADArchiveKeys,id> *)resourcedict;

-(XADError)unarchive NS_REFINED_FOR_SWIFT;
-(XADError)_unarchiveRegularArchive;
-(XADError)_unarchiveSubArchive;

-(XADError)_finalizeExtraction;

-(void)_testForSoloItems:(NSDictionary<XADArchiveKeys,id> *)entry;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL _shouldStop;

-(nullable NSString *)_checkPath:(NSString *)path forEntryWithDictionary:(nullable NSDictionary<XADArchiveKeys,id> *)dict deferred:(BOOL)deferred;
-(BOOL)_recursivelyMoveItemAtPath:(NSString *)src toPath:(NSString *)dest overwrite:(BOOL)overwritethislevel;

+(NSString *)_findUniquePathForOriginalPath:(NSString *)path;
+(NSString *)_findUniquePathForOriginalPath:(NSString *)path reservedPaths:(nullable NSSet<NSString*> *)reserved;

@end



@protocol XADSimpleUnarchiverDelegate <NSObject>
@optional
-(void)simpleUnarchiverNeedsPassword:(XADSimpleUnarchiver *)unarchiver;

-(CSHandle *)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver outputHandleForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict;

-(nullable XADStringEncodingName)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver encodingNameForXADString:(id <XADString>)string;

-(BOOL)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver shouldExtractEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict to:(NSString *)path;
-(void)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver willExtractEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict to:(NSString *)path;
-(void)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver didExtractEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict to:(NSString *)path error:(XADError)error;

-(nullable NSString *)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver replacementPathForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict
originalPath:(NSString *)path suggestedPath:(NSString *)unique;
-(nullable NSString *)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver deferredReplacementPathForOriginalPath:(NSString *)path
suggestedPath:(NSString *)unique;

-(BOOL)extractionShouldStopForSimpleUnarchiver:(XADSimpleUnarchiver *)unarchiver;

-(void)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver
extractionProgressForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict
fileProgress:(off_t)fileprogress of:(off_t)filesize
totalProgress:(off_t)totalprogress of:(off_t)totalsize;
-(void)simpleUnarchiver:(XADSimpleUnarchiver *)unarchiver
estimatedExtractionProgressForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict
fileProgress:(double)fileprogress totalProgress:(double)totalprogress;

@end

NS_ASSUME_NONNULL_END

