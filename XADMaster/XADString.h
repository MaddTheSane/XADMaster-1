#import <Foundation/Foundation.h>

#ifndef NS_TYPED_ENUM
#define NS_TYPED_ENUM
#endif

#ifndef NS_SWIFT_NAME
#define NS_SWIFT_NAME(x)
#endif

NS_ASSUME_NONNULL_BEGIN

@class XADStringSource, UniversalDetector;

//! The supported encodings used by \c XADString
typedef NSString *XADStringEncodingName NS_TYPED_ENUM;

extern XADStringEncodingName const XADUTF8StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.utf8);
extern XADStringEncodingName const XADASCIIStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.ascii);

extern XADStringEncodingName const XADISOLatin1StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin1);
extern XADStringEncodingName const XADISOLatin2StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin2);
extern XADStringEncodingName const XADISOLatin3StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin3);
extern XADStringEncodingName const XADISOLatin4StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin4);
extern XADStringEncodingName const XADISOLatin5StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin5);
extern XADStringEncodingName const XADISOLatin6StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin6);
extern XADStringEncodingName const XADISOLatin7StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin7);
extern XADStringEncodingName const XADISOLatin8StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin8);
extern XADStringEncodingName const XADISOLatin9StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin9);
extern XADStringEncodingName const XADISOLatin10StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin10);
extern XADStringEncodingName const XADISOLatin11StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin11);
extern XADStringEncodingName const XADISOLatin12StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin12);
extern XADStringEncodingName const XADISOLatin13StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin13);
extern XADStringEncodingName const XADISOLatin14StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin14);
extern XADStringEncodingName const XADISOLatin15StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin15);
extern XADStringEncodingName const XADISOLatin16StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.isoLatin16);

extern XADStringEncodingName const XADShiftJISStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.shiftJIS);

extern XADStringEncodingName const XADWindowsCP1250StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.windowsCP1250);
extern XADStringEncodingName const XADWindowsCP1251StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.windowsCP1251);
extern XADStringEncodingName const XADWindowsCP1252StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.windowsCP1252);
extern XADStringEncodingName const XADWindowsCP1253StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.windowsCP1253);
extern XADStringEncodingName const XADWindowsCP1254StringEncodingName NS_SWIFT_NAME(XADStringEncodingName.windowsCP1254);

extern XADStringEncodingName const XADMacOSRomanStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSRoman);
extern XADStringEncodingName const XADMacOSJapaneseStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSJapanese);
extern XADStringEncodingName const XADMacOSTraditionalChineseStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSTraditionalChinese);
extern XADStringEncodingName const XADMacOSKoreanStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSKorean);
extern XADStringEncodingName const XADMacOSArabicStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSArabic);
extern XADStringEncodingName const XADMacOSHebrewStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSHebrew);
extern XADStringEncodingName const XADMacOSGreekStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSGreek);
extern XADStringEncodingName const XADMacOSCyrillicStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSCyrillic);
extern XADStringEncodingName const XADMacOSSimplifiedChineseStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSSimplifiedChinese);
extern XADStringEncodingName const XADMacOSRomanianStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSRomanian);
extern XADStringEncodingName const XADMacOSUkranianStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSUkranian);
extern XADStringEncodingName const XADMacOSThaiStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSThai);
extern XADStringEncodingName const XADMacOSCentralEuropeanRomanStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSCentralEuropean);
extern XADStringEncodingName const XADMacOSIcelandicStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSIcelandic);
extern XADStringEncodingName const XADMacOSTurkishStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSTurkish);
extern XADStringEncodingName const XADMacOSCroatianStringEncodingName NS_SWIFT_NAME(XADStringEncodingName.macOSCroatian);


@protocol XADString <NSObject>

-(BOOL)canDecodeWithEncodingName:(XADStringEncodingName)encoding NS_SWIFT_NAME(canDecode(with:));
@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSString *string;
-(nullable NSString *)stringWithEncodingName:(XADStringEncodingName)encoding NS_SWIFT_NAME(string(with:));
@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSData *data;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL encodingIsKnown;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADStringEncodingName encodingName;
@property (NS_NONATOMIC_IOSONLY, readonly) float confidence;

@property (NS_NONATOMIC_IOSONLY, readonly, retain, nullable) XADStringSource *source;

#ifdef __APPLE__
-(BOOL)canDecodeWithEncoding:(NSStringEncoding)encoding NS_REFINED_FOR_SWIFT;
-(nullable NSString *)stringWithEncoding:(NSStringEncoding)encoding NS_REFINED_FOR_SWIFT;
@property (NS_NONATOMIC_IOSONLY, readonly) NSStringEncoding encoding NS_REFINED_FOR_SWIFT;
#endif

@end



