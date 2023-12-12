#include "SHLighting.h"
#include "RenderGraph/RenderPassHelpers.h"
#include "RenderGraph/RenderPassStandardFlags.h"

extern "C" FALCOR_API_EXPORT void registerPlugin(Falcor::PluginRegistry& registry)
{
    registry.registerClass<RenderPass, SHLighting>();
}

namespace
{
const char kTracerFile[] = "RenderPasses/SHLighting/Tracer.rt.slang";
const char kProbeFile[] = "RenderPasses/SHLighting/GenProbe.cs.slang";
const char kReflectTypesFile[] = "RenderPasses/SHLighting/ReflectTypes.cs.slang";

const char kLightProbeBlockName[] = "gLightProbe";

const uint32_t kMaxPayloadSizeBytes = 72u;
const uint32_t kMaxRecursionDepth = 2u;

const char kInputViewDir[] = "viewW";
const char kInputVBuffer[] = "vbuffer";

const char kOutputColor[] = "color";

const ChannelList kInputChannels =
{
    { kInputViewDir,        "gViewW",           "World-space view direction (xyz)", true /* optional */ },
    { kInputVBuffer,        "gVBuffer",         "V-buffer (xyz = world-space position, w = depth)" },
};

const ChannelList kOutputChannels =
{
    { kOutputColor,         "gOutputColor",     "Output color (RGBA)", false, ResourceFormat::RGBA32Float },
};

}

SHLighting::SHLighting(ref<Device> pDevice, const Properties& props) : RenderPass(pDevice) {
    mpSampleGenerator = SampleGenerator::create(mpDevice, SAMPLE_GENERATOR_UNIFORM);
    FALCOR_ASSERT(mpSampleGenerator);
}

Properties SHLighting::getProperties() const
{
    return {};
}

RenderPassReflection SHLighting::reflect(const CompileData& compileData)
{
    // Define the required resources here
    RenderPassReflection reflector;
    addRenderPassInputs(reflector, kInputChannels);
    addRenderPassOutputs(reflector, kOutputChannels);
    return reflector;
}

void SHLighting::execute(RenderContext* pRenderContext, const RenderData& renderData)
{
    if (!mpScene)
    {
        for (auto it : kOutputChannels)
        {
            Texture* pDst = renderData.getTexture(it.name).get();
            if (pDst)
                pRenderContext->clearTexture(pDst);
        }
        return;
    }

    beginFrame(pRenderContext, renderData);

    updatePrograms();

    addExtraDefines(renderData);

    bindShaderVars(renderData);

    genProbes(pRenderContext);

    const uint2 targetDim = renderData.getDefaultTextureDims();
    FALCOR_ASSERT(targetDim.x > 0 && targetDim.y > 0);

    // Spawn the rays.
    mpScene->raytrace(pRenderContext, mTracer.pProgram.get(), mTracer.pVars, uint3(targetDim, 1));

    endFrame(pRenderContext, renderData);
}

void SHLighting::beginFrame(RenderContext* pRenderContext, const RenderData& renderData)
{
    const auto& pOutputColor = renderData.getTexture(kOutputColor);
    FALCOR_ASSERT(pOutputColor);

    auto prevFrameDim = mParams.frameDim;
    mParams.frameDim = Falcor::uint2(pOutputColor->getWidth(), pOutputColor->getHeight());

    if (!mpProbes) {
        mpProbes = mpDevice->createStructuredBuffer(sizeof(LightCoefficients), 1,
            ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess | ResourceBindFlags::Shared, MemoryType::DeviceLocal, nullptr, false);
        mpProbesCuda = createInteropBuffer(mpDevice, sizeof(LightCoefficients) * 1);
    }

    if (!mpEnvMapSampler) {
        mpEnvMapSampler = std::make_unique<EnvMapSampler>(mpDevice, mpScene->getEnvMap());
    }
}

void SHLighting::endFrame(RenderContext* pRenderContext, const RenderData& renderData)
{
    mParams.frameCount++;
}

