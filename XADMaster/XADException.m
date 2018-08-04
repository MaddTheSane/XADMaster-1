#import "XADException.h"

#import "CSFileHandle.h"
#import "CSZlibHandle.h"
#import "CSBzip2Handle.h"

NSString *const XADExceptionName=@"XADException";
NSString *const XADErrorDomain=@"de.dstoecker.xadmaster.error";
NSString *const XADExceptionReasonKey=@"XADExceptionReason";

@implementation XADException

+(void)raiseUnknownException  { [self raiseExceptionWithXADError:XADErrorUnknown]; }
+(void)raiseInputException  { [self raiseExceptionWithXADError:XADErrorInput]; }
+(void)raiseOutputException  { [self raiseExceptionWithXADError:XADErrorOutput]; }
+(void)raiseIllegalDataException  { [self raiseExceptionWithXADError:XADErrorIllegalData]; }
+(void)raiseNotSupportedException  { [self raiseExceptionWithXADError:XADErrorNotSupported]; }
+(void)raisePasswordException { [self raiseExceptionWithXADError:XADErrorPassword]; }
+(void)raiseDecrunchException { [self raiseExceptionWithXADError:XADErrorDecrunch]; }
+(void)raiseChecksumException { [self raiseExceptionWithXADError:XADErrorChecksum]; }
+(void)raiseDataFormatException { [self raiseExceptionWithXADError:XADErrorDataFormat]; }
+(void)raiseOutOfMemoryException { [self raiseExceptionWithXADError:XADErrorOutOfMemory]; }

+(void)raiseExceptionWithXADError:(XADError)errnum
{
//	[NSException raise:@"XADException" format:@"%@",[self describeXADError:errnum]];
	[[[[NSException alloc] initWithName:XADExceptionName reason:[self describeXADError:errnum]
	userInfo:@{@"XADError": @(errnum)}] autorelease] raise];
}



+(XADError)parseException:(id)exception
{
	if([exception isKindOfClass:[NSException class]])
	{
		NSException *e=exception;
		NSString *name=e.name;
		if([name isEqual:XADExceptionName])
		{
			return [e.userInfo[@"XADError"] intValue];
		}
		else if([name isEqual:CSCannotOpenFileException]) return XADErrorOpenFile;
		else if([name isEqual:CSFileErrorException]) return XADErrorUnknown; // TODO: use ErrNo in userInfo to figure out better error
		else if([name isEqual:CSOutOfMemoryException]) return XADErrorOutOfMemory;
		else if([name isEqual:CSEndOfFileException]) return XADErrorInput;
		else if([name isEqual:CSNotImplementedException]) return XADErrorNotSupported;
		else if([name isEqual:CSNotSupportedException]) return XADErrorNotSupported;
		else if([name isEqual:CSZlibException]) return XADErrorDecrunch;
		else if([name isEqual:CSBzip2Exception]) return XADErrorDecrunch;
	}

	return XADErrorUnknown;
}

