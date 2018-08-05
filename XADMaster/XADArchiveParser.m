#import "XADArchiveParser.h"
#import "CSFileHandle.h"
#import "CSMultiFileHandle.h"
#import "CSMemoryHandle.h"
#import "CSStreamHandle.h"
#import "XADCRCHandle.h"
#import "XADPlatform.h"

#import "XADZipParser.h"
#import "XADRARParser.h"
#import "XAD7ZipParser.h"
#import "XADTarParser.h"
#import "XADLZHParser.h"

#if !defined(XADMASTER_SIMPLE) && !XADMASTER_SIMPLE
#import "XADALZipParser.h"
#import "XADAppleSingleParser.h"
#import "XADARCParser.h"
#import "XADARJParser.h"
#import "XADArParser.h"
#import "XADBinHexParser.h"
#import "XADBzip2Parser.h"
#import "XADCABParser.h"
#import "XADCFBFParser.h"
#import "XADCompactProParser.h"
#import "XADCompressParser.h"
#import "XADCpioParser.h"
#import "XADCrunchParser.h"
#import "XADDiskDoublerParser.h"
#import "XADGzipParser.h"
#import "XADISO9660Parser.h"
#import "XADLBRParser.h"
#import "XADLibXADParser.h"
#import "XADLZHSFXParsers.h"
#import "XADLZMAAloneParser.h"
#import "XADLZXParser.h"
#import "XADMacBinaryParser.h"
#import "XADNDSParser.h"
#import "XADNowCompressParser.h"
#import "XADNSAParser.h"
#import "XADNSISParser.h"
#import "XADPackItParser.h"
#import "XADPDFParser.h"
#import "XADPowerPackerParser.h"
#import "XADPPMdParser.h"
#import "XADRAR5Parser.h"
#import "XADRPMParser.h"
#import "XADSARParser.h"
#import "XADSplitFileParser.h"
#import "XADSqueezeParser.h"
#import "XADStuffItParser.h"
#import "XADStuffIt5Parser.h"
#import "XADStuffItSplitParser.h"
#import "XADStuffItXParser.h"
#import "XADSWFParser.h"
#import "XADWARCParser.h"
#import "XADXARParser.h"
#import "XADXZParser.h"
#import "XADZipSFXParsers.h"
#import "XADZooParser.h"
#endif

#include <dirent.h>

#if TARGET_OS_MAC && !TARGET_OS_OSX
#include <MobileCoreServices/MobileCoreServices.h>
#endif

NSString *const XADFileNameKey=@"XADFileName";
NSString *const XADCommentKey=@"XADComment";
NSString *const XADFileSizeKey=@"XADFileSize";
NSString *const XADCompressedSizeKey=@"XADCompressedSize";
NSString *const XADCompressionNameKey=@"XADCompressionName";

NSString *const XADIsDirectoryKey=@"XADIsDirectory";
NSString *const XADIsResourceForkKey=@"XADIsResourceFork";
NSString *const XADIsArchiveKey=@"XADIsArchive";
NSString *const XADIsHiddenKey=@"XADIsHidden";
NSString *const XADIsLinkKey=@"XADIsLink";
NSString *const XADIsHardLinkKey=@"XADIsHardLink";
NSString *const XADLinkDestinationKey=@"XADLinkDestination";
NSString *const XADIsCharacterDeviceKey=@"XADIsCharacterDevice";
NSString *const XADIsBlockDeviceKey=@"XADIsBlockDevice";
NSString *const XADDeviceMajorKey=@"XADDeviceMajor";
NSString *const XADDeviceMinorKey=@"XADDeviceMinor";
NSString *const XADIsFIFOKey=@"XADIsFIFO";
NSString *const XADIsEncryptedKey=@"XADIsEncrypted";
NSString *const XADIsCorruptedKey=@"XADIsCorrupted";

NSString *const XADLastModificationDateKey=@"XADLastModificationDate";
NSString *const XADLastAccessDateKey=@"XADLastAccessDate";
NSString *const XADLastAttributeChangeDateKey=@"XADLastAttributeChangeDate";
NSString *const XADLastBackupDateKey=@"XADLastBackupDate";
NSString *const XADCreationDateKey=@"XADCreationDate";

NSString *const XADExtendedAttributesKey=@"XADExtendedAttributes";
NSString *const XADFileTypeKey=@"XADFileType";
NSString *const XADFileCreatorKey=@"XADFileCreator";
NSString *const XADFinderFlagsKey=@"XADFinderFlags";
NSString *const XADFinderInfoKey=@"XADFinderInfo";
NSString *const XADPosixPermissionsKey=@"XADPosixPermissions";
NSString *const XADPosixUserKey=@"XADPosixUser";
NSString *const XADPosixGroupKey=@"XADPosixGroup";
NSString *const XADPosixUserNameKey=@"XADPosixUserName";
NSString *const XADPosixGroupNameKey=@"XADPosixGroupName";
NSString *const XADDOSFileAttributesKey=@"XADDOSFileAttributes";
NSString *const XADWindowsFileAttributesKey=@"XADWindowsFileAttributes";
NSString *const XADAmigaProtectionBitsKey=@"XADAmigaProtectionBits";

NSString *const XADIndexKey=@"XADIndex";
NSString *const XADDataOffsetKey=@"XADDataOffset";
NSString *const XADDataLengthKey=@"XADDataLength";
NSString *const XADSkipOffsetKey=@"XADSkipOffset";
NSString *const XADSkipLengthKey=@"XADSkipLength";

NSString *const XADIsSolidKey=@"XADIsSolid";
NSString *const XADFirstSolidIndexKey=@"XADFirstSolidIndex";
NSString *const XADFirstSolidEntryKey=@"XADFirstSolidEntry";
NSString *const XADNextSolidIndexKey=@"XADNextSolidIndex";
NSString *const XADNextSolidEntryKey=@"XADNextSolidEntry";
NSString *const XADSolidObjectKey=@"XADSolidObject";
NSString *const XADSolidOffsetKey=@"XADSolidOffset";
NSString *const XADSolidLengthKey=@"XADSolidLength";

NSString *const XADArchiveNameKey=@"XADArchiveName";
NSString *const XADVolumesKey=@"XADVolumes";
NSString *const XADVolumeScanningFailedKey=@"XADVolumeScanningFailed";
NSString *const XADDiskLabelKey=@"XADDiskLabel";


@implementation XADArchiveParser
@synthesize delegate;
@synthesize wasStopped = shouldstop;
@synthesize resourceFork = resourcefork;
@synthesize stringSource = stringsource;
@synthesize handle = sourcehandle;
@synthesize passwordEncodingName = passwordencodingname;

static NSMutableArray<Class> *parserclasses=nil;
static int maxheader=0;

