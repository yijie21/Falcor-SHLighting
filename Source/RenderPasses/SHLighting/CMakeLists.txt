add_plugin(SHLighting)

target_sources(SHLighting PRIVATE
    SHLighting.cpp
    SHLighting.h
    Params.slang
    Tracer.rt.slang
    SHHelpers.slang
    GenProbe.cs.slang
    ReflectTypes.cs.slang
)

target_copy_shaders(SHLighting RenderPasses/SHLighting)

target_source_group(SHLighting "RenderPasses")
