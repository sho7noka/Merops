//
//  USD-bind.hpp
//  Merops
//
//  Created by sho sumioka on 2018/08/27.
//  Copyright © 2018 sho sumioka. All rights reserved.
//

#ifndef USD_bind_hpp
#define USD_bind_hpp

#include <stdio.h>

#if __cplusplus
extern "C" {
#endif // __cplusplus
    
    const char** _getPrimInfo(void* stagePtr, int* numPrims);
    
    double _getStartTimeCode(void* stagePtr);
    
    double _getEndTimeCode(void* stagePtr);
    
    double _getTimeCodesPerSecond(void* stagePtr);
    
    const char* _getInterpolationType(void* stagePtr);
    
    void* _openStage(const char* sPath);
    
    void _reloadStage(void* stagePtr);
    
#if __cplusplus
}
#endif // __cplusplus

#endif /* USD_bind_hpp */