+(void)initialize
{
	static BOOL hasinitialized=NO;
	if(hasinitialized) return;
	hasinitialized=YES;

	parserclasses=[[NSMutableArray arrayWithObjects:
					// Common formats
					[XADZipParser class],
					[XADRARParser class],
					[XAD7ZipParser class],
					[XADTarParser class],
					
					// Less common formats
					[XADLZHParser class],

#if !defined(XADMASTER_SIMPLE) && !XADMASTER_SIMPLE
		// Common formats
		[XADRAR5Parser class],
		[XADGzipParser class],
		[XADBzip2Parser class],

		// Mac formats
		[XADStuffItParser class],
		[XADStuffIt5Parser class],
		[XADStuffIt5ExeParser class],
		[XADStuffItSplitParser class],
		[XADStuffItXParser class],
		[XADBinHexParser class],
		[XADMacBinaryParser class],
		[XADAppleSingleParser class],
		[XADDiskDoublerParser class],
		[XADPackItParser class],
		[XADNowCompressParser class],

		// Less common formats
		[XADPPMdParser class],
		[XADXARParser class],
		[XADCompressParser class],
		[XADRPMParser class],
		[XADXZParser class],
		[XADSWFParser class],
		[XADPDFParser class],
		[XADALZipParser class],
		[XADCABParser class],
		[XADCFBFParser class],
		[XADCABSFXParser class],
		[XADLZHAmigaSFXParser class],
		[XADLZHCommodore64SFXParser class],
		[XADLZHSFXParser class],
		[XADZooParser class],
		[XADLZXParser class],
		[XADPowerPackerParser class],
		[XADNDSParser class],
		[XADNSAParser class],
		[XADSARParser class],
		[XADArParser class],
		[XADWARCParser class],

		// Detectors that require lots of work
		[XADWinZipSFXParser class],
		[XADZipItSEAParser class],
		[XADZipSFXParser class],
		[XADEmbeddedRARParser class],
		[XADEmbeddedRAR5Parser class],
		[XAD7ZipSFXParser class],
		[XADNSISParser class],
		[XADGzipSFXParser class],
		[XADCompactProParser class],
		[XADARJParser class],
		[XADZipMultiPartParser class],

		// Over-eager detectors
		[XADARCParser class],
		[XADARCSFXParser class],
		[XADSqueezeParser class],
		[XADCrunchParser class],
		[XADLBRParser class],
		[XADLZMAAloneParser class],
		[XADCpioParser class],
		[XADSplitFileParser class],
		[XADISO9660Parser class],

		// LibXAD
		[XADLibXADParser class],
#endif
	nil] retain];

	for(Class class in parserclasses)
	{
		int header=[class requiredHeaderSize];
		if(header>maxheader) maxheader=header;
	}
}

+(void)load
{
	if ([NSError respondsToSelector:@selector(setUserInfoValueProviderForDomain:provider:)]) {
		[NSError setUserInfoValueProviderForDomain:XADErrorDomain provider:^id _Nullable(NSError * _Nonnull err, NSString * _Nonnull userInfoKey) {
			if ([userInfoKey isEqualToString:NSLocalizedDescriptionKey]) {
				NSString *nonLocDes = [XADException describeXADError:(XADError)err.code];
				NSString *locDes = [[NSBundle bundleForClass:[XADException class]] localizedStringForKey:nonLocDes value:nonLocDes table:@"XADErrors"];
				return locDes;
			}
			return nil;
		}];
	}
}

+(Class)archiveParserClassForHandle:(CSHandle *)handle firstBytes:(NSData *)header
resourceFork:(XADResourceFork *)fork name:(NSString *)name propertiesToAdd:(NSMutableDictionary *)props
{
	for(Class parserclass in parserclasses)
	{
		[handle seekToFileOffset:0];
		[props removeAllObjects];

		@try {
			if([parserclass recognizeFileWithHandle:handle firstBytes:header
			resourceFork:fork name:name propertiesToAdd:props])
			{
				[handle seekToFileOffset:0];
				return parserclass;
			}
		} @catch(id e) {} // ignore parsers that throw errors on recognition or init
	}
	return nil;
}

+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle name:(NSString *)name
{
	return [self archiveParserForHandle:handle resourceFork:nil name:name];
}

+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle name:(NSString *)name error:(XADError *)errorptr
{
	if(errorptr) *errorptr=XADErrorNone;
	@try { return [self archiveParserForHandle:handle resourceFork:nil name:name]; }
	@catch(id exception) { if(errorptr) *errorptr=[XADException parseException:exception]; }
	return nil;
}

+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle resourceFork:(XADResourceFork *)fork name:(NSString *)name
{
	NSData *header=[handle readDataOfLengthAtMost:maxheader];
	return [self archiveParserForHandle:handle firstBytes:header resourceFork:fork name:name];
}

+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle resourceFork:(XADResourceFork *)fork name:(NSString *)name error:(XADError *)errorptr
{
	if(errorptr) *errorptr=XADErrorNone;
	@try { return [self archiveParserForHandle:handle resourceFork:fork name:name]; }
	@catch(id exception) { if(errorptr) *errorptr=[XADException parseException:exception]; }
	return nil;
}

+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header name:(NSString *)name
{
	return [self archiveParserForHandle:handle firstBytes:header resourceFork:nil name:name];
}

+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header name:(NSString *)name error:(XADError *)errorptr
{
	if(errorptr) *errorptr=XADErrorNone;
	@try { return [self archiveParserForHandle:handle firstBytes:header resourceFork:nil name:name]; }
	@catch(id exception) { if(errorptr) *errorptr=[XADException parseException:exception]; }
	return nil;
}

+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header resourceFork:(XADResourceFork *)fork name:(NSString *)name;
{
	NSMutableDictionary *props=[NSMutableDictionary dictionary];

	Class parserclass=[self archiveParserClassForHandle:handle firstBytes:header
	resourceFork:fork name:name propertiesToAdd:props];

	XADArchiveParser *parser=[[parserclass new] autorelease];
	parser.handle = handle;
	parser.resourceFork = fork;
	parser.name = name;

	[parser addPropertiesFromDictionary:props];

	return parser;
}

+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header resourceFork:(XADResourceFork *)fork name:(NSString *)name error:(XADError *)errorptr
{
	if(errorptr) *errorptr=XADErrorNone;
	@try { return [self archiveParserForHandle:handle firstBytes:header resourceFork:fork name:name]; }
	@catch(id exception) { if(errorptr) *errorptr=[XADException parseException:exception]; }
	return nil;
}

