#include "00_Global.fx"
#include "00_Light.fx"

float4 Color;

struct VertexInput
{
    float4 Position : Position;
    float3 Normal : Normal;
};

struct VertexOutput
{
    float4 Position : SV_Position;
    float3 Normal : Normal;
};

VertexOutput VS(VertexInput input)
{
    VertexOutput output;
    output.Position = mul(input.Position, World);    
    output.Position = mul(output.Position, View);
    output.Position = mul(output.Position, Projection);
    
    output.Normal = mul(input.Normal, (float3x3) World);
    
    return output;
}

float4 PS(VertexOutput input) : SV_Target
{
    float NdotL = dot(-GlobalLight.Direction, normalize(input.Normal));
    
    return Color * NdotL;
}

RasterizerState RS
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
        SetRasterizerState(RS);

        SetVertexShader(CompileShader(vs_5_0, VS()));
        SetPixelShader(CompileShader(ps_5_0, PS()));
    }
}