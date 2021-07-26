#include "00_Global.fx"
#include "00_Light.fx"
#include "00_Render.fx"
#include "00_Sky.fx"

float4 PS_PreRender(MeshOutput input) : SV_Target
{
    return PS_Shadow(input.sPosition, PS_AllLight(input));
}

MeshOutput VS(VertexMesh input)
{
    MeshOutput output = VS_Mesh(input);

    float4 position = WorldPosition(input.Position);
    position = mul(position, Reflection);
    position = mul(position, Projection);
    
    output.wvpPosition_Sub = position;
    
    return output;
}

float4 PS(MeshOutput input) : SV_Target
{
    float4 refPosition = input.wvpPosition_Sub;
    
    float2 reflection;
    reflection.x = refPosition.x / refPosition.w * 0.5f + 0.5f;
    reflection.y = -refPosition.y / refPosition.w * 0.5f + 0.5f;
    
    float4 color = ReflectionMap.Sample(LinearSampler, reflection);
    
    return float4(color.rgb, 1);
}

technique11 T0
{
    //Sky
    P_RS_DSS_VP(P0, FrontCounterClockwise_True, DepthEnable_False, VS_Mesh, PS_Sky)

    //Depth 
    P_RS_VP(P1, FrontCounterClockwise_True, VS_Depth_Mesh, PS_Depth)
    P_RS_VP(P2, FrontCounterClockwise_True, VS_Depth_Model, PS_Depth)
    P_RS_VP(P3, FrontCounterClockwise_True, VS_Depth_Animation, PS_Depth)

    //Render
    P_VP(P4, VS_Mesh, PS_PreRender)
    P_VP(P5, VS_Model, PS_PreRender)
    P_VP(P6, VS_Animation, PS_PreRender)

    //Refection - PreRender
    P_RS_DSS_VP(P7, FrontCounterClockwise_True, DepthEnable_False, VS_PreRender_Reflection_Mesh, PS_Sky)
    P_VP(P8, VS_PreRender_Reflection_Mesh, PS_PreRender)
    P_VP(P9, VS_PreRender_Reflection_Model, PS_PreRender)
    P_VP(P10, VS_PreRender_Reflection_Animation, PS_PreRender)

    //Reflection Plane
    P_VP(P11, VS, PS)
}