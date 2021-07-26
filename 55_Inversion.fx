#include "00_Global.fx"
#include "00_Deffered.fx"
#include "00_PostEffect.fx"

float4 PS(VertexOutput_PostEffect input) : SV_Target
{
    float4 color = Maps[0].Sample(LinearSampler, input.Uv);
    
    return float4(1.0f - color.rgb, 1.0f);
}

technique11 T0
{
    P_VP(P0, VS_PostEffect, PS)
}