void SHLighting::updatePrograms()
{
    auto globalTypeConformances = mpScene->getTypeConformances();
    ProgramDesc baseDesc;
    baseDesc.addShaderModules(mpScene->getShaderModules());
    baseDesc.addTypeConformances(globalTypeConformances);

    DefineList defines;
    defines.add(mpSampleGenerator->getDefines());
    defines.add(mpScene->getSceneDefines());

    if (!mTracer.pProgram) {
        ProgramDesc desc = baseDesc;
        desc.addShaderLibrary(kTracerFile);
        desc.setMaxPayloadSize(kMaxPayloadSizeBytes);
        desc.setMaxAttributeSize(mpScene->getRaytracingMaxAttributeSize());
        desc.setMaxTraceRecursionDepth(kMaxRecursionDepth);

        mTracer.pBindingTable = RtBindingTable::create(2, 2, mpScene->getGeometryCount());
        auto& sbt = mTracer.pBindingTable;
        sbt->setRayGen(desc.addRayGen("rayGen"));
        sbt->setMiss(0, desc.addMiss("scatterMiss"));
        sbt->setMiss(1, desc.addMiss("shadowMiss"));

        // NOTE: only support triangle mesh now
        sbt->setHitGroup(
            0,
            mpScene->getGeometryIDs(Scene::GeometryType::TriangleMesh),
            desc.addHitGroup("scatterTriangleMeshClosestHit", "scatterTriangleMeshAnyHit")
        );
        sbt->setHitGroup(
            1, mpScene->getGeometryIDs(Scene::GeometryType::TriangleMesh), desc.addHitGroup("", "shadowTriangleMeshAnyHit")
        );

        mTracer.pProgram = Program::create(mpDevice, desc, defines);
    }

    if (!mpGenProbe) {
        ProgramDesc desc = baseDesc;
        desc.addShaderLibrary(kProbeFile).csEntry("main");
        mpGenProbe = ComputePass::create(mpDevice, desc, defines);
    }

    if (!mpReflectTypes) {
        ProgramDesc desc = baseDesc;
        desc.addShaderLibrary(kReflectTypesFile).csEntry("main");
        mpReflectTypes = ComputePass::create(mpDevice, desc, defines, false);
    }

    auto preparePass = [&](ref<ComputePass> pass)
    {
        // Note that we must use set instead of add defines to replace any stale state.
        pass->getProgram()->setDefines(defines);

        // Recreate program vars. This may trigger recompilation if needed.
        // Note that program versions are cached, so switching to a previously used specialization is faster.
        pass->setVars(nullptr);
    };

    preparePass(mpGenProbe);
    preparePass(mpReflectTypes);

    // auto var = mpReflectTypes->getRootVar();
    // if (!mpProbes) {
    //     mpProbes = mpDevice->createStructuredBuffer(var["lightCoefficients"], 1,
    //         ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess | ResourceBindFlags::Shared, MemoryType::DeviceLocal, nullptr, false);
    //     mpProbesCuda = createInteropBuffer(mpDevice, sizeof(LightCoefficients) * 1);
    // }
}

void SHLighting::addExtraDefines(const RenderData& renderData)
{
    mTracer.pProgram->addDefine("MAX_BOUNCES", std::to_string(3));
    mTracer.pProgram->addDefine("COMPUTE_DIRECT", "1");
    mTracer.pProgram->addDefine("USE_IMPORTANCE_SAMPLING", "1");
    mTracer.pProgram->addDefine("USE_ANALYTIC_LIGHTS", mpScene->useAnalyticLights() ? "1" : "0");
    mTracer.pProgram->addDefine("USE_EMISSIVE_LIGHTS", mpScene->useEmissiveLights() ? "1" : "0");
    mTracer.pProgram->addDefine("USE_ENV_LIGHT", mpScene->useEnvLight() ? "1" : "0");
    mTracer.pProgram->addDefine("USE_ENV_BACKGROUND", mpScene->useEnvBackground() ? "1" : "0");
    mTracer.pProgram->addDefines(getValidResourceDefines(kInputChannels, renderData));
    mTracer.pProgram->addDefines(getValidResourceDefines(kOutputChannels, renderData));
}

void SHLighting::bindShaderVars(const RenderData& renderData)
{
    mTracer.pVars = RtProgramVars::create(mpDevice, mTracer.pProgram, mTracer.pBindingTable);

    // bind utility classes into shared data
    auto var = mTracer.pVars->getRootVar();
    mpSampleGenerator->bindShaderData(var);

    // step 2: set shader constants
    auto& dict = renderData.getDictionary();
    var["CB"]["gFrameCount"] = mParams.frameCount;
    var["CB"]["gPRNGDimension"] = dict.keyExists(kRenderPassPRNGDimension) ? dict[kRenderPassPRNGDimension] : 0u;
    var["CB"]["gParams"].setBlob(mParams);
    var["lightCoefficients"] = mpProbes;

    auto varProbe = mpGenProbe->getRootVar()[kLightProbeBlockName];
    varProbe["probes"] = mpProbes;
    mpEnvMapSampler->bindShaderData(varProbe["envMapSampler"]);
    mpSampleGenerator->bindShaderData(varProbe);
    mpScene->bindShaderData(mpGenProbe->getRootVar()["gScene"]);

    // step 3: bind input/output buffers
    auto bind = [&](const ChannelDesc& desc)
    {
        if (!desc.texname.empty())
        {
            var[desc.texname] = renderData.getTexture(desc.name);
        }
    };
    for (auto channel : kInputChannels)
        bind(channel);
    for (auto channel : kOutputChannels)
        bind(channel);
}

void SHLighting::genProbes(RenderContext* pRenderContext)
{
    if (mRegenerateProbes == false) 
        return;

    mpGenProbe->execute(pRenderContext, uint3(1, 1, 1));
    pRenderContext->copyResource(mpProbesCuda.buffer.get(), mpProbes.get());

    mRegenerateProbes = false;
}

void SHLighting::setScene(RenderContext* pRenderContext, const ref<Scene>& pScene)
{
    mTracer.pProgram = nullptr;
    mTracer.pBindingTable = nullptr;
    mTracer.pVars = nullptr;
    mpReflectTypes = nullptr;

    mpEnvMapSampler = nullptr;

    mParams.frameCount = 0;

    mRegenerateProbes = true;

    mpScene = pScene;
}

void SHLighting::renderUI(Gui::Widgets& widget) {}
