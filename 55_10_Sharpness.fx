#include "00_Global.fx"
#include "00_Deffered.fx"
#include "00_PostEffect.fx"

float4 PS(VertexOutput_PostEffect input) : SV_Target
{
    float4 center = Maps[0].Sample(LinearSampler, input.Uv);
    float4 top = Maps[0].Sample(LinearSampler, input.Uv + float2(0, -PixelSize.y));
    float4 bottom = Maps[0].Sample(LinearSampler, input.Uv + float2(0, +PixelSize.y));
    float4 left = Maps[0].Sample(LinearSampler, input.Uv + float2(-PixelSize.x, 0));
    float4 right = Maps[0].Sample(LinearSampler, input.Uv + float2(+PixelSize.x, 0));
    
    float4 edge = center * 4 - left - right - top - bottom;
    
    return center + PostEffectValue.Sharpness * edge;
}

technique11 T0
{
    P_VP(P0, VS_PostEffect, PS)
}