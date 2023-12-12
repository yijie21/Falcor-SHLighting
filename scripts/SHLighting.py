from falcor import *

def render_graph_SHLighting():
    g = RenderGraph("SHLighting")
    AccumulatePass = createPass("AccumulatePass", {'enabled': True, 'precisionMode': 'Single'})
    g.addPass(AccumulatePass, "AccumulatePass")
    ToneMapper = createPass("ToneMapper", {'autoExposure': False, 'exposureCompensation': 0.0})
    g.addPass(ToneMapper, "ToneMapper")
    SHLighting = createPass("SHLighting")
    g.addPass(SHLighting, "SHLighting")
    VBufferRT = createPass("VBufferRT", {'samplePattern': 'Stratified', 'sampleCount': 16})
    g.addPass(VBufferRT, "VBufferRT")
    g.addEdge("AccumulatePass.output", "ToneMapper.src")
    g.addEdge("VBufferRT.vbuffer", "SHLighting.vbuffer")
    g.addEdge("VBufferRT.viewW", "SHLighting.viewW")
    g.addEdge("SHLighting.color", "AccumulatePass.input")
    g.markOutput("ToneMapper.dst")
    return g

SHLighting = render_graph_SHLighting()
try: m.addGraph(SHLighting)
except NameError: None

# m.loadScene("D:/code/Falcor/media/test_scenes/bunny.pyscene")
