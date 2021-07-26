#include "00_Global.fx"
#include "00_Deffered.fx"
#include "00_PostEffect.fx"

float3 Luminance = { 0.2125f, 0.7154f, 0.0721f };

float3 PixelKernel[9] =
{
    float3(-1, -1, -1), float3(+0, -1, -1), float3(+1, -1, -1),
    float3(-1, +0, -1), float3(+0, +0, +8), float3(+1, +0, -1),
    float3(-1, +1, -1), float3(+0, +1, -1), float3(+1, +1, -1),
};

float4 PS(VertexOutput_PostEffect input) : SV_Target
{
    float4 total = 0;
    for (int i = 0; i < 9; i++)
    {
        float3 temp = PixelKernel[i];
        temp.xy *= PixelSize;
        
        float2 uv = input.Uv + temp.xy;
        total += Maps[0].Sample(LinearSampler, uv) * temp.z;
    }
    
    float gray = dot(Luminance, total.rgb);
    gray *= PostEffectValue.Laplacian;
    
    return float4(gray, gray, gray, 1.0f);
}

//float2 PixelKernel[4] = { { 0, 1 }, { 1, 0 }, { 0, -1 }, { -1, 0 } };
//float4 PS(VertexOutput_PostEffect input) : SV_Target
//{
//    float4 color = Maps[0].Sample(LinearSampler, input.Uv);
    
//    float4 total = 0;
//    for (int i = 0; i < 4; i++)
//    {
//        float2 uv = PixelKernel[i] * PixelSize;
//        total += (abs(color - Maps[0].Sample(LinearSampler, input.Uv + uv)) - 0.5f) * 1.2f + 0.5f;
//    }
        
//    return saturate(dot(Luminance, total.rgb)) * 5.0f;
//}

technique11 T0
{
    P_VP(P0, VS_PostEffect, PS)
}