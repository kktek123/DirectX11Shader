#include "00_Global.fx"
#include "00_Deffered.fx"
#include "00_PostEffect.fx"

float4 PS(VertexOutput_PostEffect input) : SV_Target
{
    float4 color = Maps[0].Sample(LinearSampler, input.Uv);
    
    float height = 1.0f / PixelSize.y;
    
    int value = (int) ((floor(input.Uv.y * height) % PostEffectValue.InteraceValue) / (PostEffectValue.InteraceValue / 2));
    
    [flatten]
    if (value)
    {
        float3 grayScale = float3(0.2126f, 0.7152f, 0.0722f);
        float luminance = dot(color.rgb, grayScale);
        
        luminance = min(0.999f, luminance);
        
        color.rgb = lerp(color.rgb, color.rgb * luminance, PostEffectValue.InteraceStrength);
    }
    return color;
}

technique11 T0
{
    P_VP(P0, VS_PostEffect, PS)
}