+(XADArchiveParser *)archiveParserForPath:(NSString *)filename
{
	CSHandle *handle=[CSFileHandle fileHandleForReadingAtPath:filename];
	NSData *header=[handle readDataOfLengthAtMost:maxheader];

	CSHandle *forkhandle=[XADPlatform handleForReadingResourceForkAtPath:filename];
	XADResourceFork *fork=[XADResourceFork resourceForkWithHandle:forkhandle error:NULL];

	NSMutableDictionary *props=[NSMutableDictionary dictionary];

	Class parserclass=[self archiveParserClassForHandle:handle
	firstBytes:header resourceFork:fork name:filename propertiesToAdd:props];
	if(!parserclass) return nil;

	// Attempt to create a multi-volume parser, if we can find the volumes.
	@try
	{
		NSArray *volumes=[parserclass volumesForHandle:handle firstBytes:header name:filename];
		[handle seekToFileOffset:0];

		if(volumes)
		{
			if(volumes.count>1)
			{
				CSHandle *multihandle=[CSMultiFileHandle handleWithPathArray:volumes];

				XADArchiveParser *parser=[[parserclass new] autorelease];
				parser.handle = multihandle;
				parser.resourceFork = fork;
				parser.allFilenames = volumes;
				[parser addPropertiesFromDictionary:props];

				return parser;
			}
			else if(volumes)
			{
				// An empty array means scanning failed. Set a flag to
				// warn the caller, and fall through to single-file mode.
				props[XADVolumeScanningFailedKey] = @YES;
			}
		}
	}
	@catch(id e) { } // Fall through to a single file instead.

	XADArchiveParser *parser=[[parserclass alloc] init];
	parser.handle = handle;
	parser.resourceFork = fork;
	parser.filename = filename;
	[parser addPropertiesFromDictionary:props];

	props[XADVolumesKey] = @[filename];
	[parser addPropertiesFromDictionary:props];

	return [parser autorelease];
}

+(XADArchiveParser *)archiveParserForPath:(NSString *)filename error:(XADError *)errorptr
{
	if(errorptr) *errorptr=XADErrorNone;
	@try { return [self archiveParserForPath:filename]; }
	@catch(id exception) { if(errorptr) *errorptr=[XADException parseException:exception]; }
	return nil;
}

+(XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary *)entry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum
{
	return [self archiveParserForEntryWithDictionary:entry resourceForkDictionary:nil archiveParser:parser wantChecksum:checksum];
}

+(XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary *)entry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum error:(XADError *)errorptr
{
	if(errorptr) *errorptr=XADErrorNone;
	@try { return [self archiveParserForEntryWithDictionary:entry resourceForkDictionary:nil archiveParser:parser wantChecksum:checksum]; }
	@catch(id exception) { if(errorptr) *errorptr=[XADException parseException:exception]; }
	return nil;
}

+(XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary *)entry resourceForkDictionary:(NSDictionary *)forkentry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum
{
	XADResourceFork *fork=nil;
	if(forkentry)
	{
		CSHandle *forkhandle=[parser handleForEntryWithDictionary:forkentry wantChecksum:checksum];
		if(forkhandle)
		{
			fork=[XADResourceFork resourceForkWithHandle:forkhandle];
			if(checksum && forkhandle.hasChecksum)
			{
				[forkhandle seekToEndOfFile];
				if(!forkhandle.checksumCorrect) [XADException raiseChecksumException];
			}
		}
	}

	CSHandle *handle=[parser handleForEntryWithDictionary:entry wantChecksum:checksum];
	if(!handle) [XADException raiseNotSupportedException];

	NSString *filename=[entry[XADFileNameKey] string];
	XADArchiveParser *subparser=[XADArchiveParser archiveParserForHandle:handle resourceFork:fork name:filename];
	if(!subparser) return nil;

	if(parser.hasPassword) subparser.password = parser.password;
	if(parser.stringSource.hasFixedEncoding) subparser.encodingName = parser.encodingName;
	if(parser->passwordencodingname) subparser.passwordEncodingName = parser->passwordencodingname;

	return subparser;
}

+(XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary *)entry resourceForkDictionary:(NSDictionary *)forkentry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum error:(XADError *)errorptr
{
	if(errorptr) *errorptr=XADErrorNone;
	@try { return [self archiveParserForEntryWithDictionary:entry resourceForkDictionary:forkentry archiveParser:parser wantChecksum:checksum]; }
	@catch(id exception) { if(errorptr) *errorptr=[XADException parseException:exception]; }
	return nil;
}

+(XADArchiveParser *)archiveParserForFileURL:(NSURL *)filename
{
	CSHandle *handle=[CSFileHandle fileHandleForReadingAtFileURL:filename];
	NSData *header=[handle readDataOfLengthAtMost:maxheader];
	
	CSHandle *forkhandle=[XADPlatform handleForReadingResourceForkAtFileURL:filename];
	XADResourceFork *fork=[XADResourceFork resourceForkWithHandle:forkhandle error:NULL];
	
	NSMutableDictionary *props=[NSMutableDictionary dictionary];
	
	Class parserclass=[self archiveParserClassForHandle:handle
											 firstBytes:header resourceFork:fork name:filename.path propertiesToAdd:props];
	if(!parserclass) return nil;
	
	// Attempt to create a multi-volume parser, if we can find the volumes.
	@try
	{
		NSArray *volumes=[parserclass volumesForHandle:handle firstBytes:header name:filename.path];
		[handle seekToFileOffset:0];
		
		if(volumes)
		{
			if(volumes.count>1)
			{
				CSHandle *multihandle=[CSMultiFileHandle handleWithPathArray:volumes];
				
				XADArchiveParser *parser=[[parserclass new] autorelease];
				parser.handle = multihandle;
				parser.resourceFork = fork;
				parser.allFilenames = volumes;
				[parser addPropertiesFromDictionary:props];
				
				return parser;
			}
			else if(volumes)
			{
				// An empty array means scanning failed. Set a flag to
				// warn the caller, and fall through to single-file mode.
				props[XADVolumeScanningFailedKey] = @YES;
			}
		}
	}
	@catch(id e) { } // Fall through to a single file instead.
	
	XADArchiveParser *parser=[[parserclass alloc] init];
	parser.handle = handle;
	parser.resourceFork = fork;
	parser.filename = filename.path;
	[parser addPropertiesFromDictionary:props];
	
	props[XADVolumesKey] = @[filename];
	[parser addPropertiesFromDictionary:props];
	
	return [parser autorelease];
}



-(instancetype)init
{
	if((self=[super init]))
	{
		sourcehandle=nil;
		skiphandle=nil;
		resourcefork=nil;
		delegate=nil;
		password=nil;
		passwordencodingname=nil;
		caresaboutpasswordencoding=NO;

		stringsource=[[XADStringSource alloc] init];

		properties=[NSMutableDictionary new];

		currsolidobj=nil;
		currsolidhandle=nil;

		currindex=0;

		parsersolidobj=nil;
		firstsoliddict=prevsoliddict=nil;

		forcesolid=NO;

		shouldstop=NO;
	}
	return self;
}