+(NSError*)parseExceptionReturningNSError:(nonnull id)exception
{
    if([exception isKindOfClass:[NSException class]])
    {
        NSException *e=exception;
        NSString *name=[e name];
		NSMutableDictionary *usrInfo = [NSMutableDictionary dictionaryWithDictionary:e.userInfo ?: @{}];
		usrInfo[XADExceptionReasonKey] = e.reason;
        if ([name isEqual:XADExceptionName]) {
            XADError errVal = [[e userInfo][@"XADError"] intValue];
            return [NSError errorWithDomain:XADErrorDomain code:errVal userInfo:usrInfo];
        } else if([name isEqual:CSCannotOpenFileException]) {
            return [NSError errorWithDomain:XADErrorDomain code:XADErrorOpenFile userInfo:usrInfo];
        } else if([name isEqual:CSFileErrorException]) {
			if (usrInfo && [usrInfo objectForKey:@"ErrNo"]) {
				int errNo = [usrInfo[@"ErrNo"] intValue];
				return [NSError errorWithDomain:NSPOSIXErrorDomain code:errNo userInfo:usrInfo];
			}
            return [NSError errorWithDomain:XADErrorDomain code:XADErrorUnknown userInfo:usrInfo];
        } else if([name isEqual:CSOutOfMemoryException]) {
            return [NSError errorWithDomain:XADErrorDomain code:XADErrorOutOfMemory userInfo:usrInfo];
        } else if([name isEqual:CSEndOfFileException]) {
            return [NSError errorWithDomain:XADErrorDomain code:XADErrorInput userInfo:usrInfo];
        } else if([name isEqual:CSNotImplementedException]) {
            return [NSError errorWithDomain:XADErrorDomain code:XADErrorNotSupported userInfo:usrInfo];
        } else if([name isEqual:CSNotSupportedException]) {
            return [NSError errorWithDomain:XADErrorDomain code:XADErrorNotSupported userInfo:usrInfo];
        } else if([name isEqual:CSZlibException]) {
            return [NSError errorWithDomain:XADErrorDomain code:XADErrorDecrunch userInfo:usrInfo];
        } else if([name isEqual:CSBzip2Exception]) {
            CSBzip2Error bzErr = [e.userInfo[@"BZ2ErrorType"] intValue];
            NSError *err = [NSError errorWithDomain:CSBzip2ErrorDomain code:bzErr userInfo:nil];
            usrInfo[NSUnderlyingErrorKey] = err;
            return [NSError errorWithDomain:XADErrorDomain code:XADErrorDecrunch userInfo:usrInfo];
        } else {
            return [NSError errorWithDomain:XADErrorDomain code:XADErrorUnknown userInfo:usrInfo];
        }
    }
    
    return [NSError errorWithDomain:XADErrorDomain code:XADErrorUnknown userInfo:nil];
}

+(NSString *)describeXADError:(XADError)error
{
	switch(error)
	{
		case XADErrorNone:			return nil;
		case XADErrorUnknown:		return @"Unknown error";
		case XADErrorInput:			return @"Attempted to read more data than was available";
		case XADErrorOutput:		return @"Failed to write to file";
		case XADErrorBadParameters:	return @"Function called with illegal parameters";
		case XADErrorOutOfMemory:	return @"Not enough memory available";
		case XADErrorIllegalData:	return @"Data is corrupted";
		case XADErrorNotSupported:	return @"File is not fully supported";
		case XADErrorResource:		return @"Required resource missing";
		case XADErrorDecrunch:		return @"Error on decrunching";
		case XADErrorFiletype:		return @"Unknown file type";
		case XADErrorOpenFile:		return @"Opening file failed";
		case XADErrorSkip:			return @"File, disk has been skipped";
		case XADErrorBreak:			return @"User cancelled extraction";
		case XADErrorFileExists:	return @"File already exists";
		case XADErrorPassword:		return @"Missing or wrong password";
		case XADErrorMakeDirectory:	return @"Could not create directory";
		case XADErrorChecksum:		return @"Wrong checksum";
		case XADErrorVerify:		return @"Verify failed (disk hook)";
		case XADErrorGeometry:		return @"Wrong drive geometry";
		case XADErrorDataFormat:	return @"Unknown data format";
		case XADErrorEmpty:			return @"Source contains no files";
		case XADErrorFileSystem:	return @"Unknown filesystem";
		case XADErrorFileDirectory:	return @"Name of file exists as directory";
		case XADErrorShortBuffer:	return @"Buffer was too short";
		case XADErrorEncoding:		return @"Text encoding was defective";
		case XADErrorLink:			return @"Could not create symlink";
		default:					return [NSString stringWithFormat:@"Error %d",error];
	}
}

+(NSString *)localizedDescribeXADError:(XADError)errnum
{
    NSString *nonLocDes = [self describeXADError:errnum];
    if (!nonLocDes) {
        return nil;
    }
    NSString *locDes = [[NSBundle bundleForClass:[XADException class]] localizedStringForKey:nonLocDes value:nonLocDes table:@"XADErrors"];

    return locDes;
}

@end

extern NSString *XADDescribeError(XADError errnum)
{
	return [XADException describeXADError:errnum];
}

extern NSString *XADLocalizedDescribeError(XADError errnum)
{
    return [XADException localizedDescribeXADError:errnum];
}