@interface XADString:NSObject <XADString,NSCopying>
{
	NSData *data;
	NSString *string;
	XADStringSource *source;
}

+(instancetype)XADStringWithString:(NSString *)string;
+(instancetype)analyzedXADStringWithData:(NSData *)bytedata source:(XADStringSource *)stringsource;
+(nullable instancetype)decodedXADStringWithData:(NSData *)bytedata encodingName:(XADStringEncodingName)encoding;

+(NSString *)escapedStringForData:(NSData *)data encodingName:(XADStringEncodingName)encoding;
+(NSString *)escapedStringForBytes:(const void *)bytes length:(size_t)length encodingName:(XADStringEncodingName)encoding;
+(NSString *)escapedASCIIStringForBytes:(const void *)bytes length:(size_t)length;
+(NSData *)escapedASCIIDataForString:(NSString *)string;

-(instancetype)init UNAVAILABLE_ATTRIBUTE;
-(instancetype)initWithData:(NSData *)bytedata source:(XADStringSource *)stringsource NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithString:(NSString *)knownstring NS_DESIGNATED_INITIALIZER;

-(BOOL)canDecodeWithEncodingName:(XADStringEncodingName)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSString *string;
-(nullable NSString *)stringWithEncodingName:(XADStringEncodingName)encoding;
@property (NS_NONATOMIC_IOSONLY, readonly, copy, nullable) NSData *data;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL encodingIsKnown;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADStringEncodingName encodingName;
@property (NS_NONATOMIC_IOSONLY, readonly) float confidence;

@property (NS_NONATOMIC_IOSONLY, readonly, retain, nullable) XADStringSource *source;

-(BOOL)hasASCIIPrefix:(NSString *)asciiprefix;
-(XADString *)XADStringByStrippingASCIIPrefixOfLength:(NSInteger)length;

#ifdef __APPLE__
-(BOOL)canDecodeWithEncoding:(NSStringEncoding)encoding NS_REFINED_FOR_SWIFT;
-(nullable NSString *)stringWithEncoding:(NSStringEncoding)encoding NS_REFINED_FOR_SWIFT;
@property (NS_NONATOMIC_IOSONLY, readonly) NSStringEncoding encoding NS_REFINED_FOR_SWIFT;
#endif

@end

@interface XADString (PlatformSpecific)

+(BOOL)canDecodeData:(NSData *)data encodingName:(XADStringEncodingName)encoding;
+(BOOL)canDecodeBytes:(const void *)bytes length:(size_t)length encodingName:(XADStringEncodingName)encoding;
+(nullable NSString *)stringForData:(NSData *)data encodingName:(XADStringEncodingName)encoding;
+(nullable NSString *)stringForBytes:(const void *)bytes length:(size_t)length encodingName:(XADStringEncodingName)encoding;
+(nullable NSData *)dataForString:(NSString *)string encodingName:(XADStringEncodingName)encoding;
#if __has_feature(objc_class_property)
@property (class, NS_NONATOMIC_IOSONLY, readonly, copy) NSArray<NSArray<NSString*>*> *availableEncodingNames;
#else
+(NSArray<NSArray<NSString*>*> *)availableEncodingNames;
#endif

#ifdef __APPLE__
+(XADStringEncodingName)encodingNameForEncoding:(NSStringEncoding)encoding NS_REFINED_FOR_SWIFT;
+(NSStringEncoding)encodingForEncodingName:(XADStringEncodingName)encoding NS_REFINED_FOR_SWIFT;
#endif

@end




@interface XADStringSource:NSObject
{
	UniversalDetector *detector;
	XADStringEncodingName fixedencodingname;
	BOOL mac,hasanalyzeddata;

	#ifdef __APPLE__
	NSStringEncoding fixedencoding;
	#endif
}

-(instancetype)init NS_DESIGNATED_INITIALIZER;

-(void)analyzeData:(NSData *)data;

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasAnalyzedData;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) XADStringEncodingName encodingName;
@property (NS_NONATOMIC_IOSONLY, readonly) float confidence;
@property (NS_NONATOMIC_IOSONLY, readonly, retain, nullable) UniversalDetector *detector;

@property (NS_NONATOMIC_IOSONLY, readwrite, copy, nullable) XADStringEncodingName fixedEncodingName;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasFixedEncoding;
@property (NS_NONATOMIC_IOSONLY, readwrite) BOOL prefersMacEncodings;

#ifdef __APPLE__
@property (NS_NONATOMIC_IOSONLY, readonly) NSStringEncoding encoding NS_REFINED_FOR_SWIFT;
@property (NS_NONATOMIC_IOSONLY) NSStringEncoding fixedEncoding NS_REFINED_FOR_SWIFT;
#endif

@end

NS_ASSUME_NONNULL_END
