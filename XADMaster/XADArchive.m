#define XAD_NO_DEPRECATED

#import "XADArchive.h"
#import "CSMemoryHandle.h"
#import "CSHandle.h"
#import "Progress.h"
#import "NSDateXAD.h"

#import <sys/stat.h>
#import <sys/time.h>


#if !__has_feature(objc_arc)
#error this file needs to be compiled with Automatic Reference Counting (ARC)
#endif

NSString *const XADResourceDataKey=@"XADResourceData";
NSString *const XADFinderFlags=@"XADFinderFlags";



@implementation XADArchive
@synthesize delegate;
@synthesize immediateExtractionFailed = immediatefailed;

+(XADArchive *)archiveForFile:(NSString *)filename
{
	return [[XADArchive alloc] initWithFile:filename];
}

+(XADArchive *)recursiveArchiveForFile:(NSString *)filename
{
	XADArchive *archive=[self archiveForFile:filename];

	while(archive.numberOfEntries==1)
	{
		XADArchive *subarchive=[[XADArchive alloc] initWithArchive:archive entry:0];
		if(subarchive) archive=subarchive;
		else
		{
			break;
		}
	}

	return archive;
}

+(NSArray *)volumesForFile:(NSString *)filename // deprecated
{
	return @[filename];
}




-(instancetype)init
{
	if((self=[super init]))
	{
		parser=nil;
		unarchiver=nil;
		delegate=nil;
		lasterror=XADErrorNone;
		immediatedestination=nil;
		immediatefailed=NO;
		immediatesize=0;
		parentarchive=nil;

		dataentries=[[NSMutableArray alloc] init];
		resourceentries=[[NSMutableArray alloc] init];
		namedict=nil;
	 }
	return self;
}

-(instancetype)initWithFile:(NSString *)file { return [self initWithFile:file delegate:nil error:NULL]; }

-(instancetype)initWithFile:(NSString *)file error:(XADError *)error { return [self initWithFile:file delegate:nil error:error]; }

-(instancetype)initWithFile:(NSString *)file delegate:(id)del error:(XADError *)error
{
	if((self=[self init]))
	{
		delegate=del;

		parser=[XADArchiveParser archiveParserForPath:file error:error];
		if(parser)
		{
			if([self _parseWithErrorPointer:error]) return self;
		}
		else if(error) *error=XADErrorDataFormat;
	}

	return nil;
}

-(instancetype)initWithFileURL:(NSURL *)file delegate:(id)del error:(NSError *_Nullable __autoreleasing *_Nullable)error
{
	if (self = [self init]) {
		delegate = del;
		
		parser=[XADArchiveParser archiveParserForFileURL:file error:error];
		if (parser) {
			XADError tmpErr=XADErrorNone;
			if ([self _parseWithErrorPointer:&tmpErr]) {
				return self;
			} else if (error) {
				*error = [NSError errorWithDomain:XADErrorDomain code:tmpErr userInfo:@{NSURLErrorKey: file}];
			}
		}
	}
	
	return nil;
}


-(instancetype)initWithData:(NSData *)data { return [self initWithData:data delegate:nil error:NULL]; }

-(instancetype)initWithData:(NSData *)data error:(XADError *)error { return [self initWithData:data delegate:nil error:error]; }

-(instancetype)initWithData:(NSData *)data delegate:(id)del error:(XADError *)error
{
	if((self=[self init]))
	{
		delegate=del;

		parser=[XADArchiveParser archiveParserForHandle:[CSMemoryHandle memoryHandleForReadingData:data] name:@""];
		if(parser)
		{
			if([self _parseWithErrorPointer:error]) return self;
		}
		else if(error) *error=XADErrorDataFormat;
	}
	return nil;
}



-(instancetype)initWithArchive:(XADArchive *)otherarchive entry:(NSInteger)n { return [self initWithArchive:otherarchive entry:n delegate:nil error:NULL]; }

-(instancetype)initWithArchive:(XADArchive *)otherarchive entry:(NSInteger)n error:(XADError *)error { return [self initWithArchive:otherarchive entry:n delegate:nil error:error]; }

-(instancetype)initWithArchive:(XADArchive *)otherarchive entry:(NSInteger)n nserror:(NSError *_Nullable __autoreleasing *_Nullable)error { return [self initWithArchive:otherarchive entry:n delegate:nil nserror:error]; }

-(instancetype)initWithArchive:(XADArchive *)otherarchive entry:(NSInteger)n delegate:(id)del nserror:(NSError *_Nullable __autoreleasing *_Nullable)error
{
	if((self=[self init]))
	{
		parentarchive=otherarchive;
		delegate=del;

		CSHandle *handle=[otherarchive handleForEntry:n nserror:error];
		if(handle)
		{
			parser=[XADArchiveParser archiveParserForHandle:handle name:[otherarchive nameOfEntry:n]];
			if(parser)
			{
                XADError tmpErr = XADErrorNone;
                if([self _parseWithErrorPointer:&tmpErr]) return self;
                if (error) {
                    *error = [NSError errorWithDomain:XADErrorDomain code:tmpErr userInfo:nil];
                }
			}
			else if(error) *error=[NSError errorWithDomain:XADErrorDomain code:XADErrorDataFormat userInfo:nil];
		}
	}

	return nil;
}

-(instancetype)initWithArchive:(XADArchive *)otherarchive entry:(NSInteger)n
     immediateExtractionTo:(NSString *)destination error:(XADError *)error
{
	return [self initWithArchive:otherarchive entry:n immediateExtractionTo:destination
	subArchives:NO error:error];
}

-(instancetype)initWithArchive:(XADArchive *)otherarchive entry:(NSInteger)n
     immediateExtractionTo:(NSString *)destination subArchives:(BOOL)sub error:(XADError *)error
{
	if((self=[self init]))
	{
		parentarchive=otherarchive;
		immediatedestination=destination;
		immediatesubarchives=sub;
		delegate=otherarchive;
		
		immediatesize=[otherarchive representativeSizeOfEntry:n];
		
		parser=[XADArchiveParser archiveParserForEntryWithDictionary:
				[otherarchive dataForkParserDictionaryForEntry:n]
													   archiveParser:otherarchive->parser wantChecksum:YES error:error];
		if(parser)
		{
			if([self _parseWithErrorPointer:error])
			{
				if(!immediatefailed)
				{
					XADError checksumerror=[parser testChecksumWithoutExceptions];
					if(checksumerror)
					{
						lasterror=checksumerror;
						if(error) *error=checksumerror;
						immediatefailed=YES;
					}
				}
				
				[self updateAttributesForDeferredDirectories];
				immediatedestination=nil;
				return self;
			}
		}
		else if(error) *error=XADErrorSubArchive;
	}
	
	return nil;
}

