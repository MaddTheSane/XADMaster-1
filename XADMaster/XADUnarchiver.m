#import "XADUnarchiver.h"
#import "XADPlatform.h"
#import "XADAppleDouble.h"
#import "CSFileHandle.h"
#import "Progress.h"

#if !__has_feature(objc_arc)
#error this file needs to be compiled with Automatic Reference Counting (ARC)
#endif

@implementation XADUnarchiver
@synthesize delegate;
@synthesize destination;
@synthesize macResourceForkStyle = forkstyle;
@synthesize updateInterval = updateinterval;
@synthesize preservesPermissions = preservepermissions;
@synthesize archiveParser = parser;

+(XADUnarchiver *)unarchiverForArchiveParser:(XADArchiveParser *)archiveparser
{
	return [[self alloc] initWithArchiveParser:archiveparser];
}

+(XADUnarchiver *)unarchiverForPath:(NSString *)path
{
	return [self unarchiverForPath:path error:NULL];
}

+(XADUnarchiver *)unarchiverForPath:(NSString *)path error:(XADError *)errorptr
{
	XADArchiveParser *archiveparser=[XADArchiveParser archiveParserForPath:path error:errorptr];
	if(!archiveparser) return nil;
	return [[self alloc] initWithArchiveParser:archiveparser];
}

+(XADUnarchiver *)unarchiverForPath:(NSString *)path nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr
{
	XADArchiveParser *archiveparser=[XADArchiveParser archiveParserForPath:path nserror:errorptr];
	if(!archiveparser) return nil;
	return [[self alloc] initWithArchiveParser:archiveparser];
}

-(instancetype)initWithArchiveParser:(XADArchiveParser *)archiveparser
{
	if((self=[super init]))
	{
		parser=archiveparser;
		destination=nil;
		forkstyle=XADForkStyleDefault;
		preservepermissions=NO;
		updateinterval=0.1;
		delegate=nil;
		shouldstop=NO;

		deferreddirectories=[NSMutableArray new];
		deferredlinks=[NSMutableArray new];
	}
	return self;
}

-(XADError)parseAndUnarchive
{
	id olddelegate=parser.delegate;

	parser.delegate = self;
	XADError error=[parser parseWithoutExceptions];
	parser.delegate = olddelegate;
	if(error) return error;

	if(self._shouldStop) return XADErrorBreak;

	error=[self finishExtractions];
	if(error) return error;

	error=[parser testChecksumWithoutExceptions];
	if(error) return error;

	return XADErrorNone;
}

-(void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary *)dict
{
	//if([self _shouldStop]) return; // Unnecessary - XADArchiveParser handles it.
	[self extractEntryWithDictionary:dict];
}

