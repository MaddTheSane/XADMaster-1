#import "XADRegex.h"

#if !__has_feature(objc_arc)
#error this file needs to be compiled with Automatic Reference Counting (ARC)
#endif

static BOOL IsRegexSpecialCharacter(unichar c)
{
	return c=='^'||c=='.'||c=='['||c=='$'||c=='('||c==')'||
	c=='|'||c=='*'||c=='+'||c=='?'||c=='{'||c=='\\';
}

@implementation XADRegex
@synthesize pattern = patternstring;

+(XADRegex *)regexWithPattern:(NSString *)pattern options:(int)options
{ return [[XADRegex alloc] initWithPattern:pattern options:options]; }

+(XADRegex *)regexWithPattern:(NSString *)pattern
{ return [[XADRegex alloc] initWithPattern:pattern options:0]; }

+(NSString *)null
{
	static NSString *nullstring=nil;
	if(!nullstring) nullstring=[[NSMutableString alloc] initWithString:@""];
	return nullstring;
}

+(NSString *)patternForLiteralString:(NSString *)string
{
	long len=[string length];
	NSMutableString *escaped=[NSMutableString stringWithCapacity:len];

	for(long i=0;i<len;i++)
	{
		unichar c=[string characterAtIndex:i];
		if(IsRegexSpecialCharacter(c)) [escaped appendFormat:@"\\%C",c];
		else [escaped appendFormat:@"%C",c];
	}
	return [NSString stringWithString:escaped];
}

+(NSString *)patternForGlob:(NSString *)glob
{
	long len=[glob length];
	NSMutableString *pattern=[NSMutableString stringWithCapacity:len+2];

	[pattern appendString:@"^"];

	for(long i=0;i<len;i++)
	{
		unichar c=[glob characterAtIndex:i];
		if(c=='\\')
		{
			if(i==len-1) [pattern appendString:@"\\"];
			else
			{
				i++;
				unichar c=[glob characterAtIndex:i];
				if(IsRegexSpecialCharacter(c)) [pattern appendFormat:@"\\%C",c];
				else [pattern appendFormat:@"%C",c];
			}
		}
		else if(c=='*')
		{
			[pattern appendString:@".*"];
		}
		else if(c=='?')
		{
			[pattern appendString:@"."];
		}
		else if(c=='[')
		{
			[pattern appendString:@"["];
		}
		else if(c==']')
		{
			[pattern appendString:@"]"];
		}
		else if(IsRegexSpecialCharacter(c))
		{
			[pattern appendFormat:@"\\%C",c];
		}
		else
		{
			[pattern appendFormat:@"%C",c];
		}
	}

	[pattern appendString:@"$"];

	return [NSString stringWithString:pattern];
}

-(instancetype)initWithPattern:(NSString *)pattern options:(int)options
{
	if((self=[super init]))
	{
		patternstring=pattern;
		currdata=nil;
		matches=NULL;

		int err=regcomp(&preg,[pattern UTF8String],options|REG_EXTENDED);
		if(err)
		{
			char errbuf[256];
			regerror(err,&preg,errbuf,sizeof(errbuf));
			[NSException raise:@"XADRegexException" format:@"Could not compile regex \"%@\": %s",pattern,errbuf];
			return nil;
		}

		matches=calloc(sizeof(regmatch_t),preg.re_nsub+1);
		if(!matches)
		{
			[NSException raise:NSMallocException format:@"Out of memory when creating regex \"%@\"",pattern];
			return nil;
		}
	}
	return self;
}

-(void)dealloc
{
	regfree(&preg);
	free(matches);
}

-(void)beginMatchingString:(NSString *)string { [self beginMatchingData:[string dataUsingEncoding:NSUTF8StringEncoding]]; }

-(void)beginMatchingData:(NSData *)data { [self beginMatchingData:data range:NSMakeRange(0,[data length])]; }

-(void)beginMatchingData:(NSData *)data range:(NSRange)range
{
	matchrange=range;
	if(data==currdata) return;
}

-(void)finishMatching { currdata=nil; }

-(BOOL)matchNext
{
	matches[0].rm_so=matchrange.location;
	matches[0].rm_eo=matchrange.location+matchrange.length;
	if(regexec(&preg,[currdata bytes],preg.re_nsub+1,matches,REG_STARTEND)==0)
	{
		matchrange.length-=matches[0].rm_eo-matchrange.location;
		matchrange.location=(long)matches[0].rm_eo;
		return YES;
	}
	[self finishMatching];
	return NO;
}

-(NSString *)stringForMatch:(NSInteger)n
{
	if(n>preg.re_nsub||n<0) [NSException raise:NSRangeException format:@"Index %ld out of range for regex \"%@\"",(long)n,self];
 	if(matches[n].rm_so==-1&&matches[n].rm_eo==-1) return nil;
	return [[NSString alloc] initWithBytes:[currdata bytes]+matches[n].rm_so
									length:(long)(matches[n].rm_eo-matches[n].rm_so) encoding:NSUTF8StringEncoding];
}

