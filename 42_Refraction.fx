#include "00_Global.fx"
#include "00_Light.fx"
#include "00_Render.fx"
#include "00_Sky.fx"

float4 PS_PreRender(MeshOutput input) : SV_Target
{
    return PS_Shadow(input.sPosition, PS_AllLight(input));
}

float4 PS(MeshOutput input) : SV_Target
{    
    float2 refraction;
    refraction.x = input.wvpPosition.x / input.wvpPosition.w * 0.5f + 0.5f;
    refraction.y = -input.wvpPosition.y / input.wvpPosition.w * 0.5f + 0.5f;
    
    //float3 view = normalize(input.wPosition - ViewPosition());
    //refraction += refract(view, normalize(input.Normal), 0.15f).xy;
 
    input.Uv.x += (Time * 0.25f);
    float3 normal = NormalMap.Sample(LinearSampler, input.Uv).rgb * 2.0f - 1.0f;
    refraction += normal.xy * 0.05f;
    
    float4 color = RefractionMap.Sample(LinearSampler, refraction);
    
    return float4(color.rgb, 0.75f);
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

    //Refraction Plane
    P_BS_VP(P7, AlphaBlend, VS_Mesh, PS)
}