-(instancetype)initWithArchive:(XADArchive *)otherarchive entry:(NSInteger)n delegate:(id)del error:(XADError *)error
{
	if((self=[self init]))
	{
		parentarchive=otherarchive;
		delegate=del;
		
		CSHandle *handle=[otherarchive handleForEntry:n error:error];
		if(handle)
		{
			parser=[XADArchiveParser archiveParserForHandle:handle name:[otherarchive nameOfEntry:n]];
			if(parser)
			{
				if([self _parseWithErrorPointer:error]) return self;
			}
			else if(error) *error=XADErrorDataFormat;
		}
	}
	
	return nil;
}


-(instancetype)initWithArchive:(XADArchive *)otherarchive entry:(NSInteger)n
     immediateExtractionTo:(NSString *)destination subArchives:(BOOL)sub nserror:(NSError *_Nullable __autoreleasing *_Nullable)error
{
	if((self=[self init]))
	{
		parentarchive=otherarchive;
		immediatedestination=destination;
		immediatesubarchives=sub;
		delegate=otherarchive;

		immediatesize=[otherarchive representativeSizeOfEntry:n];

		parser=[XADArchiveParser archiveParserForEntryWithDictionary:
				[otherarchive dataForkParserDictionaryForEntry:n]
													   archiveParser:otherarchive->parser wantChecksum:YES nserror:error];
		if(parser)
		{
            XADError tmpErr = XADErrorNone;
			if([self _parseWithErrorPointer:&tmpErr])
			{
				if(!immediatefailed)
				{
					XADError checksumerror=[parser testChecksumWithoutExceptions];
					if(checksumerror)
					{
						lasterror=checksumerror;
						if(error) *error=[NSError errorWithDomain:XADErrorDomain code:checksumerror userInfo:nil];
						immediatefailed=YES;
					}
				}

				[self updateAttributesForDeferredDirectories];
				immediatedestination=nil;
				return self;
			} else if (error) {
				*error = [NSError errorWithDomain:XADErrorDomain code:tmpErr userInfo:nil];
			}

		}
        else if(error) *error=[NSError errorWithDomain:XADErrorDomain code:XADErrorSubArchive userInfo:nil];
	}

	return nil;
}



-(BOOL)_parseWithErrorPointer:(XADError *)error
{
	unarchiver=[[XADUnarchiver alloc] initWithArchiveParser:parser];

	parser.delegate = self;
	unarchiver.delegate = self;

	namedict=[[NSMutableDictionary alloc] init];

	XADError parseerror=[parser parseWithoutExceptions];
	if(parseerror)
	{
		lasterror=parseerror;
		if(error) *error=parseerror;
	}

	if(immediatefailed&&error) *error=lasterror;

	namedict=nil;

	return lasterror==XADErrorNone||dataentries.count!=0;
}

-(void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary *)dict
{
	if(immediatefailed) return; // ignore anything after a failure

	NSNumber *resnum=dict[XADIsResourceForkKey];
	BOOL isres=resnum&&resnum.boolValue;

	XADPath *name=dict[XADFileNameKey];

	NSNumber *index=namedict[name];
	if(index != nil) // Try to update an existing entry
	{
		int n=index.intValue;
		if(isres) // Adding a resource fork to an earlier data fork
		{
			if(resourceentries[n]==[NSNull null])
			{
				resourceentries[n] = dict;

				if(immediatedestination)
				{
					if(![self extractEntry:n to:immediatedestination
					deferDirectories:YES dataFork:NO resourceFork:YES])
					immediatefailed=YES;
				}

				return;
			}
		}
		else // Adding a data fork to an earlier resource fork
		{
			if(dataentries[n]==[NSNull null])
			{
				dataentries[n] = dict;

				if(immediatedestination)
				{
					if(immediatesubarchives&&[self entryIsArchive:n])
					{
						// Try to extract as archive, if the format is unknown, extract as regular file
						BOOL res;
						@try { res=[self extractArchiveEntry:n to:immediatedestination]; }
						@catch(id e) { res=NO; }

						if(!res&&lasterror==XADErrorDataFormat)
						{
							if(![self extractEntry:n to:immediatedestination
							deferDirectories:YES dataFork:YES resourceFork:NO])
							immediatefailed=YES;
						}
						else immediatefailed=YES;
					}
					else
					{
						if(![self extractEntry:n to:immediatedestination
						deferDirectories:YES dataFork:YES resourceFork:NO])
						immediatefailed=YES;
					}
				}

				return;
			}
		}
	}

	// Create a new entry instead

	if(isres)
	{
		[dataentries addObject:[NSNull null]];
		[resourceentries addObject:dict];
	}
	else
	{
		[dataentries addObject:dict];
		[resourceentries addObject:[NSNull null]];
	}

	namedict[name] = @(dataentries.count-1);

	if(immediatedestination)
	{
		NSInteger n=dataentries.count-1;
		if(immediatesubarchives&&[self entryIsArchive:n])
		{
			// Try to extract as archive, if the format is unknown, extract as regular file
			BOOL res;
			@try { res=[self extractArchiveEntry:n to:immediatedestination]; }
			@catch(id e) { res=NO; }

			if(!res)
			{
				if(lasterror==XADErrorDataFormat)
				{
					if(![self extractEntry:n to:immediatedestination
					deferDirectories:YES dataFork:YES resourceFork:YES])
					immediatefailed=YES;
				}
				else immediatefailed=YES;
			}
		}
		else
		{
			if(![self extractEntry:n to:immediatedestination
			deferDirectories:YES dataFork:YES resourceFork:YES])
			immediatefailed=YES;
		}
	}
}