-(void)dealloc
{
	[sourcehandle release];
	[skiphandle release];
	[password release];
	[passwordencodingname release];
	[stringsource release];
	[properties release];
	[currsolidobj release];
	[currsolidhandle release];
	[firstsoliddict release];
	[prevsoliddict release];
	[resourcefork release];
	[super dealloc];
}


-(void)setHandle:(CSHandle *)newhandle
{
	[sourcehandle autorelease];
	sourcehandle=[newhandle retain];

	// If the handle is a CSStreamHandle, it can not seek, so treat
	// this like a solid archive (for instance, .tar.gz). Also, it will
	// usually be wrapped in a CSSubHandle so unwrap it first.
	CSHandle *testhandle=newhandle;
	if([testhandle isKindOfClass:[CSSubHandle class]]) testhandle=((CSSubHandle *)testhandle).parentHandle;

	if([testhandle isKindOfClass:[CSStreamHandle class]]) forcesolid=YES;
	else forcesolid=NO;
}

-(NSString *)name { return properties[XADArchiveNameKey]; }

-(void)setName:(NSString *)newname
{
	properties[XADArchiveNameKey] = newname.lastPathComponent;
}

-(NSString *)filename { return properties[XADVolumesKey][0]; }

-(void)setFilename:(NSString *)filename
{
	properties[XADVolumesKey] = @[filename];
	self.name = filename;
}

-(NSArray *)allFilenames { return properties[XADVolumesKey]; }

-(void)setAllFilenames:(NSArray *)newnames
{
	properties[XADVolumesKey] = newnames;
	self.name = newnames[0];
}


-(NSDictionary *)properties { return [NSDictionary dictionaryWithDictionary:properties]; }

-(NSString *)currentFilename
{
	if([sourcehandle isKindOfClass:[CSSegmentedHandle class]])
	{
		return [[(CSSegmentedHandle *)sourcehandle currentHandle] name];
	}
	else
	{
		return self.filename;
	}
}

-(BOOL)isEncrypted
{
	NSNumber *isencrypted=properties[XADIsEncryptedKey];
	return isencrypted&&isencrypted.boolValue;
}

-(NSString *)password
{
	if(!password)
	{
		if([delegate respondsToSelector:@selector(archiveParserNeedsPassword:)]) {
			[delegate archiveParserNeedsPassword:self];
		}
		if(!password) return @"";
	}
	return password;
}

-(BOOL)hasPassword
{
	return password!=nil;
}

-(void)setPassword:(NSString *)newpassword
{
	[password autorelease];
	password=[newpassword copy];

	// Make sure to invalidate any remaining solid handles, as they will need to change
	// for the new password.
	[currsolidobj release];
	currsolidobj=nil;
	[currsolidhandle release];
	currsolidhandle=nil;
}

-(NSString *)encodingName
{
	return stringsource.encodingName;
}

-(float)encodingConfidence
{
	return stringsource.confidence;
}

-(void)setEncodingName:(NSString *)encodingname
{
	stringsource.fixedEncodingName = encodingname;
}

@synthesize caresAboutPasswordEncoding = caresaboutpasswordencoding;

-(NSString *)passwordEncodingName
{
	if(!passwordencodingname) return self.encodingName;
	else return passwordencodingname;
}




-(XADString *)linkDestinationForDictionary:(NSDictionary *)dict
{
	// Return the destination path for a link.

	// Check if this entry actually is a link.
	NSNumber *islink=dict[XADIsLinkKey];
	if(islink==nil||!islink.boolValue) return nil;

	// If the destination is stored in the dictionary, return it directly.
	XADString *linkdest=dict[XADLinkDestinationKey];
	if(linkdest) return linkdest;

	// If not, read the contents of the data stream as the destination (for Zip files and the like).
	CSHandle *handle=[self handleForEntryWithDictionary:dict wantChecksum:YES];
	NSData *linkdata=[handle remainingFileContents];
	if(handle.hasChecksum&&!handle.checksumCorrect) [XADException raiseChecksumException];

	return [self XADStringWithData:linkdata];
}

-(XADString *)linkDestinationForDictionary:(NSDictionary *)dict error:(XADError *)errorptr
{
	if(errorptr) *errorptr=XADErrorNone;
	@try { return [self linkDestinationForDictionary:dict]; }
	@catch(id exception) { if(errorptr) *errorptr=[XADException parseException:exception]; }
	return nil;
}

-(NSDictionary *)extendedAttributesForDictionary:(NSDictionary *)dict
{
	NSDictionary *originalattrs=dict[XADExtendedAttributesKey];

	// If the extended attributes already have a finderinfo,
	// just keep it and return them as such.
	if(originalattrs && originalattrs[@"com.apple.FinderInfo"])
	{
		return originalattrs;
	}

	// If we have or can build a finderinfo struct, add it.
	NSData *finderinfo=[self finderInfoForDictionary:dict];
	if(finderinfo)
	{
		if(originalattrs)
		{
			// If we have a set of extended attributes, extend it.
			NSMutableDictionary *newattrs=[NSMutableDictionary dictionaryWithDictionary:originalattrs];
			newattrs[@"com.apple.FinderInfo"] = finderinfo;
			return newattrs;
		}
		else
		{
			// If we do not have any extended attributes, create a
			// set that only contains a finderinfo.
			return @{@"com.apple.FinderInfo": finderinfo};
		}
	}

	return originalattrs;
}

-(NSData *)finderInfoForDictionary:(NSDictionary *)dict
{
	// Return a FinderInfo struct with extended info (32 bytes in size).
	NSData *finderinfo=dict[XADFinderInfoKey];
	if(finderinfo)
	{
		// If a FinderInfo struct already exists, return it. Extend it to 32 bytes if needed.

		if(finderinfo.length>=32) return finderinfo;
		NSMutableData *extendedinfo=[NSMutableData dataWithData:finderinfo];
		extendedinfo.length = 32;
		return extendedinfo;
	}
	else
	{
		// If a FinderInfo struct doesn't exist, try to make one.

		uint8_t finderinfo[32]={ 0x00 };

		NSNumber *dirnum=dict[XADIsDirectoryKey];
		BOOL isdir=dirnum&&dirnum.boolValue;
		if(!isdir)
		{
			NSNumber *typenum=dict[XADFileTypeKey];
			NSNumber *creatornum=dict[XADFileCreatorKey];

			if(typenum != nil) CSSetUInt32BE(&finderinfo[0],typenum.unsignedIntValue);
			if(creatornum != nil) CSSetUInt32BE(&finderinfo[4],creatornum.unsignedIntValue);
		}

		NSNumber *flagsnum=dict[XADFinderFlagsKey];
		if(flagsnum != nil) CSSetUInt16BE(&finderinfo[8],flagsnum.unsignedShortValue);

		// Check if any data was filled in at all. If not, return nil.
		bool zero=true;
		for(int i=0;zero && i<sizeof(finderinfo);i++) if(finderinfo[i]!=0) zero=false;
		if(zero) return nil;

		return [NSData dataWithBytes:finderinfo length:32];
	}
}

