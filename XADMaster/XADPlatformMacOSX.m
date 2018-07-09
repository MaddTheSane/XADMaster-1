#import "XADPlatform.h"
#import "CSMemoryHandle.h"
#import "NSDateXAD.h"

#import <fcntl.h>
#import <unistd.h>
#import <sys/stat.h>
#import <sys/time.h>
#import <sys/attr.h>
#import <sys/xattr.h>

struct ResourceOutputArguments
{
	int fd,offset;
};

@interface XADPlatform ()

+(void)setComment:(NSString *)comment forPath:(NSString *)path;

@end




@implementation XADPlatform

+(void)load
{
	if (@available(macOS 10.11, *)) {
		[NSError setUserInfoValueProviderForDomain:XADErrorDomain provider:^id _Nullable(NSError * _Nonnull err, NSErrorUserInfoKey  _Nonnull userInfoKey) {
			if ([userInfoKey isEqualToString:NSLocalizedDescriptionKey]) {
				return [XADException localizedDescribeXADError:(XADError)err.code];
			}
			return nil;
		}];
	}
}

//
// Archive entry extraction.
//

+(XADError)extractResourceForkEntryWithDictionary:(NSDictionary *)dict
unarchiver:(XADUnarchiver *)unarchiver toPath:(NSString *)destpath
{
	const char *cpath=destpath.fileSystemRepresentation;
	int originalpermissions=-1;

	// Open the file for writing, creating it if it doesn't exist.
	// TODO: Does it need to be opened for writing or is read enough?
	int fd=open(cpath,O_WRONLY|O_CREAT|O_NOFOLLOW,0666);
	if(fd==-1)
	{
		// If opening the file failed, check if it is a link and skip if it is.
		struct stat st;
		lstat(cpath,&st);

		if(S_ISLNK(st.st_mode))
		{
			NSNumber *sizenum=dict[XADFileSizeKey];
			if(sizenum == nil) return XADErrorNone;
			else if(sizenum.longLongValue==0) return XADErrorNone;
		}

		// Otherwise, try changing permissions.
		originalpermissions=st.st_mode;

		chmod(cpath,0700);

		fd=open(cpath,O_WRONLY|O_CREAT|O_NOFOLLOW,0666);
		if(fd==-1) return XADErrorOpenFile; // TODO: Better error.
	}

	struct ResourceOutputArguments args={ .fd=fd, .offset=0 };

	XADError error=[unarchiver runExtractorWithDictionary:dict
	outputTarget:self selector:@selector(outputToResourceFork:bytes:length:)
	argument:[NSValue valueWithPointer:&args]];

	close(fd);

	if(originalpermissions!=-1) chmod(cpath,originalpermissions);

	return error;
}

+(XADError)outputToResourceFork:(NSValue *)pointerval bytes:(uint8_t *)bytes length:(int)length
{
	struct ResourceOutputArguments *args=pointerval.pointerValue;
	if(fsetxattr(args->fd,XATTR_RESOURCEFORK_NAME,bytes,length,
	args->offset,0)) return XADErrorOutput;

	args->offset+=length;

	return XADErrorNone;
}




