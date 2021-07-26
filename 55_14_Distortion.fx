#include "00_Global.fx"
#include "00_Deffered.fx"
#include "00_PostEffect.fx"

float4 PS(VertexOutput_PostEffect input) : SV_Target
{
    float2 uv = input.Uv * 2 - 1;
    
    float2 vpSize = float2(1.0f / PixelSize.x, 1.0f / PixelSize.y);
    float aspect = vpSize.x / vpSize.y;
    float radiusSquared = aspect * aspect * uv.x * uv.x + uv.y * uv.y;
    float radius = sqrt(radiusSquared);

    float3 f = PostEffectValue.Distortion * pow(abs(radius + 0.0001f), PostEffectValue.LensPower) + 1;
    
    float2 r = (f.r * uv + 1) * 0.5f;
    float2 g = (f.g * uv + 1) * 0.5f;
    float2 b = (f.b * uv + 1) * 0.5f;
    
    float4 color = 0;
    color.r = Maps[0].Sample(LinearSampler, r).r;
    color.ga = Maps[0].Sample(LinearSampler, g).ga;
    color.b = Maps[0].Sample(LinearSampler, b).b;
    
    return color;
}

technique11 T0
{
    P_VP(P0, VS_PostEffect, PS)
}