-(BOOL)hasChecksum { return sourcehandle.hasChecksum; }

-(BOOL)testChecksum
{
	if(!sourcehandle.hasChecksum) return YES;
	[sourcehandle seekToEndOfFile];
	return sourcehandle.checksumCorrect;
}

-(XADError)testChecksumWithoutExceptions
{
	@try { if(![self testChecksum]) return XADErrorChecksum; }
	@catch(id exception) { return [XADException parseException:exception]; }
	return XADErrorNone;
}

-(BOOL)testChecksumWithError:(NSError**)error
{
	@try {
		if(![self testChecksum]) {
			if (error) {
				*error = [NSError errorWithDomain:XADErrorDomain code:XADErrorChecksum userInfo:nil];
			}
			return NO;
		}
		
	} @catch(id exception) {
		if (error) {
			*error = [XADException parseExceptionReturningNSError:exception];
		}
		return NO;
		
	}
	return YES;
}


// Internal functions

+(NSArray *)scanForVolumesWithFilename:(NSString *)filename regex:(XADRegex *)regex
{
	return [self scanForVolumesWithFilename:filename regex:regex firstFileExtension:nil];
}

+(NSArray *)scanForVolumesWithFilename:(NSString *)filename
regex:(XADRegex *)regex firstFileExtension:(NSString *)firstext
{
	NSMutableArray *volumes=[NSMutableArray array];

	NSString *directory=filename.stringByDeletingLastPathComponent;
	if(directory.length==0) directory=nil;

	NSString *dirpath=directory;
	if(!dirpath) dirpath=@".";

	NSArray *dircontents=[XADPlatform contentsOfDirectoryAtPath:dirpath];
	if(!dircontents) return @[];

	NSEnumerator *enumerator=[dircontents objectEnumerator];

	NSString *direntry;
	while((direntry=[enumerator nextObject]))
	{
		NSString *filename;
		if(directory) filename=[directory stringByAppendingPathComponent:direntry];
		else filename=direntry;

		if([regex matchesString:filename]) [volumes addObject:filename];
	}

	[volumes sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
		NSString *str1=obj1;
		NSString *str2=obj2;
		BOOL isfirst1=firstext&&[str1 rangeOfString:firstext options:NSAnchoredSearch|NSCaseInsensitiveSearch|NSBackwardsSearch].location!=NSNotFound;
		BOOL isfirst2=firstext&&[str2 rangeOfString:firstext options:NSAnchoredSearch|NSCaseInsensitiveSearch|NSBackwardsSearch].location!=NSNotFound;
		
		if(isfirst1&&!isfirst2) return NSOrderedAscending;
		else if(!isfirst1&&isfirst2) return NSOrderedDescending;
		//	else return [str1 compare:str2 options:NSCaseInsensitiveSearch|NSNumericSearch];
		else return [str1 compare:str2 options:NSCaseInsensitiveSearch];
	}];

	return volumes;
}



-(BOOL)shouldKeepParsing
{
	if(!delegate) return YES;
	if(shouldstop) return NO;

	if ([delegate respondsToSelector:@selector(archiveParsingShouldStop:)]) {
		shouldstop=[delegate archiveParsingShouldStop:self];
	}
	return !shouldstop;
}



-(CSHandle *)handleAtDataOffsetForDictionary:(NSDictionary *)dict
{
	NSNumber *skipoffs=dict[XADSkipOffsetKey];
	if(skipoffs != nil)
	{
		[skiphandle seekToFileOffset:skipoffs.longLongValue];

		NSNumber *length=dict[XADSkipLengthKey];
		if(length != nil) return [skiphandle nonCopiedSubHandleOfLength:length.longLongValue];
		else return skiphandle;
	}
	else
	{
		[sourcehandle seekToFileOffset:[dict[XADDataOffsetKey] longLongValue]];

		NSNumber *length=dict[XADDataLengthKey];
		if(length != nil) return [sourcehandle nonCopiedSubHandleOfLength:length.longLongValue];
		else return sourcehandle;
	}
}

-(XADSkipHandle *)skipHandle
{
	if(!skiphandle) skiphandle=[[XADSkipHandle alloc] initWithHandle:sourcehandle];
	return skiphandle;
}

-(CSHandle *)zeroLengthHandleWithChecksum:(BOOL)checksum
{
	CSHandle *zero=[CSMemoryHandle memoryHandleForReadingData:[NSData data]];
	if(checksum) zero=[XADCRCHandle IEEECRC32HandleWithHandle:zero length:0 correctCRC:0 conditioned:NO];
	return zero;
}

-(CSHandle *)subHandleFromSolidStreamForEntryWithDictionary:(NSDictionary *)dict
{
	id solidobj=dict[XADSolidObjectKey];

	if(solidobj!=currsolidobj)
	{
		[currsolidobj release];
		currsolidobj=[solidobj retain];
		[currsolidhandle release];
		currsolidhandle=[[self handleForSolidStreamWithObject:solidobj wantChecksum:YES] retain];
	}

	if(!currsolidhandle) return nil;

	off_t start=[dict[XADSolidOffsetKey] longLongValue];
	off_t size=[dict[XADSolidLengthKey] longLongValue];
	return [currsolidhandle nonCopiedSubHandleFrom:start length:size];
}




-(BOOL)hasVolumes
{
	return [sourcehandle isKindOfClass:[XADSegmentedHandle class]];
}

-(NSArray *)volumeSizes
{
	if([sourcehandle isKindOfClass:[XADSegmentedHandle class]])
	{
		return [(XADSegmentedHandle *)sourcehandle segmentSizes];
	}
	else
	{
		return @[@([sourcehandle fileSize])];
	}
}

-(CSHandle *)currentHandle
{
	if([sourcehandle isKindOfClass:[CSSegmentedHandle class]]) return [(CSSegmentedHandle *)sourcehandle currentHandle];
	else return sourcehandle;
}



-(void)setObject:(id)object forPropertyKey:(NSString *)key { properties[key] = object; }

-(void)addPropertiesFromDictionary:(NSDictionary *)dict { [properties addEntriesFromDictionary:dict]; }

-(void)setIsMacArchive:(BOOL)ismac { stringsource.prefersMacEncodings = ismac; }




-(void)addEntryWithDictionary:(NSMutableDictionary *)dict
{
	[self addEntryWithDictionary:dict retainPosition:NO];
}