-(BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser
{
	return immediatefailed;
}

-(void)archiveParserNeedsPassword:(XADArchiveParser *)parser
{
	if ([delegate respondsToSelector:@selector(archiveNeedsPassword:)]) {
		[delegate archiveNeedsPassword:self];
	}
}



-(NSString *)filename
{
	return parser.filename;
}

-(NSArray *)allFilenames
{
	return parser.allFilenames;
}

-(NSString *)formatName
{
	if(parentarchive) return [NSString stringWithFormat:@"%@ in %@",parser.formatName,parentarchive.formatName];
	else return parser.formatName;
}

-(BOOL)isEncrypted { return parser.encrypted; }

-(BOOL)isSolid
{
	NSNumber *issolid=parser.properties[XADIsSolidKey];
	if(issolid == nil) return NO;
	return issolid.boolValue;
}

-(BOOL)isCorrupted
{
	NSNumber *iscorrupted=parser.properties[XADIsCorruptedKey];
	if(iscorrupted == nil) return NO;
	return iscorrupted.boolValue;
}

-(NSInteger)numberOfEntries { return dataentries.count; }

-(NSString *)commonTopDirectory
{
	NSString *firstname=[self nameOfEntry:0];
	NSRange slash=[firstname rangeOfString:@"/"];

	NSString *directory;
	if(slash.location!=NSNotFound) directory=[firstname substringToIndex:slash.location];
	else if([self entryIsDirectory:0]) directory=firstname;
	else return nil;

	NSString *dirprefix=[directory stringByAppendingString:@"/"];

	NSInteger numentries=self.numberOfEntries;
	for(int i=1;i<numentries;i++)
	if(![[self nameOfEntry:i] hasPrefix:dirprefix]) return nil;

	return directory;
}

-(NSString *)comment
{
	return parser.properties[XADCommentKey];
}



-(NSString *)password { return parser.password; }

-(void)setPassword:(NSString *)newpassword { parser.password = newpassword; }



-(NSStringEncoding)nameEncoding { return parser.stringSource.encoding; }

-(void)setNameEncoding:(NSStringEncoding)encoding { parser.stringSource.fixedEncoding = encoding; }




@synthesize lastError = lasterror;

-(void)clearLastError { lasterror=XADErrorNone; }

-(NSString *)describeLastError { return [XADException describeXADError:lasterror]; }

-(NSString *)describeError:(XADError)error { return [XADException describeXADError:error]; }



-(NSString *)description
{
	return [NSString stringWithFormat:@"XADArchive: %@ (%@, %ld entries)",self.filename,self.formatName,(long)self.numberOfEntries];
}



-(NSDictionary *)dataForkParserDictionaryForEntry:(NSInteger)n
{
	id obj=dataentries[n];
	if(obj==[NSNull null]) return nil;
	else return obj;
}

-(NSDictionary *)resourceForkParserDictionaryForEntry:(NSInteger)n
{
	id obj=resourceentries[n];
	if(obj==[NSNull null]) return nil;
	else return obj;
}

-(NSDictionary *)combinedParserDictionaryForEntry:(NSInteger)n
{
	NSDictionary *data=dataentries[n];
	NSDictionary *resource=resourceentries[n];

	if((id)data==[NSNull null]) return resource;
	if((id)resource==[NSNull null]) return data;

	NSMutableDictionary *new=[NSMutableDictionary dictionaryWithDictionary:data];

	id obj;

	obj=resource[XADFileTypeKey];
	if(obj) new[XADFileTypeKey] = obj;
	obj=resource[XADFileCreatorKey];
	if(obj) new[XADFileCreatorKey] = obj;
	obj=resource[XADFinderFlagsKey];
	if(obj) new[XADFinderFlagsKey] = obj;
	obj=resource[XADFinderInfoKey];
	if(obj) new[XADFinderInfoKey] = obj;

	return new;
}

-(NSString *)nameOfEntry:(NSInteger)n
{
	NSDictionary *dict=[self dataForkParserDictionaryForEntry:n];
	if(!dict) dict=[self resourceForkParserDictionaryForEntry:n];

	XADPath *xadname=dict[XADFileNameKey];
	if(!xadname) return nil;

	if(!xadname.encodingIsKnown&&delegate)
	{
		NSStringEncoding encoding=[delegate archive:self encodingForData:xadname.data
		guess:xadname.encoding confidence:xadname.confidence];
		return [xadname sanitizedPathStringWithEncoding:encoding];
	}
	else
	{
		return xadname.sanitizedPathString;
	}
}

-(BOOL)entryHasSize:(NSInteger)n
{
	NSDictionary *dict=[self dataForkParserDictionaryForEntry:n];
	return dict[XADFileSizeKey]?YES:NO;
}

-(off_t)uncompressedSizeOfEntry:(NSInteger)n
{
	NSDictionary *dict=[self dataForkParserDictionaryForEntry:n];
	if(!dict) return 0; // Special case for resource forks without data forks
	NSNumber *size=dict[XADFileSizeKey];
	if(size == nil) return CSHandleMaxLength;
	return size.longLongValue;
}

-(off_t)compressedSizeOfEntry:(NSInteger)n
{
	NSDictionary *dict=[self dataForkParserDictionaryForEntry:n];
	if(!dict) return 0; // Special case for resource forks without data forks
	NSNumber *size=dict[XADCompressedSizeKey];
	if(size == nil) return CSHandleMaxLength;
	return size.longLongValue;
}

-(off_t)representativeSizeOfEntry:(NSInteger)n
{
	NSDictionary *dict=[self dataForkParserDictionaryForEntry:n];
	if(!dict) return 0; // Special case for resource forks without data forks
	NSNumber *size=dict[XADFileSizeKey];
	if(size == nil) size=dict[XADCompressedSizeKey];
	if(size == nil) return 1000;
	return size.longLongValue;
}

-(BOOL)entryIsDirectory:(NSInteger)n
{
	NSDictionary *dict=[self combinedParserDictionaryForEntry:n];
	NSNumber *isdir=dict[XADIsDirectoryKey];

	return isdir&&isdir.boolValue;
}

-(BOOL)entryIsLink:(NSInteger)n
{
	NSDictionary *dict=[self dataForkParserDictionaryForEntry:n];
	NSNumber *islink=dict[XADIsLinkKey];

	return islink&&islink.boolValue;
}

-(BOOL)entryIsEncrypted:(NSInteger)n
{
	NSDictionary *dict=[self dataForkParserDictionaryForEntry:n];
	NSNumber *isenc=dict[XADIsEncryptedKey];

	return isenc&&isenc.boolValue;
}

-(BOOL)entryIsArchive:(NSInteger)n
{
	NSDictionary *dict=[self dataForkParserDictionaryForEntry:n];
	NSNumber *isarc=dict[XADIsArchiveKey];

	return isarc&&isarc.boolValue;
}

-(BOOL)entryHasResourceFork:(NSInteger)n
{
	NSDictionary *resdict=[self resourceForkParserDictionaryForEntry:n];
	if(!resdict) return NO;
	NSNumber *num=resdict[XADFileSizeKey];
	if(num == nil) return NO;

	return num.intValue!=0;
}

-(NSString *)commentForEntry:(NSInteger)n
{
	NSDictionary *dict=[self dataForkParserDictionaryForEntry:n]; // TODO: combined or data?
	return dict[XADCommentKey];
}

-(NSDictionary *)attributesOfEntry:(NSInteger)n { return [self attributesOfEntry:n withResourceFork:NO]; }

-(NSDictionary *)attributesOfEntry:(NSInteger)n withResourceFork:(BOOL)resfork
{
	NSDictionary *dict=[self combinedParserDictionaryForEntry:n];
	NSMutableDictionary *attrs=[NSMutableDictionary dictionary];

	NSDate *creation=dict[XADCreationDateKey];
	NSDate *modification=dict[XADLastModificationDateKey];
	if(modification) attrs[NSFileModificationDate] = modification;
	if(creation) attrs[NSFileCreationDate] = creation;

	NSNumber *type=dict[XADFileTypeKey];
	if(type != nil) attrs[NSFileHFSTypeCode] = type;

	NSNumber *creator=dict[XADFileCreatorKey];
	if(creator != nil) attrs[NSFileHFSCreatorCode] = creator;

	NSNumber *flags=dict[XADFinderFlagsKey];
	if(flags != nil) attrs[XADFinderFlagsKey] = flags;

	NSNumber *perm=dict[XADPosixPermissionsKey];
	if(perm != nil) attrs[NSFilePosixPermissions] = perm;

	XADString *user=dict[XADPosixUserNameKey];
	if(user)
	{
		NSString *username=user.string;
		if(username) attrs[NSFileOwnerAccountName] = username;
	}

	XADString *group=dict[XADPosixGroupNameKey];
	if(group)
	{
		NSString *groupname=group.string;
		if(groupname) attrs[NSFileGroupOwnerAccountName] = groupname;
	}

	if(resfork)
	{
		NSDictionary *resdict=[self resourceForkParserDictionaryForEntry:n];
		if(resdict)
		{
			for(;;)
			{
				@try
				{
					CSHandle *handle=[parser handleForEntryWithDictionary:resdict wantChecksum:YES];
					if(!handle) [XADException raiseDecrunchException];
					NSData *forkdata=[handle remainingFileContents];
					if(handle.hasChecksum&&!handle.checksumCorrect) [XADException raiseChecksumException];

					attrs[XADResourceDataKey] = forkdata;
					break;
				}
				@catch(id e)
				{
					lasterror=[XADException parseException:e];
					XADAction action=[delegate archive:self extractionOfResourceForkForEntryDidFail:n error:lasterror];
					if(action==XADActionSkip) break;
					else if(action!=XADActionRetry) return nil;
				}
			}
		}
	}

	return [attrs copy];
}

-(CSHandle *)handleForEntry:(NSInteger)n
{
	return [self handleForEntry:n error:NULL];
}

-(CSHandle *)handleForEntry:(NSInteger)n error:(XADError *)error
{
	NSDictionary *dict=[self dataForkParserDictionaryForEntry:n];
	if(!dict) return [CSMemoryHandle memoryHandleForReadingData:[NSData data]]; // Special case for files with only a resource fork

	@try
	{ return [parser handleForEntryWithDictionary:dict wantChecksum:YES]; }
	@catch(id e)
	{
		lasterror=[XADException parseException:e];
		if(error) *error=lasterror;
	}
	return nil;
}

-(CSHandle *)resourceHandleForEntry:(NSInteger)n
{
	return [self resourceHandleForEntry:n error:NULL];
}

-(CSHandle *)resourceHandleForEntry:(NSInteger)n error:(XADError *)error
{
	NSDictionary *resdict=[self resourceForkParserDictionaryForEntry:n];
	if(!resdict) return nil;
	NSNumber *isdir=resdict[XADIsDirectoryKey];
	if(isdir&&isdir.boolValue) return nil;

	@try
	{ return [parser handleForEntryWithDictionary:resdict wantChecksum:YES]; }
	@catch(id e)
	{
		lasterror=[XADException parseException:e];
		if(error) *error=lasterror;
	}
	return nil;
}

-(NSData *)contentsOfEntry:(NSInteger)n
{
	NSDictionary *dict=[self dataForkParserDictionaryForEntry:n];
	if(!dict) return [NSData data]; // Special case for files with only a resource fork

	@try
	{
		CSHandle *handle=[parser handleForEntryWithDictionary:dict wantChecksum:YES];
		if(!handle) [XADException raiseDecrunchException];
		NSData *data=[handle remainingFileContents];
		if(handle.hasChecksum&&!handle.checksumCorrect) [XADException raiseChecksumException];

		return data;
	}
	@catch(id e)
	{
		lasterror=[XADException parseException:e];
	}
	return nil;
}




// Extraction functions

-(BOOL)extractTo:(NSString *)destination
{
	return [self extractEntries:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,self.numberOfEntries)] to:destination subArchives:NO];
}

