//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#ifndef Merops_Bridging_Header_h
#define Merops_Bridging_Header_h

@import Foundation;

// kivy for iOS
#if TARGET_OS_IPHONE | TARGET_OS_IPAD
#include "Python.h"
#endif

// git
#import "ObjectiveGit/git2.h"
#import "ObjectiveGit/ObjectiveGit.h"

// lib
#import "USD-bind.hpp"

#endif
