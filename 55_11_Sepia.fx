#include "00_Global.fx"
#include "00_Deffered.fx"
#include "00_PostEffect.fx"

float4x4 ColorToSepiaMatrix = float4x4
(
    0.393, 0.769, 0.189, 0,
    0.349, 0.686, 0.168, 0,
    0.272, 0.534, 0.131, 0,
    0, 0, 0, 1
);

float4 PS(VertexOutput_PostEffect input) : SV_Target
{
    float4 color = Maps[0].Sample(LinearSampler, input.Uv);
    
    return mul(ColorToSepiaMatrix, color);
}

technique11 T0
{
    P_VP(P0, VS_PostEffect, PS)
}