-(BOOL)extractTo:(NSString *)destination subArchives:(BOOL)sub
{
	return [self extractEntries:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,self.numberOfEntries)] to:destination subArchives:sub];
}

-(BOOL)extractEntries:(NSIndexSet *)entryset to:(NSString *)destination
{
	return [self extractEntries:entryset to:destination subArchives:NO];
}

-(BOOL)extractEntries:(NSIndexSet *)entryset to:(NSString *)destination subArchives:(BOOL)sub
{
	extractsize=0;
	totalsize=0;

	for(NSUInteger i=entryset.firstIndex;i!=NSNotFound;i=[entryset indexGreaterThanIndex:i])
	totalsize+=[self representativeSizeOfEntry:i];

	NSInteger numentries=entryset.count;
	[delegate archive:self extractionProgressFiles:0 of:numentries];
	[delegate archive:self extractionProgressBytes:0 of:totalsize];

	for(NSUInteger i=entryset.firstIndex;i!=NSNotFound;i=[entryset indexGreaterThanIndex:i])
	{
		BOOL res;

		if(sub&&[self entryIsArchive:i])
		{
			@try { res=[self extractArchiveEntry:i to:destination]; }
			@catch(id e) { res=NO; }

			if(!res&&lasterror==XADErrorDataFormat) // Retry as regular file if the archive format was not known
			{
				res=[self extractEntry:i to:destination deferDirectories:YES];
			}
		}
		else res=[self extractEntry:i to:destination deferDirectories:YES];

		if(!res)
		{
			totalsize=0;
			return NO;
		}

		extractsize+=[self representativeSizeOfEntry:i];

		[delegate archive:self extractionProgressFiles:i+1 of:numentries];
		[delegate archive:self extractionProgressBytes:extractsize of:totalsize];
	}

	[self updateAttributesForDeferredDirectories];

	totalsize=0;
	return YES;
}