+(XADError)updateFileAttributesAtPath:(NSString *)path
forEntryWithDictionary:(NSDictionary *)dict parser:(XADArchiveParser *)parser
preservePermissions:(BOOL)preservepermissions
{
	const char *cpath=path.fileSystemRepresentation;

	// Read file permissions.
	struct stat st;
	if(lstat(cpath,&st)!=0) return XADErrorOpenFile; // TODO: better error

	// If the file does not have write permissions, change this temporarily.
	if(!(st.st_mode&S_IWUSR)) chmod(cpath,0700);

	// Write extended attributes.
	NSDictionary *extattrs=[parser extendedAttributesForDictionary:dict];
	if(extattrs)
	{
		NSEnumerator *enumerator=[extattrs keyEnumerator];
		NSString *key;
		while((key=[enumerator nextObject]))
		{
			NSData *data=extattrs[key];

			NSInteger namelen=[key lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
			char namebytes[namelen+1];
			[key getCString:namebytes maxLength:sizeof(namebytes) encoding:NSUTF8StringEncoding];

			setxattr(cpath,namebytes,data.bytes,data.length,0,XATTR_NOFOLLOW);
		}
	}

	// Set comment.
	XADString *comment=dict[XADCommentKey];
	if(comment) [self setComment:comment.string forPath:path];

	// Attrlist structures.
	struct attrlist list={ ATTR_BIT_MAP_COUNT };
	uint8_t attrdata[3*sizeof(struct timespec)+sizeof(uint32_t)];
	uint8_t *attrptr=attrdata;

	// Handle timestamps.
	NSDate *creation=dict[XADCreationDateKey];
	NSDate *modification=dict[XADLastModificationDateKey];
	NSDate *access=dict[XADLastAccessDateKey];

	if(creation)
	{
		list.commonattr|=ATTR_CMN_CRTIME;
		*((struct timespec *)attrptr)=creation.timespecStruct;
		attrptr+=sizeof(struct timeval);
	}
	if(modification)
	{
		list.commonattr|=ATTR_CMN_MODTIME;
		*((struct timespec *)attrptr)=modification.timespecStruct;
		attrptr+=sizeof(struct timeval);
	}
	if(access)
	{
		list.commonattr|=ATTR_CMN_ACCTIME;
		*((struct timespec *)attrptr)=access.timespecStruct;
		attrptr+=sizeof(struct timeval);
	}

	// Figure out permissions, or reuse the earlier value.
	mode_t mode=st.st_mode;
	NSNumber *permissions=dict[XADPosixPermissionsKey];
	if(permissions != nil)
	{
		mode=permissions.unsignedShortValue;
		if(!preservepermissions)
		{
			mode_t mask=umask(022);
			umask(mask); // This is stupid. Is there no sane way to just READ the umask?
			mode&=~(mask|S_ISUID|S_ISGID);

			// Just force read and write flags for all files, no matter what
			// insane archives think.
			mode|=S_IRUSR|S_IWUSR;
		}
	}

	// Add permissions to attribute list.
	list.commonattr|=ATTR_CMN_ACCESSMASK;
	*((uint32_t *)attrptr)=mode;
	attrptr+=sizeof(uint32_t);

	// Finally, set all attributes.
	setattrlist(cpath,&list,attrdata,attrptr-attrdata,FSOPT_NOFOLLOW);

	return XADErrorNone;
}

+(void)setComment:(NSString *)comment forPath:(NSString *)path;
{
	if(!comment||!comment.length) return;

	// Don't bother if we're sandboxed, as Apple refuses to allow
	// entitlements for this.
	if(getenv("APP_SANDBOX_CONTAINER_ID")) return;

	const char *eventformat =
	"'----': 'obj '{ "         // Direct object is the file comment we want to modify
	"  form: enum(prop), "     //  ... the comment is an object's property...
	"  seld: type(comt), "     //  ... selected by the 'comt' 4CC ...
	"  want: type(prop), "     //  ... which we want to interpret as a property (not as e.g. text).
	"  from: 'obj '{ "         // It's the property of an object...
	"      form: enum(indx), "
	"      want: type(file), " //  ... of type 'file' ...
	"      seld: @,"           //  ... selected by an alias ...
	"      from: null() "      //  ... according to the receiving application.
	"              }"
	"             }, "
	"data: @";                 // The data is what we want to set the direct object to.

	NSAppleEventDescriptor *commentdesc=[NSAppleEventDescriptor descriptorWithString:comment];

	NSURL *fileURL = [NSURL fileURLWithPath:path];
	NSString *fileString = [fileURL.absoluteString retain];
	const char *fileCStr = fileString.UTF8String;

	AEDesc filedesc;
	AEInitializeDesc(&filedesc);
	if(AECoercePtr(typeFileURL,fileCStr,strlen(fileCStr),typeAlias,&filedesc)!=noErr) {[fileString release]; return;}

	AEDesc builtevent,replyevent;
	AEInitializeDesc(&builtevent);
	AEInitializeDesc(&replyevent);
	[fileString release];

	static OSType findersignature='MACS';

	OSErr err=AEBuildAppleEvent(kAECoreSuite,kAESetData,
	typeApplSignature,&findersignature,sizeof(findersignature),
	kAutoGenerateReturnID,kAnyTransactionID,
	&builtevent,NULL,eventformat,&filedesc,commentdesc.aeDesc);

	AEDisposeDesc(&filedesc);

	if(err!=noErr) return;

	AESendMessage(&builtevent,&replyevent,kAENoReply,kAEDefaultTimeout);

	AEDisposeDesc(&builtevent);
	AEDisposeDesc(&replyevent);
}




+(XADError)createLinkAtPath:(NSString *)path withDestinationPath:(NSString *)link
{
	struct stat st;
	const char *destcstr=path.fileSystemRepresentation;
	if(lstat(destcstr,&st)==0) unlink(destcstr);
	if(symlink(link.fileSystemRepresentation,destcstr)!=0) return XADErrorLink;

	return XADErrorNone;
}




//
// Archive post-processing.
//

#ifdef IsLegacyVersion

+(id)readCloneableMetadataFromPath:(NSString *)path
{
	if(!LSSetItemAttribute) return nil;

	NSURL *url=[NSURL fileURLWithPath:path];
	if(!url) return nil;

	FSRef ref;
	if(CFURLGetFSRef((CFURLRef)url,&ref))
	{
		CFDictionaryRef quarantinedict;
		if(LSCopyItemAttribute(&ref,kLSRolesAll,kLSItemQuarantineProperties,
		(CFTypeRef*)&quarantinedict)==noErr)
		{
			return [(id)quarantinedict autorelease];
		}
	}
	return nil;
}

+(void)writeCloneableMetadata:(id)metadata toPath:(NSString *)path
{
	if(!LSSetItemAttribute) return;

	NSURL *url=[NSURL fileURLWithPath:path];
	if(!url) return nil;

	FSRef ref;
	if(CFURLGetFSRef((CFURLRef)url,&ref))
	LSSetItemAttribute(&ref,kLSRolesAll,kLSItemQuarantineProperties,metadata);
}

#else

+(id)readCloneableMetadataFromPath:(NSString *)path
{
	NSDictionary *value;
	if([[NSURL fileURLWithPath:path] getResourceValue:&value forKey:NSURLQuarantinePropertiesKey error:NULL])
	{
		return value;
	}
	return nil;
}

+(void)writeCloneableMetadata:(id)metadata toPath:(NSString *)path
{
	[[NSURL fileURLWithPath:path] setResourceValue:metadata forKey:@"NSURLQuarantinePropertiesKey" error:NULL];
}

#endif

+(BOOL)copyDateFromPath:(NSString *)src toPath:(NSString *)dest
{
	struct stat st;
	const char *csrc=src.fileSystemRepresentation;
	if(stat(csrc,&st)!=0) return NO;

	struct timeval times[2]={
		{st.st_atimespec.tv_sec,(int)(st.st_atimespec.tv_nsec/1000)},
		{st.st_mtimespec.tv_sec,(int)(st.st_mtimespec.tv_nsec/1000)},
	};

	const char *cdest=dest.fileSystemRepresentation;
	if(utimes(cdest,times)!=0) return NO;

	return YES;
}

+(BOOL)resetDateAtPath:(NSString *)path
{
	const char *cpath=path.fileSystemRepresentation;
	if(utimes(cpath,NULL)!=0) return NO;

	return YES;
}



//
// Path functions.
//

+(BOOL)fileExistsAtPath:(NSString *)path { return [self fileExistsAtPath:path isDirectory:NULL]; }

+(BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isdirptr
{
	// [NSFileManager fileExistsAtPath:] is broken. It will happily return NO
	// for some symbolic links. We need to implement our own.

	struct stat st;
	if(lstat(path.fileSystemRepresentation,&st)!=0) return NO;

	if(isdirptr)
	{
		if((st.st_mode&S_IFMT)==S_IFDIR) *isdirptr=YES;
		else *isdirptr=NO;
	}

	return YES;
}

+(NSString *)uniqueDirectoryPathWithParentDirectory:(NSString *)parent
{
	// TODO: ensure this path is actually unique.
	NSDate *now=[NSDate date];
	int64_t t=now.timeIntervalSinceReferenceDate*1000000000;
	pid_t pid=getpid();

	NSString *dirname=[NSString stringWithFormat:@"XADTemp%qd%d",t,pid];

	if(parent) return [parent stringByAppendingPathComponent:dirname];
	else return dirname;
}

+(NSString *)sanitizedPathComponent:(NSString *)component
{
	if([component rangeOfString:@"/"].location==NSNotFound&&
	[component rangeOfString:@"\000"].location==NSNotFound) return component;

	NSMutableString *newstring=[NSMutableString stringWithString:component];
	[newstring replaceOccurrencesOfString:@"/" withString:@":" options:0 range:NSMakeRange(0,newstring.length)];
	[newstring replaceOccurrencesOfString:@"\000" withString:@"_" options:0 range:NSMakeRange(0,newstring.length)];
	return newstring;
}

+(NSArray *)contentsOfDirectoryAtPath:(NSString *)path
{
	#if MAC_OS_X_VERSION_MIN_REQUIRED>=1050
	return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
	#else
	return [[NSFileManager defaultManager] directoryContentsAtPath:path];
	#endif
}

+(BOOL)moveItemAtPath:(NSString *)src toPath:(NSString *)dest
{
	#if MAC_OS_X_VERSION_MIN_REQUIRED>=1050
	return [[NSFileManager defaultManager] moveItemAtPath:src toPath:dest error:NULL];
	#else
	return [[NSFileManager defaultManager] movePath:src toPath:dest handler:nil];
	#endif
}

+(BOOL)removeItemAtPath:(NSString *)path
{
	#if MAC_OS_X_VERSION_MIN_REQUIRED>=1050
	return [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
	#else
	return [[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
	#endif
}



//
// Resource forks
//

+(CSHandle *)handleForReadingResourceForkAtPath:(NSString *)path
{
	// TODO: Make an actual CSHandle subclass? Possible but sort of useless.
	NSMutableData *data=[NSMutableData data];

	const char *cpath=path.fileSystemRepresentation;
	int fd=open(cpath,O_RDONLY);
	if(fd==-1) return nil;

	uint32_t pos=0;
	for(;;)
	{
		uint8_t buffer[16384];

		ssize_t actual=fgetxattr(fd,XATTR_RESOURCEFORK_NAME,buffer,sizeof(buffer),pos,0);
		if(actual<0) { close(fd); return nil; }
		if(actual==0) break;

		[data appendBytes:buffer length:actual];
		pos+=actual;
	}

	close(fd);

	return [CSMemoryHandle memoryHandleForReadingData:data];
}

+(CSHandle *)handleForReadingResourceForkAtFileURL:(NSURL *)path
{
	// TODO: Make an actual CSHandle subclass? Possible but sort of useless.
	NSMutableData *data=[NSMutableData data];
	
	const char *cpath=path.fileSystemRepresentation;
	int fd=open(cpath,O_RDONLY);
	if(fd==-1) return nil;
	
	uint32_t pos=0;
	for(;;)
	{
		uint8_t buffer[16384];
		
		ssize_t actual=fgetxattr(fd,XATTR_RESOURCEFORK_NAME,buffer,sizeof(buffer),pos,0);
		if(actual<0) { close(fd); return nil; }
		if(actual==0) break;
		
		[data appendBytes:buffer length:actual];
		pos+=actual;
	}
	
	close(fd);
	
	return [CSMemoryHandle memoryHandleForReadingData:data];
}


//
// Time functions.
//

+(double)currentTimeInSeconds
{
	struct timeval tv;
	gettimeofday(&tv,NULL);
	return (double)tv.tv_sec+(double)tv.tv_usec/1000000.0;
}





@end
