### Overview

A plugin that allows you to use bookmarks in Xcode!  
I know you all have been waiting for soooo long for a bookmark plugin for Xcode.


## Usage

Use menu item or shortcuts to toggle/navigate/clear bookmarks like you do in other editors.

* Toggle Bookmark `Command + F2`
* Next Bookmark `F2`
* Prev Bookmark `Shift + F2`
* Clear All Bookmarks `Command + Option + F2`

## Installation
The recommended installation method (and also the simplest) is via the [Alcatraz](http://alcatraz.io/) plugin manager. within which search for XcodeBookmark, click install and you're done!

Or you can download the project and build it, and then relaunch Xcode.
It will be installed in `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins` automatically.

To uninstall it, Click the Remove button in Alcatraz or manually remove XcodeBookmark.xcplugin in the `Plug-ins` directory.

## Requirements

* Xcode 6.0+ 

## How It Works

The bookmarks are actually disabled breakpoints with some dedicated properties with which the bookmarks could be distinguished from the normal breakpoints. These properties are set to prevent the side effects of the breakpoints, so that the bookmarks won't intefere with the debugging process. 

They are:
* a condition of '!"bookmark"'.  
this is the primary property to turn a breakpoint into a bookmark
* a huge ignore count.  
so the bookmark won't get hit even if enabled
* continue running when hit.  
    so it won't stop even if hit.

## Todo
* jump between bookmarks in multiple files
* use a dedicated indicator for bookmarks
* you name it

## Owner

- [Nick Xiao](http://github.com/nicoster) [nicoster@](mailto:nicoster@gmail.com)


## Thanks

This project was inspired by the [Tuna](https://github.com/dealforest/Tuna) by [Toshihiro Morimoto](http://github.com/dealforest). Some of the code is directly imported from Tuna and the copyright notices are preserved. Thanks to Toshihiro and Tuna is an awesome plugin you may want to check out.

## License

XcodeBookmark is released under the MIT license. See LICENSE for details.
