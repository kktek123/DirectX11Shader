#include "00_Global.fx"
#include "00_Deffered.fx"
#include "00_PostEffect.fx"

float4 PS(VertexOutput_PostEffect input) : SV_Target
{
    float4 color = 0;
    
    for (int i = 0; i < BlurCount; i++)
    {
        float2 uv = float2(0, i - 6) * PixelSize;
        color += Maps[0].Sample(LinearSampler, input.Uv + uv) * BlurWeights[i];
    }
        
    
    return color;
}

technique11 T0
{
    P_VP(P0, VS_PostEffect, PS)
}