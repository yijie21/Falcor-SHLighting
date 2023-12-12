#pragma once
#include "Falcor.h"
#include "RenderGraph/RenderPass.h"
#include "Utils/Sampling/SampleGenerator.h"
#include "Utils/CudaUtils.h"
#include "Rendering/Lights/EnvMapSampler.h"

#include "Params.slang"

using namespace Falcor;

class SHLighting : public RenderPass
{
public:
    FALCOR_PLUGIN_CLASS(SHLighting, "SHLighting", "SH Lighting Pass.");

    static ref<SHLighting> create(ref<Device> pDevice, const Properties& props)
    {
        return make_ref<SHLighting>(pDevice, props);
    }

    SHLighting(ref<Device> pDevice, const Properties& props);

    virtual Properties getProperties() const override;
    virtual RenderPassReflection reflect(const CompileData& compileData) override;
    virtual void compile(RenderContext* pRenderContext, const CompileData& compileData) override {}
    virtual void execute(RenderContext* pRenderContext, const RenderData& renderData) override;
    virtual void renderUI(Gui::Widgets& widget) override;
    virtual void setScene(RenderContext* pRenderContext, const ref<Scene>& pScene) override;
    virtual bool onMouseEvent(const MouseEvent& mouseEvent) override { return false; }
    virtual bool onKeyEvent(const KeyboardEvent& keyEvent) override { return false; }

private:
    void updatePrograms();
    void addExtraDefines(const RenderData& renderData);
    void bindShaderVars(const RenderData& renderData);
    void beginFrame(RenderContext* pRenderContext, const RenderData& renderData);
    void endFrame(RenderContext* pRenderContext, const RenderData& renderData);
    void genProbes(RenderContext* pRenderContext);

    ref<Scene> mpScene;
    ref<SampleGenerator> mpSampleGenerator;

    PathTracerParams mParams;

    struct
    {
        ref<Program> pProgram;
        ref<RtBindingTable> pBindingTable;
        ref<RtProgramVars> pVars;
    } mTracer;

    ref<ComputePass> mpGenProbe;
    bool mRegenerateProbes = true;
    ref<Buffer> mpProbes;
    InteropBuffer mpProbesCuda;

    ref<ComputePass> mpReflectTypes;

    std::unique_ptr<EnvMapSampler>  mpEnvMapSampler;
};