-(BOOL)extractEntry:(NSInteger)n to:(NSString *)destination
{ return [self extractEntry:n to:destination deferDirectories:NO dataFork:YES resourceFork:YES]; }

-(BOOL)extractEntry:(NSInteger)n to:(NSString *)destination deferDirectories:(BOOL)defer
{ return [self extractEntry:n to:destination deferDirectories:defer dataFork:YES resourceFork:YES]; }

-(BOOL)extractEntry:(NSInteger)n to:(NSString *)destination deferDirectories:(BOOL)defer
resourceFork:(BOOL)resfork
{ return [self extractEntry:n to:destination deferDirectories:defer dataFork:YES resourceFork:resfork]; }

-(BOOL)extractEntry:(NSInteger)n to:(NSString *)destination deferDirectories:(BOOL)defer
dataFork:(BOOL)datafork resourceFork:(BOOL)resfork
{
	if(datafork) [delegate archive:self extractionOfEntryWillStart:n];

	NSString *name;

	while(!(name=[self nameOfEntry:n]))
	{
		if(delegate)
		{
			XADAction action=[delegate archive:self nameDecodingDidFailForEntry:n
			data:[[self dataForkParserDictionaryForEntry:n][XADFileNameKey] data]];
			if(action==XADActionSkip) return YES;
			else if(action!=XADActionRetry)
			{
				lasterror=XADErrorBreak;
				return NO;
			}
		}
		else
		{
			lasterror=XADErrorEncoding;
			return NO;
		}
	}

	if(!name.length) return YES; // Silently ignore unnamed files (or more likely, directories).

	NSString *destfile=[destination stringByAppendingPathComponent:name];
	while(![self _extractEntry:n as:destfile deferDirectories:defer dataFork:datafork resourceFork:resfork])
	{
		if(lasterror==XADErrorBreak) return NO;
		else if(delegate&&datafork)
		{
			XADAction action=[delegate archive:self extractionOfEntryDidFail:n error:lasterror];

			if(action==XADActionSkip) return YES;
			else if(action!=XADActionRetry) return NO;
		}
		else return NO;
	}

	if(datafork) [delegate archive:self extractionOfEntryDidSucceed:n];

	return YES;
}

- (BOOL)extractContentsOfEntry:(NSInteger)n toPath:(NSString *)destination
{
	[delegate archive:self extractionOfEntryWillStart:n];

	while(![self _extractEntry:n as:destination deferDirectories:NO dataFork:YES resourceFork:YES])
	{
		if(lasterror==XADErrorBreak) return NO;
		else if(delegate)
		{
			XADAction action=[delegate archive:self extractionOfEntryDidFail:n error:lasterror];
			
			if(action==XADActionSkip) return YES;
			else if(action!=XADActionRetry) return NO;
		}
		else return NO;
	}

	[delegate archive:self extractionOfEntryDidSucceed:n];

	return YES;
}

-(BOOL)extractArchiveEntry:(NSInteger)n to:(NSString *)destination
{
	NSString *path=[destination stringByAppendingPathComponent:
	[self nameOfEntry:n].stringByDeletingLastPathComponent];

	for(;;)
	{
		XADError err;
		XADArchive *subarchive=[[XADArchive alloc] initWithArchive:self entry:n
		immediateExtractionTo:path subArchives:YES error:&err];

		if(!subarchive)
		{
			lasterror=err;
		}
		else
		{
			err=subarchive.lastError;
			if(err) lasterror=err;
		}

		BOOL res=subarchive&&!subarchive.immediateExtractionFailed;

		if(res) return YES;
		else if(err==XADErrorBreak||err==XADErrorDataFormat) return NO;
		else if(delegate)
		{
			XADAction action=[delegate archive:self extractionOfEntryDidFail:n error:err];

			if(action==XADActionSkip) return YES;
			else if(action!=XADActionRetry) return NO;
		}
		else return NO;
	}
}



-(BOOL)_extractEntry:(NSInteger)n as:(NSString *)destfile deferDirectories:(BOOL)defer
dataFork:(BOOL)datafork resourceFork:(BOOL)resfork
{
	for(;;)
	{
		XADError error=[unarchiver _ensureDirectoryExists:destfile.stringByDeletingLastPathComponent];

		if(error==XADErrorNone)
		{
			break;
		}
		else if(delegate)
		{
			XADAction action=[delegate archive:self creatingDirectoryDidFailForEntry:n];
			if(action==XADActionSkip) return YES;
			else if(action!=XADActionRetry)
			{
				lasterror=XADErrorBreak;
				return NO;
			}
		}
		else
		{
			lasterror=error;
			return NO;
		}
	}

	struct stat st;
	BOOL isdir=[self entryIsDirectory:n];

	if(delegate)
	while(lstat(destfile.fileSystemRepresentation,&st)==0)
	{
		BOOL dir=(st.st_mode&S_IFMT)==S_IFDIR;
		NSString *newname=nil;
		XADAction action;

		if(dir)
		{
			if(isdir) return YES;
			else action=[delegate archive:self entry:n collidesWithDirectory:destfile newFilename:&newname];
		}
		else action=[delegate archive:self entry:n collidesWithFile:destfile newFilename:&newname];

		if(action==XADActionOverwrite&&!dir) break;
		else if(action==XADActionSkip) return YES;
		else if(action==XADActionRename) destfile=[destfile.stringByDeletingLastPathComponent stringByAppendingPathComponent:newname];
		else if(action!=XADActionRetry)
		{
			lasterror=XADErrorBreak;
			return NO;
		}
	}

	NSDictionary *datadict=[self dataForkParserDictionaryForEntry:n];
	NSDictionary *resdict=[self resourceForkParserDictionaryForEntry:n];

	//extractEntryWithDictionary:(NSDictionary *)dict as:(NSString *)path forceDirectories:(BOOL)force

	if(datafork&&datadict)
	{
		extractingentry=n;
		extractingresource=NO;
		XADError error=[unarchiver extractEntryWithDictionary:datadict as:destfile forceDirectories:!defer];
		if(error) { lasterror=error; return NO; }
	}

	if(resfork&&resdict)
	{
		extractingentry=n;
		extractingresource=YES;
		XADError error=[unarchiver extractEntryWithDictionary:resdict as:destfile forceDirectories:!defer];
		if(error) { lasterror=error; return NO; }
	}

	return YES;
}