-(void)addEntryWithDictionary:(NSMutableDictionary *)dict retainPosition:(BOOL)retainpos
{
	// If the caller has requested to stop parsing, discard entry.
	if(!self.shouldKeepParsing) return;

	// Add index and increment.
	dict[XADIndexKey] = @(currindex);
	currindex++;

	// If an encrypted file is added, set the global encryption flag.
	NSNumber *enc=dict[XADIsEncryptedKey];
	if(enc&&enc.boolValue) [self setObject:@YES forPropertyKey:XADIsEncryptedKey];

	// Same for the corrupted flag.
	NSNumber *cor=dict[XADIsCorruptedKey];
	if(cor&&cor.boolValue) [self setObject:@YES forPropertyKey:XADIsCorruptedKey];

	// LinkDestination implies IsLink.
	XADString *linkdest=dict[XADLinkDestinationKey];
	if(linkdest) dict[XADIsLinkKey] = @YES;

	// Extract further flags from PosixPermissions, if possible.
	NSNumber *perms=dict[XADPosixPermissionsKey];
	if(perms != nil)
	switch(perms.unsignedIntValue&0xf000)
	{
		case 0x1000: dict[XADIsFIFOKey] = @YES; break;
		case 0x2000: dict[XADIsCharacterDeviceKey] = @YES; break;
		// Do not automatically handles directories. Parsers need to do this, or else Ditto parsing will break.
		//case 0x4000: [dict setObject:[NSNumber numberWithBool:YES] forKey:XADIsDirectoryKey]; break;
		case 0x6000: dict[XADIsBlockDeviceKey] = @YES; break;
		case 0xa000: dict[XADIsLinkKey] = @YES; break;
	}

	// Set hidden flag if DOS or Windows file attributes are available and indicate it.
	NSNumber *attrs=dict[XADDOSFileAttributesKey];
	if(attrs == nil) attrs=dict[XADWindowsFileAttributesKey];
	if(attrs != nil)
	{
		if(attrs.intValue&0x02) dict[XADIsHiddenKey] = @YES;
	}

	// Extract finderinfo from extended attributes, if present.
	// Overwrite whatever finderinfo was provided, on the assumption that
	// the extended attributes are more authoritative.
	NSData *extfinderinfo=dict[XADExtendedAttributesKey][@"com.apple.FinderInfo"];
	if(extfinderinfo) dict[XADFinderInfoKey] = extfinderinfo;

	// Extract Spotlight comment from extended attributes, if present,
	// and if there is not already a comment.
	NSData *extcomment=dict[XADExtendedAttributesKey][@"com.apple.metadata:kMDItemFinderComment"];
	XADString *actualcomment=dict[XADCommentKey];
	if(extcomment && !actualcomment)
	{
		id plist=[NSPropertyListSerialization propertyListWithData:extcomment
		options:0 format:NULL error:NULL];

		if(plist&&[plist isKindOfClass:[NSString class]])
		dict[XADCommentKey] = [self XADStringWithString:plist];
	}

	// Extract type, creator and finderflags from finderinfo.
	NSData *finderinfo=dict[XADFinderInfoKey];
	if(finderinfo&&finderinfo.length>=10)
	{
		const uint8_t *bytes=finderinfo.bytes;
		NSNumber *isdir=dict[XADIsDirectoryKey];

		if(isdir==nil||!isdir.boolValue)
		{
			uint32_t filetype=CSUInt32BE(bytes+0);
			uint32_t filecreator=CSUInt32BE(bytes+4);

			if(filetype) dict[XADFileTypeKey] = @(filetype);
			if(filecreator) dict[XADFileCreatorKey] = @(filecreator);
		}

		int finderflags=CSUInt16BE(bytes+8);
		if(finderflags) dict[XADFinderFlagsKey] = @(finderflags);
	}

	// If this is an embedded archive that can't seek, force a solid flag if one isn't already present.
	if(forcesolid && !dict[XADSolidObjectKey]) dict[XADSolidObjectKey] = sourcehandle;

	// Handle solidness - set FirstSolid, NextSolid and IsSolid depending on SolidObject.
	id solidobj=dict[XADSolidObjectKey];
	if(solidobj)
	{
		if(solidobj==parsersolidobj)
		{
			dict[XADIsSolidKey] = @YES;
			dict[XADFirstSolidIndexKey] = firstsoliddict[XADIndexKey];
			dict[XADFirstSolidEntryKey] = [NSValue valueWithNonretainedObject:firstsoliddict];
			prevsoliddict[XADNextSolidIndexKey] = dict[XADIndexKey];
			prevsoliddict[XADNextSolidEntryKey] = [NSValue valueWithNonretainedObject:dict];

			[prevsoliddict release];
			prevsoliddict=[dict retain];
		}
		else
		{
			parsersolidobj=solidobj;

			[firstsoliddict release];
			[prevsoliddict release];
			firstsoliddict=[dict retain];
			prevsoliddict=[dict retain];
		}
	}
	else if(parsersolidobj)
	{
		parsersolidobj=nil;
		[firstsoliddict release];
		firstsoliddict=nil;
		[prevsoliddict release];
		prevsoliddict=nil;
	}

	// If a solid file is added, set the global solid flag.
	NSNumber *solid=dict[XADIsSolidKey];
	if(solid&&solid.boolValue) [self setObject:@YES forPropertyKey:XADIsSolidKey];



	@autoreleasepool {
		if ([delegate respondsToSelector:@selector(archiveParser:foundEntryWithDictionary:)]) {
			if (retainpos) {
				off_t pos=sourcehandle.offsetInFile;
				[delegate archiveParser:self foundEntryWithDictionary:dict];
				[sourcehandle seekToFileOffset:pos];
			} else
				[delegate archiveParser:self foundEntryWithDictionary:dict];
		}
	}
}



-(XADString *)XADStringWithString:(NSString *)string
{
	return [XADString XADStringWithString:string];
}

-(XADString *)XADStringWithData:(NSData *)data
{
	return [XADString analyzedXADStringWithData:data source:stringsource];
}

-(XADString *)XADStringWithData:(NSData *)data encodingName:(NSString *)encoding
{
	return [XADString decodedXADStringWithData:data encodingName:encoding];
}

-(XADString *)XADStringWithBytes:(const void *)bytes length:(NSInteger)length
{
	NSData *data=[NSData dataWithBytes:bytes length:length];
	return [XADString analyzedXADStringWithData:data source:stringsource];
}

-(XADString *)XADStringWithBytes:(const void *)bytes length:(NSInteger)length encodingName:(NSString *)encoding
{
	NSData *data=[NSData dataWithBytes:bytes length:length];
	return [XADString decodedXADStringWithData:data encodingName:encoding];
}

-(XADString *)XADStringWithCString:(const char *)cstring
{
	NSData *data=[NSData dataWithBytes:cstring length:strlen(cstring)];
	return [XADString analyzedXADStringWithData:data source:stringsource];
}

