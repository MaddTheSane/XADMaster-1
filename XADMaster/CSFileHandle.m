#import "CSFileHandle.h"

#include <sys/stat.h>

#if !__has_feature(objc_arc)
#error this file needs to be compiled with Automatic Reference Counting (ARC)
#endif

NSString *const CSCannotOpenFileException=@"CSCannotOpenFileException";
NSString *const CSFileErrorException=@"CSFileErrorException";




@implementation CSFileHandle
@synthesize filePointer = fh;

+(CSFileHandle *)fileHandleForReadingAtFileURL:(NSURL *)path
{ return [self fileHandleForFileURL:path modes:@"rb"]; }

+(CSFileHandle *)fileHandleForWritingAtFileURL:(NSURL *)path
{ return [self fileHandleForFileURL:path modes:@"wb"]; }

+(CSFileHandle *)fileHandleForFileURL:(NSURL *)path modes:(NSString *)modes
{
	if(!path) return nil;
	
#if defined(__COCOTRON__) // Cocotron
	FILE *fileh=_wfopen([path fileSystemRepresentationW],
						(const wchar_t *)[modes cStringUsingEncoding:NSUnicodeStringEncoding]);
#elif defined(__MINGW32__) // GNUstep under mingw32 - sort of untested
	FILE *fileh=_wfopen((const wchar_t *)[path fileSystemRepresentation],
						(const wchar_t *)[modes cStringUsingEncoding:NSUnicodeStringEncoding]);
#else // Cocoa or GNUstep under Linux
	FILE *fileh=fopen(path.fileSystemRepresentation,modes.UTF8String);
#endif
	
	if(!fileh) [[NSException exceptionWithName:CSCannotOpenFileException
										reason: [NSString stringWithFormat:@"Error attempting to open file \"%@\" in mode \"%@\" (%d).",path,modes, (int)errno]
									  userInfo:@{NSUnderlyingErrorKey: [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil],
												 NSURLErrorKey: path
												 }] raise];
	
	CSFileHandle *handle=[[CSFileHandle alloc] initWithFilePointer:fileh closeOnDealloc:YES path:path.path];
	if(handle) return handle;
	
	fclose(fileh);
	return nil;
}

+(CSFileHandle *)fileHandleForReadingAtPath:(NSString *)path
{ return [self fileHandleForPath:path modes:@"rb"]; }

+(CSFileHandle *)fileHandleForWritingAtPath:(NSString *)path
{ return [self fileHandleForPath:path modes:@"wb"]; }

+(CSFileHandle *)fileHandleForPath:(NSString *)path modes:(NSString *)modes
{
	if(!path) return nil;

	#if defined(__COCOTRON__) // Cocotron
	FILE *fileh=_wfopen([path fileSystemRepresentationW],
	(const wchar_t *)[modes cStringUsingEncoding:NSUnicodeStringEncoding]);
	#elif defined(__MINGW32__) // GNUstep under mingw32 - sort of untested
	FILE *fileh=_wfopen((const wchar_t *)[path fileSystemRepresentation],
	(const wchar_t *)[modes cStringUsingEncoding:NSUnicodeStringEncoding]);
	#else // Cocoa or GNUstep under Linux
	FILE *fileh=fopen(path.fileSystemRepresentation,modes.UTF8String);
	#endif

	if(!fileh) [[NSException exceptionWithName:CSCannotOpenFileException
										reason: [NSString stringWithFormat:@"Error attempting to open file \"%@\" in mode \"%@\" (%d).",path,modes, (int)errno]
									  userInfo:@{NSUnderlyingErrorKey: [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil],
												 NSFilePathErrorKey: path
												 }] raise];

	CSFileHandle *handle=[[CSFileHandle alloc] initWithFilePointer:fileh closeOnDealloc:YES path:path];
	if(handle) return handle;

	fclose(fileh);
	return nil;
}

+(CSFileHandle *)fileHandleForStandardInput
{
	static CSFileHandle *handle=nil;
	if(!handle) handle=[[CSFileHandle alloc] initWithFilePointer:stdin closeOnDealloc:NO path:@"/dev/stdin"];
	return handle;
}