-(void)updateAttributesForDeferredDirectories
{
	[unarchiver finishExtractions];
}



-(BOOL)extractionShouldStopForUnarchiver:(XADUnarchiver *)unarchiver;
{
	return delegate&&[delegate archiveExtractionShouldStop:self];
}

-(void)unarchiver:(XADUnarchiver *)unarchiver extractionProgressForEntryWithDictionary:(NSDictionary *)dict
fileFraction:(double)fileprogress estimatedTotalFraction:(double)totalprogress
{
	if(extractingresource) return;

	off_t size=[self representativeSizeOfEntry:extractingentry];
	off_t progress=fileprogress*size;
	[delegate archive:self extractionProgressForEntry:extractingentry bytes:progress of:size];

	if(totalsize)
	{
		[delegate archive:self extractionProgressBytes:extractsize+progress of:totalsize];
	}
	else if(immediatedestination)
	{
		[delegate archive:self extractionProgressBytes:totalprogress*immediatesize of:immediatesize];
	}
}

-(NSString *)unarchiver:(XADUnarchiver *)unarchiver destinationForLink:(XADString *)link from:(NSString *)path
{
	NSString *linkstring;
	if(!link.encodingIsKnown&&delegate)
	{
		// TODO: should there be a better way to deal with encodings?
		NSStringEncoding encoding=[delegate archive:self encodingForData:link.data
		guess:link.encoding confidence:link.confidence];
		linkstring=[link stringWithEncoding:encoding];
	}
	else linkstring=link.string;

	return linkstring;
}

-(BOOL)unarchiver:(XADUnarchiver *)unarchiver shouldCreateDirectory:(NSString *)directory
{
	if(!delegate||[delegate archive:self shouldCreateDirectory:directory]) return YES;
	else return NO;
}





//
// Deprecated
//

-(int)sizeOfEntry:(int)n // deprecated and broken
{
	NSDictionary *dict=[self dataForkParserDictionaryForEntry:n];
	if(!dict) return 0; // Special case for resource forks without data forks
	NSNumber *size=dict[XADFileSizeKey];
	if(size == nil) return INT_MAX;
	return size.intValue;
}

// Ugly hack to support old versions of Xee.
-(void *)xadFileInfoForEntry:(int)n
{
	struct xadFileInfo
	{
		void *xfi_Next;
		uint32_t xfi_EntryNumber;/* number of entry */
		char *xfi_EntryInfo;  /* additional archiver text */
		void *xfi_PrivateInfo;/* client private, see XAD_OBJPRIVINFOSIZE */
		uint32_t xfi_Flags;      /* see XADFIF_xxx defines */
		char *xfi_FileName;   /* see XAD_OBJNAMESIZE tag */
		char *xfi_Comment;    /* see XAD_OBJCOMMENTSIZE tag */
		uint32_t xfi_Protection; /* AmigaOS3 bits (including multiuser) */
		uint32_t xfi_OwnerUID;   /* user ID */
		uint32_t xfi_OwnerGID;   /* group ID */
		char *xfi_UserName;   /* user name */
		char *xfi_GroupName;  /* group name */
		uint64_t xfi_Size;       /* size of this file */
		uint64_t xfi_GroupCrSize;/* crunched size of group */
		uint64_t xfi_CrunchSize; /* crunched size */
		char *xfi_LinkName;   /* name and path of link */
		struct xadDate {
			uint32_t xd_Micros;  /* values 0 to 999999     */
			int32_t xd_Year;    /* values 1 to 2147483648 */
			uint8_t xd_Month;   /* values 1 to 12         */
			uint8_t xd_WeekDay; /* values 1 to 7          */
			uint8_t xd_Day;     /* values 1 to 31         */
			uint8_t xd_Hour;    /* values 0 to 23         */
			uint8_t xd_Minute;  /* values 0 to 59         */
			uint8_t xd_Second;  /* values 0 to 59         */
		} xfi_Date;
		uint16_t xfi_Generation; /* File Generation [0...0xFFFF] (V3) */
		uint64_t xfi_DataPos;    /* crunched data position (V3) */
		void *xfi_MacFork;    /* pointer to 2nd fork for Mac (V7) */
		uint16_t xfi_UnixProtect;/* protection bits for Unix (V11) */
		uint8_t xfi_DosProtect; /* protection bits for MS-DOS (V11) */
		uint8_t xfi_FileType;   /* XADFILETYPE to define type of exe files (V11) */
		void *xfi_Special;    /* pointer to special data (V11) */
	};

	NSDictionary *dict=[self combinedParserDictionaryForEntry:n];
	NSDate *mod=dict[XADLastModificationDateKey];
	NSNumber *size=dict[XADFileSizeKey];

	NSMutableData *data=[NSMutableData dataWithLength:sizeof(struct xadFileInfo)];
	struct xadFileInfo *fi=data.mutableBytes;

	if(mod)
	{
		NSDateComponents* cal = [[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian] componentsInTimeZone:[NSTimeZone defaultTimeZone] fromDate:mod];
		fi->xfi_Date.xd_Year=(int)cal.year;
		fi->xfi_Date.xd_Month=cal.month;
		fi->xfi_Date.xd_Day=cal.day;
		fi->xfi_Date.xd_Hour=cal.hour;
		fi->xfi_Date.xd_Minute=cal.minute;
		fi->xfi_Date.xd_Second=cal.second;
	}
	else fi->xfi_Flags|=1<<6;

	if(size != nil) fi->xfi_Size=size.longLongValue;
	else fi->xfi_Size=0;

	return fi;
}

