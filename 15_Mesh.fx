#include "00_Global.fx"
#include "00_Light.fx"
#include "00_Render.fx"

float4 PS(MeshOutput input) : SV_Target
{
    float3 diffuse = DiffuseMap.Sample(LinearSampler, input.Uv).rgb;
    float NdotL = dot(-GlobalLight.Direction, normalize(input.Normal));
    
    return float4(diffuse * NdotL, 1);
}

technique11 T0
{
    P_VP(P0, VS_Mesh, PS)
}