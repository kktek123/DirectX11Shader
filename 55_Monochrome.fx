#include "00_Global.fx"
#include "00_Deffered.fx"
#include "00_PostEffect.fx"

float3 Luminance = { 0.2125f, 0.7154f, 0.0721f };
float4 PS(VertexOutput_PostEffect input) : SV_Target
{
    float4 color = Maps[0].Sample(LinearSampler, input.Uv);
    
    return dot(color.rgb, Luminance);
}

technique11 T0
{
    P_VP(P0, VS_PostEffect, PS)
}