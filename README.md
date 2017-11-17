The XADMaster framework for uncompressing archive files in various formats. 

* The original source files can found at the developer's website (<http://unarchiver.c3.cx/unarchiver>). 

* XAMaster is released under the GNU LGPL.

* The UniversalDetector framework is included as a dependency for XADMaster.

* The framework is mirrored here in preparation for supporting other projects on GitHub (<https://github.com/arauchfuss/Simple-Comic>). 

* XADMaster first appeared in v2.0 of The Unarchiver.

* This mirror archives every released version of the XADMaster and UniversalDetector frameworks from 2.0 on to enable diff of the versions.

* The intent is to keep this master branch of this mirror up to date with The Unarchiver site.

#### Here is the original ReadMe from the The Unarchiver:
--------------------------------------------------------------

![Icon](http://wakaba.c3.cx/images/unarchiver_icon.png)

# The Unarchiver is an Objective-C application for uncompressing archive files.

* Supports more formats than I can remember. Zip, Tar, Gzip, Bzip2, 7-Zip, Rar, LhA, StuffIt, several old Amiga file and disk archives, CAB, LZX, stuff I don't even know what it is. Read [the wiki page](http://code.google.com/p/theunarchiver/wiki/SupportedFormats) for a more thorough listing of formats.
* Copies the Finder file-copying/moving/deleting interface for its interface.
* Uses character set autodetection code from Mozilla to auto-detect the encoding of the filenames in the archives.
* Supports split archives for certain formats, like RAR.
* Version 2.0 uses an archive-handling library built largely from scratch in Objective-C, which makes adding support for new formats and algorithms very easy.
* Uses [libxad](http://sourceforge.net/projects/libxad/) for older and more obscure formats. This is an old Amiga library for handling unpacking of archives.
* The unarchiving engine itself is multi-platform, and command-line tools exist for Linux, Windows and other OSes.