-(BOOL)extractEntry:(int)n to:(NSString *)destination overrideWritePermissions:(BOOL)override
{ return [self extractEntry:n to:destination deferDirectories:override resourceFork:YES]; }

-(BOOL)extractEntry:(int)n to:(NSString *)destination overrideWritePermissions:(BOOL)override resourceFork:(BOOL)resfork
{ return [self extractEntry:n to:destination deferDirectories:override resourceFork:resfork]; }

-(void)fixWritePermissions { [self updateAttributesForDeferredDirectories]; }





-(NSStringEncoding)archive:(XADArchive *)archive encodingForData:(NSData *)data guess:(NSStringEncoding)guess confidence:(float)confidence
{ return [delegate archive:archive encodingForData:data guess:guess confidence:confidence]; }

-(XADAction)archive:(XADArchive *)archive nameDecodingDidFailForEntry:(NSInteger)n data:(NSData *)data
{ return [delegate archive:archive nameDecodingDidFailForEntry:n data:data]; }

-(BOOL)archiveExtractionShouldStop:(XADArchive *)arc
{ return [delegate archiveExtractionShouldStop:arc]; }

-(BOOL)archive:(XADArchive *)arc shouldCreateDirectory:(NSString *)directory
{ return [delegate archive:arc shouldCreateDirectory:directory]; }

-(XADAction)archive:(XADArchive *)arc entry:(NSInteger)n collidesWithFile:(NSString *)file newFilename:(NSString **)newname
{ return [delegate archive:arc entry:n collidesWithFile:file newFilename:newname]; }

-(XADAction)archive:(XADArchive *)arc entry:(NSInteger)n collidesWithDirectory:(NSString *)file newFilename:(NSString **)newname
{ return [delegate archive:arc entry:n collidesWithDirectory:file newFilename:newname]; }

-(XADAction)archive:(XADArchive *)arc creatingDirectoryDidFailForEntry:(NSInteger)n
{ return [delegate archive:arc creatingDirectoryDidFailForEntry:n]; }

-(void)archiveNeedsPassword:(XADArchive *)arc
{
	if ([delegate respondsToSelector:@selector(archiveNeedsPassword:)]) {
		[delegate archiveNeedsPassword:arc];
	}
}

-(void)archive:(XADArchive *)arc extractionOfEntryWillStart:(NSInteger)n
{ [delegate archive:arc extractionOfEntryWillStart:n]; }

-(void)archive:(XADArchive *)arc extractionProgressForEntry:(NSInteger)n bytes:(off_t)bytes of:(off_t)total
{ [delegate archive:arc extractionProgressForEntry:n bytes:bytes of:total]; }

-(void)archive:(XADArchive *)arc extractionOfEntryDidSucceed:(NSInteger)n
{ [delegate archive:arc extractionOfEntryDidSucceed:n]; }

-(XADAction)archive:(XADArchive *)arc extractionOfEntryDidFail:(NSInteger)n error:(XADError)error
{ return [delegate archive:arc extractionOfEntryDidFail:n error:error]; }

-(XADAction)archive:(XADArchive *)arc extractionOfResourceForkForEntryDidFail:(NSInteger)n error:(XADError)error
{ return [delegate archive:arc extractionOfResourceForkForEntryDidFail:n error:error]; }

-(void)archive:(XADArchive *)arc extractionProgressBytes:(off_t)bytes of:(off_t)total
{ [delegate archive:arc extractionProgressBytes:bytes of:total]; }

//-(void)archive:(XADArchive *)arc extractionProgressFiles:(int)files of:(int)total;
//{}

# pragma mark - NSError functions

-(CSHandle *)resourceHandleForEntry:(NSInteger)n nserror:(NSError *_Nullable __autoreleasing *_Nullable)error
{
	NSDictionary *resdict=[self resourceForkParserDictionaryForEntry:n];
	if(!resdict) return nil;
	NSNumber *isdir=resdict[XADIsDirectoryKey];
	if(isdir&&isdir.boolValue) return nil;
	
	@try
	{ return [parser handleForEntryWithDictionary:resdict wantChecksum:YES]; }
	@catch(id e)
	{
		lasterror=[XADException parseException:e];
		if(error) *error=[XADException parseExceptionReturningNSError:e];
	}
	return nil;
}

-(CSHandle *)handleForEntry:(NSInteger)n nserror:(NSError *_Nullable __autoreleasing *_Nullable)error
{
	NSDictionary *dict=[self dataForkParserDictionaryForEntry:n];
	if(!dict) return [CSMemoryHandle memoryHandleForReadingData:[NSData data]]; // Special case for files with only a resource fork
	
	@try
	{ return [parser handleForEntryWithDictionary:dict wantChecksum:YES]; }
	@catch(id e)
	{
		lasterror=[XADException parseException:e];
		if(error) *error=[XADException parseExceptionReturningNSError:e];
	}
	return nil;
}

-(instancetype)initWithFile:(NSString *)file nserror:(NSError *_Nullable __autoreleasing *_Nullable)error { return [self initWithFile:file delegate:nil nserror:error]; }

-(instancetype)initWithFile:(NSString *)file delegate:(id)del nserror:(NSError *_Nullable __autoreleasing *_Nullable)error
{
	if((self=[self init]))
	{
		delegate=del;
		
		parser=[XADArchiveParser archiveParserForPath:file nserror:error];
		if(parser)
		{
			XADError tmpErr = 0;
			if([self _parseWithErrorPointer:&tmpErr]) return self;
			if(error) *error=[NSError errorWithDomain:XADErrorDomain code:tmpErr userInfo:nil];
		}
		else if(error) *error=[NSError errorWithDomain:XADErrorDomain code:XADErrorDataFormat userInfo:nil];
	}
	
	return nil;
}



-(instancetype)initWithData:(NSData *)data nserror:(NSError *_Nullable __autoreleasing *_Nullable)error { return [self initWithData:data delegate:nil nserror:error]; }