+(CSFileHandle *)fileHandleForStandardOutput
{
	static CSFileHandle *handle=nil;
	if(!handle) handle=[[CSFileHandle alloc] initWithFilePointer:stdout closeOnDealloc:NO path:@"/dev/stdout"];
	return handle;
}

+(CSFileHandle *)fileHandleForStandardError
{
	static CSFileHandle *handle=nil;
	if(!handle) handle=[[CSFileHandle alloc] initWithFilePointer:stderr closeOnDealloc:NO path:@"/dev/stderr"];
	return handle;
}




-(id)initWithFilePointer:(FILE *)file closeOnDealloc:(BOOL)closeondealloc path:(NSString *)filepath
{
	if(self=[super init])
	{
		fh=file;
		path=[filepath copy];
 		close=closeondealloc;
		multilock=nil;
		fhowner=nil;
	}
	return self;
}

-(id)initAsCopyOf:(CSFileHandle *)other
{
	if(self=[super initAsCopyOf:other])
	{
		fh=other->fh;
		path=[other->path copy];
 		close=NO;
		if(other->fhowner) fhowner=other->fhowner;
		else fhowner=other;

		if(!other->multilock) [other _setMultiMode];

		multilock=other->multilock;
		[multilock lock];
		pos=other->pos;
		[multilock unlock];
	}
	return self;
}

-(void)dealloc
{
	if(fh&&close) fclose(fh);
}

-(void)close
{
	if(fh && close) fclose(fh);
	fh=NULL;
}




-(off_t)fileSize
{
	#if defined(__MINGW32__)
	struct _stati64 s;
	if(_fstati64(fileno(fh),&s)) [self _raiseError];
	#else
	struct stat s;
	if(fstat(fileno(fh),&s)) [self _raiseError];
	#endif

	return s.st_size;
}

-(off_t)offsetInFile
{
	if(multilock) return pos;
	else return ftello(fh);
}

-(BOOL)atEndOfFile
{
	return self.offsetInFile==self.fileSize;
/*	if(multi) return pos==[self fileSize];
	else return feof(fh);*/ // feof() only returns true after trying to read past the end
}



-(void)seekToFileOffset:(off_t)offs
{
	if(multilock) { [multilock lock]; }
	//if(offs>[self fileSize]) [self _raiseEOF];
	if(fseeko(fh,offs,SEEK_SET)) [self _raiseError];
	if(multilock) { pos=ftello(fh); [multilock unlock]; }
}

-(void)seekToEndOfFile
{
	if(multilock) { [multilock lock]; }
	if(fseeko(fh,0,SEEK_END)) [self _raiseError];
	if(multilock) { pos=ftello(fh); [multilock unlock]; }
}

-(void)pushBackByte:(int)byte
{
	if(multilock) [self _raiseNotSupported:_cmd];
	if(ungetc(byte,fh)==EOF) [self _raiseError];
}

-(NSInteger)readAtMost:(NSInteger)num toBuffer:(void *)buffer
{
	if(num==0) return 0;
	if(multilock) { [multilock lock]; fseeko(fh,pos,SEEK_SET); }
	NSInteger n=(NSInteger)fread(buffer,1,num,fh);
	if(n<=0&&!feof(fh)) [self _raiseError];
	if(multilock) { pos=ftello(fh); [multilock unlock]; }
	return n;
}

-(void)writeBytes:(NSInteger)num fromBuffer:(const void *)buffer
{
	if(multilock) { [multilock lock]; fseeko(fh,pos,SEEK_SET); }
	if(fwrite(buffer,1,num,fh)!=num) [self _raiseError];
	if(multilock) { pos=ftello(fh); [multilock unlock]; }
}

-(NSString *)name
{
	return path;
}




-(void)_raiseError
{
	if(feof(fh)) [self _raiseEOF];
	else [[[NSException alloc] initWithName:CSFileErrorException
	reason:[NSString stringWithFormat:@"Error while attempting to read file \"%@\": %s.",[self name],strerror(errno)]
								   userInfo:@{@"ErrNo": @(errno)}] raise];
}

-(void)_setMultiMode
{
	if(!multilock)
	{
		multilock=[NSLock new];
		pos=ftello(fh);
	}
}

@end
