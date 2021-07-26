#include "00_Global.fx"
#include "00_Light.fx"

struct VertexOutput
{
    float4 Position : SV_Position0;
    float2 Uv : Uv0;
    float3 Normal : Normal0;
};

VertexOutput VS(VertexTextureNormal input)
{
    VertexOutput output;
    output.Position = WorldPosition(input.Position);
    output.Position = ViewProjection(output.Position);
    output.Normal = WorldNormal(input.Normal);
    output.Uv = input.Uv;

    return output;
}

float4 PS(VertexOutput input) : SV_Target0
{
    float4 diffuse = DiffuseMap.Sample(LinearSampler, input.Uv);

    float3 normal = normalize(input.Normal);
    float NdotL = dot(normal, -GlobalLight.Direction);

    return diffuse * NdotL;
}

RasterizerState Fill
{
    FillMode = Wireframe;
};

technique11 T0
{
    pass P0
    {
        SetVertexShader(CompileShader(vs_5_0, VS()));
        SetPixelShader(CompileShader(ps_5_0, PS()));
    }
    
    pass P1
    {
        SetRasterizerState(Fill);

        SetVertexShader(CompileShader(vs_5_0, VS()));
        SetPixelShader(CompileShader(ps_5_0, PS()));
    }
}