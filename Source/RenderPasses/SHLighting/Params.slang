#pragma once
#include "Utils/HostDeviceShared.slangh"

BEGIN_NAMESPACE_FALCOR

struct PathTracerParams
{
    uint32_t frameCount = 0;
    uint2 frameDim = { 0, 0 };
    uint32_t lmax = 2;
    uint32_t raySamples = 1000;
};

struct LightCoefficients {
    // TODO: 25个SH系数，之后需要输入参数修改
    float3 lightCoefficients[9];
};

END_NAMESPACE_FALCOR
