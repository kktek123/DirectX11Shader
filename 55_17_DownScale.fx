#include "00_Global.fx"
#include "00_Deffered.fx"
#include "00_PostEffect.fx"

float2 PixelCoordsDownFilter[16] =
{
    float2(+1.5, -1.5), float2(+1.5, -0.5), float2(+1.5, +0.5), float2(+1.5, +1.5),
    float2(+0.5, -1.5), float2(+0.5, -0.5), float2(+0.5, +0.5), float2(+0.5, +1.5),
    float2(-0.5, -1.5), float2(-0.5, -0.5), float2(-0.5, +0.5), float2(-0.5, +1.5),
    float2(-1.5, -1.5), float2(-1.5, -0.5), float2(-1.5, +0.5), float2(-1.5, +1.5),
};

float4 PS(VertexOutput_PostEffect input) : SV_Target
{
    float4 total = 0;
    for (int i = 0; i < 16; i++)
        total += Maps[0].Sample(PointSampler, input.Uv + PixelCoordsDownFilter[i] / float2(1280, 720));
    
    return float4(total.rgb / 16, 1.0f);
}

technique11 T0
{
    P_VP(P0, VS_PostEffect, PS)
}