-(XADString *)XADStringWithCString:(const char *)cstring encodingName:(NSString *)encoding
{
	NSData *data=[NSData dataWithBytes:cstring length:strlen(cstring)];
	return [XADString decodedXADStringWithData:data encodingName:encoding];
}



-(XADPath *)XADPath
{
	return [XADPath emptyPath];
}

-(XADPath *)XADPathWithString:(NSString *)string
{
	return [XADPath separatedPathWithString:string];
}

-(XADPath *)XADPathWithUnseparatedString:(NSString *)string
{
	return [XADPath pathWithString:string];
}

-(XADPath *)XADPathWithData:(NSData *)data separators:(const char *)separators
{
	return [XADPath analyzedPathWithData:data source:stringsource separators:separators];
}

-(XADPath *)XADPathWithData:(NSData *)data encodingName:(NSString *)encoding separators:(const char *)separators
{
	return [XADPath decodedPathWithData:data encodingName:encoding separators:separators];
}

-(XADPath *)XADPathWithBytes:(const void *)bytes length:(NSInteger)length separators:(const char *)separators
{
	NSData *data=[NSData dataWithBytes:bytes length:length];
	return [XADPath analyzedPathWithData:data source:stringsource separators:separators];
}

-(XADPath *)XADPathWithBytes:(const void *)bytes length:(NSInteger)length encodingName:(NSString *)encoding separators:(const char *)separators
{
	NSData *data=[NSData dataWithBytes:bytes length:length];
	return [XADPath decodedPathWithData:data encodingName:encoding separators:separators];
}

-(XADPath *)XADPathWithCString:(const char *)cstring separators:(const char *)separators
{
	NSData *data=[NSData dataWithBytes:cstring length:strlen(cstring)];
	return [XADPath analyzedPathWithData:data source:stringsource separators:separators];
}

-(XADPath *)XADPathWithCString:(const char *)cstring encodingName:(NSString *)encoding separators:(const char *)separators
{
	NSData *data=[NSData dataWithBytes:cstring length:strlen(cstring)];
	return [XADPath decodedPathWithData:data encodingName:encoding separators:separators];
}



-(NSData *)encodedPassword
{
	caresaboutpasswordencoding=YES;

	NSString *pass=self.password;
	NSString *encodingname=self.passwordEncodingName;

	return [XADString dataForString:pass encodingName:encodingname];
}

-(const char *)encodedCStringPassword
{
	NSMutableData *data=[NSMutableData dataWithData:self.encodedPassword];
	[data increaseLengthBy:1];
	return data.bytes;
}



-(void)reportInterestingFileWithReason:(NSString *)reason,...
{
	va_list args;
	va_start(args,reason);
	[self reportInterestingFileWithReason:reason format:args];
	va_end(args);
}

-(void)reportInterestingFileWithReason:(NSString *)reason format:(va_list)args
{
	NSString *fullreason=[[NSString alloc] initWithFormat:reason arguments:args];
	
	if ([delegate respondsToSelector:@selector(archiveParser:findsFileInterestingForReason:)]) {
		[delegate archiveParser:self findsFileInterestingForReason:[NSString stringWithFormat:
																	@"%@: %@", self.formatName, fullreason]];
	}

	[fullreason release];
}


+(int)requiredHeaderSize { return 0; }

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name { return NO; }

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name propertiesToAdd:(NSMutableDictionary *)props
{
	return [self recognizeFileWithHandle:handle firstBytes:data name:name];
}

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data
resourceFork:(XADResourceFork *)fork name:(NSString *)name propertiesToAdd:(NSMutableDictionary *)props
{
	return [self recognizeFileWithHandle:handle firstBytes:data name:name propertiesToAdd:props];
}

+(NSArray *)volumesForHandle:(CSHandle *)handle firstBytes:(NSData *)data
name:(NSString *)name { return nil; }

-(void)parse {}
-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum { return nil; }
-(NSString *)formatName { return @""; } // TODO: combine names for nested archives

-(CSHandle *)handleForSolidStreamWithObject:(id)obj wantChecksum:(BOOL)checksum { return nil; }




-(XADError)parseWithoutExceptions
{
	@try { [self parse]; }
	@catch(id exception) { return [XADException parseException:exception]; }
	if(shouldstop) return XADErrorBreak;
	return XADErrorNone;
}

-(BOOL)parseWithError:(NSError**)error
{
	@try {
		[self parse];
	} @catch(id exception) {
		if (error) {
			*error = [XADException parseExceptionReturningNSError:exception];
		}
		return NO;
	}
	if(shouldstop) {
		if (error) {
			*error = [NSError errorWithDomain:XADErrorDomain code:XADErrorBreak userInfo:nil];
		}
		return NO;
	}
	return YES;
}

-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum error:(XADError *)errorptr
{
	if(errorptr) *errorptr=XADErrorNone;
	@try
	{
		CSHandle *handle=[self handleForEntryWithDictionary:dict wantChecksum:checksum];
		if(!handle&&errorptr) *errorptr=XADErrorNotSupported;
		return handle;
	}
	@catch(id exception)
	{
		if(errorptr) *errorptr=[XADException parseException:exception];
	}

	return nil;
}

#pragma mark - NSError functions

+(XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary *)entry resourceForkDictionary:(NSDictionary *)forkentry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr
{
	@try {
		XADArchiveParser *tmpParse = [self archiveParserForEntryWithDictionary:entry resourceForkDictionary:forkentry archiveParser:parser wantChecksum:checksum];
		if (tmpParse) {
			return tmpParse;
		}
	} @catch(id exception) {
		if(errorptr) {
			*errorptr=[XADException parseExceptionReturningNSError:exception];
		}
		return nil;
	}
	if (errorptr) {
		*errorptr = [NSError errorWithDomain:XADErrorDomain code:XADErrorNotSupported userInfo:nil];
	}
	return nil;
}

-(XADString *)linkDestinationForDictionary:(NSDictionary *)dict nserror:(NSError *__autoreleasing __nullable*__nullable)errorptr
{
	@try {
		XADString *tmpParse = [self linkDestinationForDictionary:dict];
		if (tmpParse) {
			return tmpParse;
		}
	} @catch(id exception) {
		if(errorptr) {
			*errorptr=[XADException parseExceptionReturningNSError:exception];
		}
		return nil;
	}
	if (errorptr) {
		*errorptr = [NSError errorWithDomain:XADErrorDomain code:XADErrorNotSupported userInfo:nil];
	}
	return nil;
}

