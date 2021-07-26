#include "00_Global.fx"
#include "00_Deffered.fx"
#include "00_PostEffect.fx"

//Saturation = 0 : grayscale
//0 < Saturation < 1 : desaturation
//Saturation = 1 : original
//Saturation > 1 : satuaration

float4 PS(VertexOutput_PostEffect input) : SV_Target
{
    float3 grayscale = float3(0.2126f, 0.7152f, 0.0722f);
    
    float4 diffuse = Maps[0].Sample(LinearSampler, input.Uv);
    float temp = dot(diffuse.rgb, grayscale);
    
    diffuse.rgb = lerp(temp, diffuse.rgb, PostEffectValue.Saturation);
    diffuse.a = 1.0f;
    
    return diffuse;
}

technique11 T0
{
    P_VP(P0, VS_PostEffect, PS)
}