-(NSArray *)allMatches
{
	NSMutableArray *array=[NSMutableArray arrayWithCapacity:preg.re_nsub+1];
	for(int i=0;i<=preg.re_nsub;i++)
	{
		NSString *str=[self stringForMatch:i];
		if(str) [array addObject:str];
		else [array addObject:[XADRegex null]];
	}
	return [NSArray arrayWithArray:array];
}



-(BOOL)matchesString:(NSString *)string
{
	[self beginMatchingString:string];
	BOOL res=[self matchNext];
	[self finishMatching];
	return res;
}

-(NSString *)matchedSubstringOfString:(NSString *)string
{
	[self beginMatchingString:string];
	NSString *res=nil;
	if([self matchNext]) res=[self stringForMatch:0];
	[self finishMatching];
	return res;
}

-(NSArray *)capturedSubstringsOfString:(NSString *)string
{
	[self beginMatchingString:string];
	NSArray *res=nil;
	if([self matchNext]) res=[self allMatches];
	[self finishMatching];
	return res;
}

-(NSArray *)allMatchedSubstringsOfString:(NSString *)string
{
	[self beginMatchingString:string];
	NSMutableArray *array=[NSMutableArray array];
	while([self matchNext]) [array addObject:[self stringForMatch:0]];
	[self finishMatching];
	return [NSArray arrayWithArray:array];
}

-(NSArray *)allCapturedSubstringsOfString:(NSString *)string
{
	[self beginMatchingString:string];
	NSMutableArray *array=[NSMutableArray array];
	while([self matchNext]) [array addObject:[self allMatches]];
	[self finishMatching];
	return [NSArray arrayWithArray:array];
}

-(NSArray *)componentsOfSeparatedString:(NSString *)string
{
	[self beginMatchingString:string];
	NSMutableArray *array=[NSMutableArray array];

	regoff_t prevstart=0;
	const char *bytes=[currdata bytes];
	while([self matchNext])
	{
		[array addObject:[[NSString alloc] initWithBytes:bytes+prevstart length:(long)(matches[0].rm_so-prevstart)
												encoding:NSUTF8StringEncoding]];
		prevstart=matches[0].rm_eo;
	}
	[array addObject:[[NSString alloc] initWithBytes:bytes+prevstart length:(long)([currdata length]-prevstart)
											encoding:NSUTF8StringEncoding]];

	[self finishMatching];
	return [NSArray arrayWithArray:array];
}

-(NSString *)description { return patternstring; }

@end



@implementation NSString (XADRegex)

-(BOOL)matchedByPattern:(NSString *)pattern { return [self matchedByPattern:pattern options:0]; }
-(BOOL)matchedByPattern:(NSString *)pattern options:(int)options
{ return [[XADRegex regexWithPattern:pattern options:options] matchesString:self]; }

-(NSString *)substringMatchedByPattern:(NSString *)pattern { return [self substringMatchedByPattern:pattern options:0]; }
-(NSString *)substringMatchedByPattern:(NSString *)pattern options:(int)options
{ return [[XADRegex regexWithPattern:pattern options:options] matchedSubstringOfString:self]; }

-(NSArray *)substringsCapturedByPattern:(NSString *)pattern { return [self substringsCapturedByPattern:pattern options:0]; }
-(NSArray *)substringsCapturedByPattern:(NSString *)pattern options:(int)options
{ return [[XADRegex regexWithPattern:pattern options:options] capturedSubstringsOfString:self]; }

-(NSArray *)allSubstringsMatchedByPattern:(NSString *)pattern { return [self allSubstringsMatchedByPattern:pattern options:0]; }
-(NSArray *)allSubstringsMatchedByPattern:(NSString *)pattern options:(int)options
{ return [[XADRegex regexWithPattern:pattern options:options] allMatchedSubstringsOfString:self]; }

-(NSArray *)allSubstringsCapturedByPattern:(NSString *)pattern { return [self allSubstringsCapturedByPattern:pattern options:0]; }
-(NSArray *)allSubstringsCapturedByPattern:(NSString *)pattern options:(int)options
{ return [[XADRegex regexWithPattern:pattern options:options] allCapturedSubstringsOfString:self]; }

-(NSArray *)componentsSeparatedByPattern:(NSString *)pattern { return [self componentsSeparatedByPattern:pattern options:0]; }
-(NSArray *)componentsSeparatedByPattern:(NSString *)pattern options:(int)options
{ return [[XADRegex regexWithPattern:pattern options:options] componentsOfSeparatedString:self]; }

-(NSString *)escapedPattern { return [XADRegex patternForLiteralString:self]; }

@end

