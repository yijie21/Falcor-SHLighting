#include "Utils/HostDeviceShared.slangh"
#include "Utils/Math/MathConstants.slangh"

import Scene.Scene;
import Utils.Sampling.SampleGenerator;
import Utils.Math.MathHelpers;
import Rendering.Lights.EnvMapSampler;

import Params;
import SHHelpers;

static const uint kProbeRaySamples = 2000;

struct LightProbe
{
    RWStructuredBuffer<LightCoefficients> probes;
    EnvMapSampler envMapSampler;

    void execute(const uint3 dispatchID)
    {
        uint32_t probe_idx = dispatchID.x;
        SampleGenerator sg = SampleGenerator(dispatchID.xy, 1);

        LightCoefficients probe;
        for (uint32_t j = 0; j < 9; j++)
        {
            probe.lightCoefficients[j] = float3(0, 0, 0);
        }

        // TODO: 2000条采样方向，之后需要输入参数修改
        for (uint32_t i = 0; i < kProbeRaySamples; i++)
        {
            // float3 wiW = sample_sphere(sampleNext2D(sg));
            // float3 sampleColor = gScene.envMap.eval(wiW);

            EnvMapSample lightSample;
            envMapSampler.sample(sampleNext2D(sg), lightSample);

            float SHCoeffsR[9];
            float SHCoeffsG[9];
            float SHCoeffsB[9];

            // accumShProjection(wiW, sampleColor.x * M_4PI, SHCoeffsR);
            // accumShProjection(wiW, sampleColor.y * M_4PI, SHCoeffsG);
            // accumShProjection(wiW, sampleColor.z * M_4PI, SHCoeffsB);

            accumShProjection(lightSample.dir, lightSample.Le.x / lightSample.pdf, SHCoeffsR);
            accumShProjection(lightSample.dir, lightSample.Le.y / lightSample.pdf, SHCoeffsG);
            accumShProjection(lightSample.dir, lightSample.Le.z / lightSample.pdf, SHCoeffsB);

            for (uint32_t j = 0; j < 9; j++)
            {
                probe.lightCoefficients[j].x += SHCoeffsR[j];
                probe.lightCoefficients[j].y += SHCoeffsG[j];
                probe.lightCoefficients[j].z += SHCoeffsB[j];
            }
        }

        for (uint32_t j = 0; j < 9; j++)
        {
            probe.lightCoefficients[j].x /= float(kProbeRaySamples);
            probe.lightCoefficients[j].y /= float(kProbeRaySamples);
            probe.lightCoefficients[j].z /= float(kProbeRaySamples);
        }

        probes[probe_idx] = probe;
    }
}

ParameterBlock<LightProbe> gLightProbe;

[numthreads(16, 16, 1)]
void main(uint3 dispatchThreadID: SV_DispatchThreadID)
{
    gLightProbe.execute(dispatchThreadID);
}