-(instancetype)initWithData:(NSData *)data delegate:(id)del nserror:(NSError *_Nullable __autoreleasing *_Nullable)error
{
	if((self=[self init]))
	{
		delegate=del;
		
		parser=[XADArchiveParser archiveParserForHandle:[CSMemoryHandle memoryHandleForReadingData:data] name:@""];
		if(parser)
		{
			XADError tmpErr = XADErrorNone;
			if([self _parseWithErrorPointer:&tmpErr]) return self;
			if (error) {
				*error = [NSError errorWithDomain:XADErrorDomain code:tmpErr userInfo:nil];
			}
		}
		else if(error) *error=[NSError errorWithDomain:XADErrorDomain code:XADErrorDataFormat userInfo:nil];
	}
	return nil;
}

-(instancetype)initWithArchive:(XADArchive *)otherarchive entry:(NSInteger)n
		 immediateExtractionTo:(NSString *)destination nserror:(NSError *_Nullable __autoreleasing *_Nullable)error
{
	return [self initWithArchive:otherarchive entry:n immediateExtractionTo:destination
					 subArchives:NO nserror:error];
}

@end

@interface NSObject (XADArchiveDelegateInformal)

-(NSStringEncoding)archive:(XADArchive *)archive encodingForData:(NSData *)data guess:(NSStringEncoding)guess confidence:(float)confidence;
-(XADAction)archive:(XADArchive *)archive nameDecodingDidFailForEntry:(NSInteger)n data:(NSData *)data;

-(BOOL)archiveExtractionShouldStop:(XADArchive *)archive;
-(BOOL)archive:(XADArchive *)archive shouldCreateDirectory:(NSString *)directory;
-(XADAction)archive:(XADArchive *)archive entry:(NSInteger)n collidesWithFile:(NSString *)file newFilename:(NSString **)newname;
-(XADAction)archive:(XADArchive *)archive entry:(NSInteger)n collidesWithDirectory:(NSString *)file newFilename:(NSString **)newname;
-(XADAction)archive:(XADArchive *)archive creatingDirectoryDidFailForEntry:(NSInteger)n;

-(void)archive:(XADArchive *)archive extractionOfEntryWillStart:(NSInteger)n;
-(void)archive:(XADArchive *)archive extractionProgressForEntry:(NSInteger)n bytes:(off_t)bytes of:(off_t)total;
-(void)archive:(XADArchive *)archive extractionOfEntryDidSucceed:(NSInteger)n;
-(XADAction)archive:(XADArchive *)archive extractionOfEntryDidFail:(NSInteger)n error:(XADError)error;
-(XADAction)archive:(XADArchive *)archive extractionOfResourceForkForEntryDidFail:(NSInteger)n error:(XADError)error;

-(void)archive:(XADArchive *)archive extractionProgressBytes:(off_t)bytes of:(off_t)total;

-(void)archive:(XADArchive *)archive extractionProgressFiles:(NSInteger)files of:(NSInteger)total;

// Deprecated
-(NSStringEncoding)archive:(XADArchive *)archive encodingForName:(const char *)bytes guess:(NSStringEncoding)guess confidence:(float)confidence DEPRECATED_ATTRIBUTE;
-(XADAction)archive:(XADArchive *)archive nameDecodingDidFailForEntry:(NSInteger)n bytes:(const char *)bytes DEPRECATED_ATTRIBUTE;

@end


@implementation NSObject (XADArchiveDelegateInformal)

-(NSStringEncoding)archive:(XADArchive *)archive encodingForData:(NSData *)data guess:(NSStringEncoding)guess confidence:(float)confidence
{
	// Default implementation calls old method
	NSMutableData *terminateddata=[[NSMutableData alloc] initWithData:data];
	[terminateddata increaseLengthBy:1]; // append a 0 byte
	NSStringEncoding enc=[self archive:archive encodingForName:terminateddata.bytes guess:guess confidence:confidence];
	return enc;
}

-(XADAction)archive:(XADArchive *)archive nameDecodingDidFailForEntry:(NSInteger)n data:(NSData *)data
{
	// Default implementation calls old method
	NSMutableData *terminateddata=[[NSMutableData alloc] initWithData:data];
	XADAction action=[self archive:archive nameDecodingDidFailForEntry:n bytes:terminateddata.bytes];
	return action;
}

-(BOOL)archiveExtractionShouldStop:(XADArchive *)archive { return NO; }
-(BOOL)archive:(XADArchive *)archive shouldCreateDirectory:(NSString *)directory { return YES; }
-(XADAction)archive:(XADArchive *)archive entry:(NSInteger)n collidesWithFile:(NSString *)file newFilename:(NSString **)newname { return XADActionOverwrite; }
-(XADAction)archive:(XADArchive *)archive entry:(NSInteger)n collidesWithDirectory:(NSString *)file newFilename:(NSString **)newname { return XADActionSkip; }
-(XADAction)archive:(XADArchive *)archive creatingDirectoryDidFailForEntry:(NSInteger)n { return XADActionAbort; }

-(void)archive:(XADArchive *)archive extractionOfEntryWillStart:(NSInteger)n {}
-(void)archive:(XADArchive *)archive extractionProgressForEntry:(NSInteger)n bytes:(off_t)bytes of:(off_t)total {}
-(void)archive:(XADArchive *)archive extractionOfEntryDidSucceed:(NSInteger)n {}
-(XADAction)archive:(XADArchive *)archive extractionOfEntryDidFail:(NSInteger)n error:(XADError)error { return XADActionAbort; }
-(XADAction)archive:(XADArchive *)archive extractionOfResourceForkForEntryDidFail:(NSInteger)n error:(XADError)error { return XADActionAbort; }

-(void)archive:(XADArchive *)archive extractionProgressBytes:(off_t)bytes of:(off_t)total {}
-(void)archive:(XADArchive *)archive extractionProgressFiles:(NSInteger)files of:(NSInteger)total {}

// Deprecated
-(NSStringEncoding)archive:(XADArchive *)archive encodingForName:(const char *)bytes guess:(NSStringEncoding)guess confidence:(float)confidence { return guess; }
-(XADAction)archive:(XADArchive *)archive nameDecodingDidFailForEntry:(NSInteger)n bytes:(const char *)bytes { return XADActionAbort; }

@end