-(BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser
{
	return self._shouldStop;
}

-(void)archiveParserNeedsPassword:(XADArchiveParser *)parser
{
	[delegate unarchiverNeedsPassword:self];
}

-(void)archiveParser:(XADArchiveParser *)parser findsFileInterestingForReason:(NSString *)reason
{
	[delegate unarchiver:self findsFileInterestingForReason:reason];
}




-(XADError)extractEntryWithDictionary:(NSDictionary *)dict
{
	return [self extractEntryWithDictionary:dict as:nil forceDirectories:NO];
}

-(XADError)extractEntryWithDictionary:(NSDictionary *)dict forceDirectories:(BOOL)force
{
	return [self extractEntryWithDictionary:dict as:nil forceDirectories:force];
}

-(XADError)extractEntryWithDictionary:(NSDictionary *)dict as:(NSString *)path
{
	return [self extractEntryWithDictionary:dict as:path forceDirectories:NO];
}

-(XADError)extractEntryWithDictionary:(NSDictionary *)dict as:(NSString *)path forceDirectories:(BOOL)force
{
	@autoreleasepool {

	NSNumber *dirnum=dict[XADIsDirectoryKey];
	NSNumber *linknum=dict[XADIsLinkKey];
	NSNumber *resnum=dict[XADIsResourceForkKey];
	NSNumber *archivenum=dict[XADIsArchiveKey];
	BOOL isdir=dirnum&&dirnum.boolValue;
	BOOL islink=linknum&&linknum.boolValue;
	BOOL isres=resnum&&resnum.boolValue;
	BOOL isarchive=archivenum&&archivenum.boolValue;

	// If we were not given a path, pick one ourselves.
	if(!path)
	{
		XADPath *name=dict[XADFileNameKey];
		NSString *namestring=name.sanitizedPathString;

		if(destination) path=[destination stringByAppendingPathComponent:namestring];
		else path=namestring;

		// Adjust path for resource forks.
		path=[self adjustPathString:path forEntryWithDictionary:dict];
	}

	// Ask for permission and possibly a path, and report that we are starting.
	if(delegate)
	{
		if(![delegate unarchiver:self shouldExtractEntryWithDictionary:dict suggestedPath:&path])
		{
			return XADErrorNone;
		}
		[delegate unarchiver:self willExtractEntryWithDictionary:dict to:path];
	}

	XADError error;
	
	error=[self _ensureDirectoryExists:path.stringByDeletingLastPathComponent];
	if(error) goto end;

	// Attempt to extract embedded archives if requested.
	if(isarchive&&delegate)
	{
		NSString *unarchiverpath=path.stringByDeletingLastPathComponent;

		if([delegate unarchiver:self shouldExtractArchiveEntryWithDictionary:dict to:unarchiverpath])
		{
			error=[self _extractArchiveEntryWithDictionary:dict to:unarchiverpath name:path.lastPathComponent];
			// If extraction was attempted, and succeeded for failed, skip everything else.
			// Otherwise, if the archive couldn't be opened, fall through and extract normally.
			if(error!=XADErrorSubArchive) goto end;
		}
	}

	// Extract normally.
	if(isres)
	{
		switch(forkstyle)
		{
			case XADForkStyleIgnored:
			break;

			case XADForkStyleMacOSX:
				if(!isdir)
				error=[XADPlatform extractResourceForkEntryWithDictionary:dict unarchiver:self toPath:path];
			break;

			case XADForkStyleHiddenAppleDouble:
			case XADForkStyleVisibleAppleDouble:
				error=[self _extractResourceForkEntryWithDictionary:dict asAppleDoubleFile:path];
			break;

			case XADForkStyleHFVExplorerAppleDouble:
				// We need to make sure there is an empty file for the data fork in all
				// cases, so just try to recover the original filename and create an empty
				// file there in case one doesn't exist, and this isn't a directory.
				// Kludge in the same file attributes as the resource fork. If there is
				// an actual data fork later, it will overwrite this file. There special-case
				// code to avoid collision warnings.
				if(![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:NULL] && !isdir)
				{
					NSString *dirpart=path.stringByDeletingLastPathComponent;
					NSString *namepart=path.lastPathComponent;
					if([namepart hasPrefix:@"%"])
					{
						NSString *originalname=[namepart substringFromIndex:1];
						NSString *datapath=[dirpart stringByAppendingPathComponent:originalname];
						[[NSData data] writeToFile:datapath atomically:NO];
						[self _updateFileAttributesAtPath:datapath forEntryWithDictionary:dict deferDirectories:!force];
					}
				}
				error=[self _extractResourceForkEntryWithDictionary:dict asAppleDoubleFile:path];
			break;

			default:
				// TODO: better error
				error=XADErrorBadParameters;
			break;
		}
	}
	else if(isdir)
	{
		error=[self _extractDirectoryEntryWithDictionary:dict as:path];
	}
	else if(islink)
	{
		error=[self _extractLinkEntryWithDictionary:dict as:path];
	}
	else
	{
		error=[self _extractFileEntryWithDictionary:dict as:path];
	}

	if(!error)
	{
		error=[self _updateFileAttributesAtPath:path forEntryWithDictionary:dict deferDirectories:!force];
	}

	// Report success or failure
	end:
	if(delegate && [delegate respondsToSelector:@selector(unarchiver:didExtractEntryWithDictionary:to:error:)])
	{
		[delegate unarchiver:self didExtractEntryWithDictionary:dict to:path error:error];
	}

	return error;
	}
}




static NSComparisonResult SortDirectoriesByDepthAndResource(id entry1,id entry2,void *context)
{
	NSDictionary *dict1=entry1[1];
	NSDictionary *dict2=entry2[1];

	XADPath *path1=dict1[XADFileNameKey];
	XADPath *path2=dict2[XADFileNameKey];
	NSInteger depth1=path1.depth;
	NSInteger depth2=path2.depth;
	if(depth1>depth2) return NSOrderedAscending;
	else if(depth1<depth2) return NSOrderedDescending;

	NSNumber *resnum1=dict1[XADIsResourceForkKey];
	NSNumber *resnum2=dict2[XADIsResourceForkKey];
	BOOL isres1=resnum1&&resnum1.boolValue;
	BOOL isres2=resnum2&&resnum2.boolValue;
	if(!isres1&&isres2) return NSOrderedAscending;
	else if(isres1&&!isres2) return NSOrderedDescending;

	return NSOrderedSame;
}

-(XADError)finishExtractions
{
	XADError error;

	error=[self _fixDeferredLinks];
	if(error) return error;

	error=[self _fixDeferredDirectories];
	if(error) return error;

	return XADErrorNone;
}

-(XADError)_fixDeferredLinks
{
	NSEnumerator *enumerator=[deferredlinks objectEnumerator];
	NSArray *entry;
	while((entry=[enumerator nextObject]))
	{
		NSString *path=entry[0];
		NSString *linkdest=entry[1];
		NSDictionary *dict=entry[2];

		XADError error;

		error=[XADPlatform createLinkAtPath:path withDestinationPath:linkdest];
		if(error) return error;

		error=[self _updateFileAttributesAtPath:path forEntryWithDictionary:dict deferDirectories:NO];
		if(error) return error;
	}

	[deferredlinks removeAllObjects];

	return XADErrorNone;
}

-(XADError)_fixDeferredDirectories
{
	[deferreddirectories sortUsingFunction:SortDirectoriesByDepthAndResource context:NULL];

	NSEnumerator *enumerator=[deferreddirectories objectEnumerator];
	NSArray *entry;
	while((entry=[enumerator nextObject]))
	{
		NSString *path=entry[0];
		NSDictionary *dict=entry[1];

		XADError error=[self _updateFileAttributesAtPath:path forEntryWithDictionary:dict deferDirectories:NO];
		if(error) return error;
	}

	[deferreddirectories removeAllObjects];

	return XADErrorNone;
}



-(XADUnarchiver *)unarchiverForEntryWithDictionary:(NSDictionary *)dict
wantChecksum:(BOOL)checksum nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr
{
	return [self unarchiverForEntryWithDictionary:dict resourceForkDictionary:nil
	wantChecksum:checksum nserror:errorptr];
}

-(XADUnarchiver *)unarchiverForEntryWithDictionary:(NSDictionary *)dict
wantChecksum:(BOOL)checksum error:(XADError *)errorptr
{
	return [self unarchiverForEntryWithDictionary:dict resourceForkDictionary:nil
									 wantChecksum:checksum error:errorptr];
}

-(XADUnarchiver *)unarchiverForEntryWithDictionary:(NSDictionary *)dict
resourceForkDictionary:(NSDictionary *)forkdict wantChecksum:(BOOL)checksum error:(XADError*)errorptr
{
	XADArchiveParser *subparser=[XADArchiveParser
	archiveParserForEntryWithDictionary:dict
	resourceForkDictionary:forkdict
	archiveParser:parser wantChecksum:checksum error:errorptr];
	if(!subparser) return nil;

	XADUnarchiver *subunarchiver=[XADUnarchiver unarchiverForArchiveParser:subparser];
	subunarchiver.delegate = delegate;
	subunarchiver.destination = destination;
	subunarchiver.macResourceForkStyle = forkstyle;
	subunarchiver.preservesPermissions = preservepermissions;
	subunarchiver.updateInterval = updateinterval;

	return subunarchiver;
}

-(XADUnarchiver *)unarchiverForEntryWithDictionary:(NSDictionary *)dict
							resourceForkDictionary:(NSDictionary *)forkdict wantChecksum:(BOOL)checksum nserror:(NSError *_Nullable __autoreleasing *_Nullable)errorptr
{
	XADArchiveParser *subparser=[XADArchiveParser
								 archiveParserForEntryWithDictionary:dict
								 resourceForkDictionary:forkdict
								 archiveParser:parser wantChecksum:checksum nserror:errorptr];
	if(!subparser) return nil;
	
	XADUnarchiver *subunarchiver=[XADUnarchiver unarchiverForArchiveParser:subparser];
	subunarchiver.delegate = delegate;
	subunarchiver.destination = destination;
	subunarchiver.macResourceForkStyle = forkstyle;
	subunarchiver.preservesPermissions = preservepermissions;
	subunarchiver.updateInterval = updateinterval;
	
	return subunarchiver;
}



-(XADError)_extractFileEntryWithDictionary:(NSDictionary *)dict as:(NSString *)destpath
{
	CSHandle *fh;
	@try { fh=[CSFileHandle fileHandleForWritingAtPath:destpath]; }
	@catch(id e) { return XADErrorOpenFile; }

	XADError err=[self runExtractorWithDictionary:dict outputHandle:fh];

	[fh close];

	return err;
}

-(XADError)_extractDirectoryEntryWithDictionary:(NSDictionary *)dict as:(NSString *)destpath
{
	return [self _ensureDirectoryExists:destpath];
}

-(XADError)_extractLinkEntryWithDictionary:(NSDictionary *)dict as:(NSString *)destpath
{
	XADError error;
	XADString *link=[parser linkDestinationForDictionary:dict error:&error];
	if(!link) return error;

	NSString *linkdest=nil;
	if(delegate) linkdest=[delegate unarchiver:self destinationForLink:link from:destpath];
	if(!linkdest) return XADErrorNone; // Handle nil returns as a request to skip.

	// Check if the link destination is an absolute path, or if it contains
	// any .. path components.
	if([linkdest hasPrefix:@"/"] || [linkdest isEqual:@".."] ||
	[linkdest hasPrefix:@"../"] || [linkdest hasSuffix:@"/.."] ||
	[linkdest rangeOfString:@"/../"].location!=NSNotFound)
	{
		// If so, consider it unsafe, and create a placeholder file instead,
		// and create the real link only in finishExtractions.
		CSHandle *fh;
		@try { fh=[CSFileHandle fileHandleForWritingAtPath:destpath]; }
		@catch(id e)
		{
			unlink(destpath.fileSystemRepresentation);
			@try { fh=[CSFileHandle fileHandleForWritingAtPath:destpath]; }
			@catch(id e) { return XADErrorOpenFile; }
		}
		[fh close];

		[deferredlinks addObject:@[destpath,linkdest,dict]];
		return XADErrorNone;
	}
	else
	{
		return [XADPlatform createLinkAtPath:destpath withDestinationPath:linkdest];
	}
}

-(XADError)_extractArchiveEntryWithDictionary:(NSDictionary *)dict to:(NSString *)destpath name:(NSString *)filename
{
	XADError error;
	XADUnarchiver *subunarchiver=[self unarchiverForEntryWithDictionary:dict
	wantChecksum:YES error:&error];
	if(!subunarchiver)
	{
		if(error) return error;
		else return XADErrorSubArchive;
	}

	subunarchiver.destination = destpath;

	[delegate unarchiver:self willExtractArchiveEntryWithDictionary:dict
	withUnarchiver:subunarchiver to:destpath];

	error=[subunarchiver parseAndUnarchive];

	[delegate unarchiver:self didExtractArchiveEntryWithDictionary:dict
	withUnarchiver:subunarchiver to:destpath error:error];

	return error;
}


-(XADError)_extractResourceForkEntryWithDictionary:(NSDictionary *)dict asAppleDoubleFile:(NSString *)destpath
{
	CSHandle *fh;
	@try { fh=[CSFileHandle fileHandleForWritingAtPath:destpath]; }
	@catch(id e) { return XADErrorOpenFile; }

	off_t ressize=0;
	NSNumber *sizenum=dict[XADFileSizeKey];
	if(sizenum!=nil) ressize=sizenum.longLongValue;

	NSDictionary *extattrs=[parser extendedAttributesForDictionary:dict];

	@try
	{
		// TODO: Should this function handle exceptions itself?
		[XADAppleDouble writeAppleDoubleHeaderToHandle:fh resourceForkSize:(int)ressize
		extendedAttributes:extattrs];
	}
	@catch(id e) { return [XADException parseException:e]; }

	// Write resource fork.
	XADError error=XADErrorNone;
	if(ressize) error=[self runExtractorWithDictionary:dict outputHandle:fh];

	[fh close];

	return error;
}



-(XADError)_updateFileAttributesAtPath:(NSString *)path forEntryWithDictionary:(NSDictionary *)dict
deferDirectories:(BOOL)defer
{
	if(defer)
	{
		NSNumber *dirnum=dict[XADIsDirectoryKey];
		if(dirnum&&dirnum.boolValue)
		{
			[deferreddirectories addObject:@[path,dict]];
			return XADErrorNone;
		}
	}

	return [XADPlatform updateFileAttributesAtPath:path forEntryWithDictionary:dict
	parser:parser preservePermissions:preservepermissions];
}

-(XADError)_ensureDirectoryExists:(NSString *)path
{
	if(path.length==0) return XADErrorNone;

	NSFileManager *manager=[NSFileManager defaultManager];

	BOOL isdir;
	if([manager fileExistsAtPath:path isDirectory:&isdir])
	{
		if(isdir) return XADErrorNone;

		if(!delegate) return XADErrorMakeDirectory;
		if(![delegate unarchiver:self shouldDeleteFileAndCreateDirectory:path]) return XADErrorMakeDirectory;
		if(![XADPlatform removeItemAtPath:path]) return XADErrorMakeDirectory;
	}
	else
	{
		XADError error=[self _ensureDirectoryExists:path.stringByDeletingLastPathComponent];
		if(error) return error;

		if(delegate)
		{
			if(![delegate unarchiver:self shouldCreateDirectory:path]) return XADErrorMakeDirectory;
		}
	}

	if([manager createDirectoryAtPath:path
	withIntermediateDirectories:NO attributes:nil error:NULL]) return XADErrorNone;
	else return XADErrorMakeDirectory;
}



-(XADError)runExtractorWithDictionary:(NSDictionary *)dict outputHandle:(CSHandle *)handle
{
	return [self runExtractorWithDictionary:dict outputTarget:self
	selector:@selector(_outputToHandle:bytes:length:) argument:handle];
}

-(XADError)_outputToHandle:(CSHandle *)handle bytes:(uint8_t *)bytes length:(NSInteger)length
{
	// TODO: combine the exception parsing for input and output
	@try { [handle writeBytes:length fromBuffer:bytes]; }
	@catch(id e) { return XADErrorOutput; }
	return XADErrorNone;
}

-(XADError)runExtractorWithDictionary:(NSDictionary *)dict
outputTarget:(id)target selector:(SEL)selector argument:(id)argument
{
	XADError (*outputfunc)(id,SEL,id,uint8_t *,NSInteger);
	outputfunc=(void *)[target methodForSelector:selector];

	uint8_t *buf=NULL;

	@try
	{
		// Send a progress report to show that we are starting.
		[delegate unarchiver:self extractionProgressForEntryWithDictionary:dict
		fileFraction:0 estimatedTotalFraction:parser.handle.estimatedProgress];

		// Try to find the size of this entry.
		NSNumber *sizenum=dict[XADFileSizeKey];
		off_t size=0;
		if(sizenum != nil)
		{
			size=sizenum.longLongValue;

			// If this file is empty, don't bother reading anything, just
			// call the output function once with 0 bytes and return.
			if(size==0) return outputfunc(target,selector,argument,(uint8_t *)"",0);
		}

		// Create handle and start unpacking.
		CSHandle *srchandle=[parser handleForEntryWithDictionary:dict wantChecksum:YES];
		if(!srchandle) return XADErrorNotSupported;

		off_t done=0;
		double updatetime=0;

		const int bufsize=0x40000;
		buf=malloc(bufsize);
		if(!buf) [XADException raiseOutOfMemoryException];

		for(;;)
		{
			if(self._shouldStop) return XADErrorBreak;

			// Read some data, and send it to the output function.
			// Stop if no more data was available.
			NSInteger actual=[srchandle readAtMost:bufsize toBuffer:buf];
			if(actual)
			{
				XADError error=outputfunc(target,selector,argument,buf,actual);
				if(error) return error;
			}
			else break;

			done+=actual;

			// Occasionally, send a progress message.
			double currtime=[XADPlatform currentTimeInSeconds];
			if(currtime-updatetime>updateinterval)
			{
				updatetime=currtime;

				double progress;
				if(sizenum != nil) progress=(double)done/(double)size;
				else progress=srchandle.estimatedProgress;

				[delegate unarchiver:self extractionProgressForEntryWithDictionary:dict
				fileFraction:progress estimatedTotalFraction:parser.handle.estimatedProgress];
			}
		}

		// Check if the file has already been marked as corrupt, and
		// give up without testing checksum if so.
		NSNumber *iscorrupt=dict[XADIsCorruptedKey];
		if(iscorrupt&&iscorrupt.boolValue) return XADErrorDecrunch;

		// If the file has a checksum, check it. Otherwise, if it has a
		// size, check that the size ended up correct.
		if(srchandle.hasChecksum)
		{
			if(!srchandle.checksumCorrect) return XADErrorChecksum;
		}
		else
		{
			if(sizenum&&done!=size) return XADErrorDecrunch; // kind of hacky
		}

		// Send a final progress report.
		[delegate unarchiver:self extractionProgressForEntryWithDictionary:dict
		fileFraction:1 estimatedTotalFraction:parser.handle.estimatedProgress];
	}
	@catch(id e)
	{
		return [XADException parseException:e];
	}

	free(buf);

	return XADErrorNone;
}

-(NSString *)adjustPathString:(NSString *)path forEntryWithDictionary:(NSDictionary *)dict
{
	// If we are unpacking a resource fork, we may need to modify the path.
	NSNumber *resnum=dict[XADIsResourceForkKey];
	if(resnum&&resnum.boolValue)
	{
		switch(forkstyle)
		{
			case XADForkStyleHiddenAppleDouble:
				// TODO: is this path generation correct?
				return [path.stringByDeletingLastPathComponent stringByAppendingPathComponent:
						[@"._" stringByAppendingString:path.lastPathComponent]];
				break;
				
			case XADForkStyleVisibleAppleDouble:
				return [path stringByAppendingPathExtension:@"rsrc"];
				break;
				
			case XADForkStyleHFVExplorerAppleDouble:
				// TODO: is this path generation correct?
				return [path.stringByDeletingLastPathComponent stringByAppendingPathComponent:
						[@"%" stringByAppendingString:path.lastPathComponent]];
				break;
				
			default:
				break;
		}
	}
	return path;
}

-(BOOL)_shouldStop
{
	if(!delegate) return NO;
	if(shouldstop) return YES;

	return shouldstop=[delegate extractionShouldStopForUnarchiver:self];
}

@end



@implementation NSObject (XADUnarchiverDelegate)

-(void)unarchiverNeedsPassword:(XADUnarchiver *)unarchiver {}

-(NSString *)unarchiver:(XADUnarchiver *)unarchiver pathForExtractingEntryWithDictionary:(NSDictionary *)dict { return nil; }

-(BOOL)unarchiver:(XADUnarchiver *)unarchiver shouldExtractEntryWithDictionary:(NSDictionary *)dict suggestedPath:(NSString **)pathptr
{
	// Kludge to handle old-style interface.
	if([self respondsToSelector:@selector(unarchiver:shouldExtractEntryWithDictionary:to:)])
	{
		NSString *path=[self unarchiver:unarchiver pathForExtractingEntryWithDictionary:dict];
		if(path) *pathptr=path;
		return [(NSObject<XADUnarchiverDelegate>*)self unarchiver:unarchiver shouldExtractEntryWithDictionary:dict to:*pathptr];
	}
	else return YES;
}

-(void)unarchiver:(XADUnarchiver *)unarchiver willExtractEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path {}
-(void)unarchiver:(XADUnarchiver *)unarchiver didExtractEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path error:(XADError)error {}

-(BOOL)unarchiver:(XADUnarchiver *)unarchiver shouldCreateDirectory:(NSString *)directory { return YES; }
-(BOOL)unarchiver:(XADUnarchiver *)unarchiver shouldDeleteFileAndCreateDirectory:(NSString *)directory { return NO; }

-(BOOL)unarchiver:(XADUnarchiver *)unarchiver shouldExtractArchiveEntryWithDictionary:(NSDictionary *)dict to:(NSString *)path { return NO; }
-(void)unarchiver:(XADUnarchiver *)unarchiver willExtractArchiveEntryWithDictionary:(NSDictionary *)dict withUnarchiver:(XADUnarchiver *)subunarchiver to:(NSString *)path {}
-(void)unarchiver:(XADUnarchiver *)unarchiver didExtractArchiveEntryWithDictionary:(NSDictionary *)dict withUnarchiver:(XADUnarchiver *)subunarchiver to:(NSString *)path error:(XADError)error {}

-(NSString *)unarchiver:(XADUnarchiver *)unarchiver destinationForLink:(XADString *)link from:(NSString *)path
{
	// Kludge to handle old-style interface.
	if([self respondsToSelector:@selector(unarchiver:linkDestinationForEntryWithDictionary:from:)])
	{
		return [(NSObject<XADUnarchiverDelegate>*)self unarchiver:unarchiver linkDestinationForEntryWithDictionary:
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
			link,XADLinkDestinationKey,
			@YES,XADIsLinkKey,
		nil] from:path];
	}
	else return link.string;
}

-(BOOL)extractionShouldStopForUnarchiver:(XADUnarchiver *)unarchiver { return NO; }
-(void)unarchiver:(XADUnarchiver *)unarchiver extractionProgressForEntryWithDictionary:(NSDictionary *)dict
fileFraction:(double)fileprogress estimatedTotalFraction:(double)totalprogress {}

-(void)unarchiver:(XADUnarchiver *)unarchiver findsFileInterestingForReason:(NSString *)reason {}

@end

