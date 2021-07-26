#include "00_Global.fx"
#include "00_Light.fx"
#include "00_Render.fx"
#include "00_Terrain.fx"
#include "00_Deffered.fx"
#include "00_PostEffect.fx"

float4 PS(VertexOutput_PostEffect input) : SV_Target
{
    return Maps[0].Sample(LinearSampler, input.Uv);
}

technique11 T0
{
    P_VP(P0, VS_PostEffect, PS)
}