+(XADArchiveParser *)archiveParserForEntryWithDictionary:(NSDictionary *)entry archiveParser:(XADArchiveParser *)parser wantChecksum:(BOOL)checksum nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr
{
	@try {
		XADArchiveParser *tmpParse = [self archiveParserForEntryWithDictionary:entry resourceForkDictionary:nil archiveParser:parser wantChecksum:checksum];
		if (tmpParse) {
			return tmpParse;
		}
	} @catch(id exception) {
		if(errorptr) {
			*errorptr=[XADException parseExceptionReturningNSError:exception];
		}
		return nil;
	}
	if (errorptr) {
		*errorptr = [NSError errorWithDomain:XADErrorDomain code:XADErrorNotSupported userInfo:nil];
	}
	return nil;
}

+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle name:(NSString *)name nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr
{
	@try {
		XADArchiveParser *tmpParse = [self archiveParserForHandle:handle resourceFork:nil name:name];
		if (tmpParse) {
			return tmpParse;
		}
	} @catch(id exception) {
		if(errorptr) {
			*errorptr=[XADException parseExceptionReturningNSError:exception];
		}
		return nil;
	}
	if (errorptr) {
		*errorptr = [NSError errorWithDomain:XADErrorDomain code:XADErrorNotSupported userInfo:nil];
	}
	return nil;
}

+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header resourceFork:(XADResourceFork *)fork name:(NSString *)name nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr
{
	@try {
		XADArchiveParser *tmpParse = [self archiveParserForHandle:handle firstBytes:header resourceFork:fork name:name];
		if (tmpParse) {
			return tmpParse;
		}
	} @catch(id exception) {
		if(errorptr) {
			*errorptr=[XADException parseExceptionReturningNSError:exception];
		}
		return nil;
	}
	if (errorptr) {
		*errorptr = [NSError errorWithDomain:XADErrorDomain code:XADErrorNotSupported userInfo:nil];
	}
	return nil;
}

+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle firstBytes:(NSData *)header name:(NSString *)name nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr
{
	@try {
		XADArchiveParser *tmpParse = [self archiveParserForHandle:handle firstBytes:header resourceFork:nil name:name];
		if (tmpParse) {
			return tmpParse;
		}
	} @catch(id exception) {
		if(errorptr) {
			*errorptr=[XADException parseExceptionReturningNSError:exception];
		}
		return nil;
	}
	if (errorptr) {
		*errorptr = [NSError errorWithDomain:XADErrorDomain code:XADErrorNotSupported userInfo:nil];
	}
	return nil;
}

+(XADArchiveParser *)archiveParserForFileURL:(NSURL *)filename error:(NSError * _Nullable *)errorptr
{
	@try {
		XADArchiveParser *tmpParse = [self archiveParserForFileURL:filename];
		if (tmpParse) {
			return tmpParse;
		}
	} @catch(id exception) {
		if(errorptr)
			*errorptr=[XADException parseExceptionReturningNSError:exception];
		
		return nil;
	}
	if (errorptr) {
		*errorptr = [NSError errorWithDomain:XADErrorDomain code:XADErrorNotSupported userInfo:@{NSURLErrorKey: filename}];
	}
	return nil;
}

+(XADArchiveParser *)archiveParserForPath:(NSString *)filename nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr
{
	@try {
		XADArchiveParser *tmpParse = [self archiveParserForPath:filename];
		if (tmpParse) {
			return tmpParse;
		}
	} @catch(id exception) {
		if(errorptr)
			*errorptr=[XADException parseExceptionReturningNSError:exception];
		
		return nil;
	}
	if (errorptr) {
		*errorptr = [NSError errorWithDomain:XADErrorDomain code:XADErrorNotSupported userInfo:@{NSFilePathErrorKey: filename}];
	}
	return nil;
}

+(XADArchiveParser *)archiveParserForHandle:(CSHandle *)handle resourceFork:(XADResourceFork *)fork name:(NSString *)name nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr
{
	@try { return [self archiveParserForHandle:handle resourceFork:fork name:name]; }
	@catch(id exception) {
		if(errorptr) {
			*errorptr=[XADException parseExceptionReturningNSError:exception];
		}
		return nil;
	}
	if (errorptr) {
		*errorptr = [NSError errorWithDomain:XADErrorDomain code:XADErrorNotSupported userInfo:nil];
	}
	return nil;
}

-(XADHandle *)handleForEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict wantChecksum:(BOOL)checksum nserror:(NSError * _Nullable *)errorptr
{
	@try
	{
		CSHandle *handle=[self handleForEntryWithDictionary:dict wantChecksum:checksum];
		if(!handle&&errorptr) *errorptr=[NSError errorWithDomain:XADErrorDomain code:XADErrorNotSupported userInfo:nil];
		return handle;
	}
	@catch(id exception)
	{
		if(errorptr) *errorptr=[XADException parseExceptionReturningNSError:exception];
	}
	
	return nil;
	
}

#pragma mark -

#if __APPLE__
+(NSString*)possibleUTIForDictionary:(NSDictionary<XADArchiveKeys,id> *)dict
{
#if 0
	if (dict[XADIsFIFOKey] && [dict[XADIsFIFOKey] boolValue]) {
		// TODO: find the UTI
	}
	
	if (dict[XADIsCharacterDeviceKey] && [dict[XADIsCharacterDeviceKey] boolValue]) {
		// TODO: find the UTI
	}

	if (dict[XADIsBlockDeviceKey] && [dict[XADIsBlockDeviceKey] boolValue]) {
		// TODO: find the UTI
	}
#endif

	if (dict[XADIsLinkKey] != nil && [dict[XADIsLinkKey] boolValue]) {
		return (NSString*)kUTTypeSymLink;
	}

	CFStringRef baseUTI = kUTTypeData;
	if (dict[XADIsDirectoryKey] != nil && [dict[XADIsDirectoryKey] boolValue]) {
		baseUTI = kUTTypeDirectory;
	}
	
#if TARGET_OS_OSX
	if (dict[XADFileTypeKey] != nil && [dict[XADFileTypeKey] unsignedIntValue] != 0) {
		NSNumber *numOSType = dict[XADFileTypeKey];
		CFStringRef strOSType = UTCreateStringForOSType(numOSType.unsignedIntValue);
		CFStringRef possibleOSUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassOSType, strOSType, baseUTI);
		CFRelease(strOSType);
		if (possibleOSUTI && UTTypeIsDeclared(possibleOSUTI)) {
			BOOL isGood = YES;
			
			if (isGood) {
				return CFBridgingRelease(possibleOSUTI);
			}
		}
		if (possibleOSUTI) {
			CFRelease(possibleOSUTI);
		}
	}
#endif
	NSString *lastPathComp = [dict[XADFileNameKey] lastPathComponent].pathExtension;
	CFStringRef possibleOSUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)(lastPathComp), baseUTI);
	if (possibleOSUTI == NULL || !UTTypeIsDeclared(possibleOSUTI)) {
		if (possibleOSUTI) {
			CFRelease(possibleOSUTI);
		}
		return (NSString*)baseUTI;
	}
	return CFBridgingRelease(possibleOSUTI);
}
#endif

@end
