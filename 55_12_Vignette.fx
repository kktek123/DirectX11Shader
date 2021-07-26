#include "00_Global.fx"
#include "00_Deffered.fx"
#include "00_PostEffect.fx"

//Power
//1 : Linear
//>1 : Non-Linear

float4 PS(VertexOutput_PostEffect input) : SV_Target
{
    float4 color = Maps[0].Sample(LinearSampler, input.Uv);
    
    float radius = length((input.Uv - 0.5f) * 2 / PostEffectValue.VignetteScale);
    float vignette = pow(abs(radius + 0.0001f), PostEffectValue.VignettePower);
    
    return saturate(1 - vignette) * color;
}

technique11 T0
{
    P_VP(P0, VS_PostEffect, PS)
}