#include "00_Global.fx"
#include "00_Light.fx"

cbuffer CB_Render2D
{
    matrix View2D;
    matrix Projection2D;
};

struct VertexOutput
{
    float4 Position : SV_Position0;
    float2 Uv : Uv0;
};

VertexOutput VS(VertexTexture input)
{
    VertexOutput output;

    output.Position = WorldPosition(input.Position);
    output.Position = mul(output.Position, View2D);
    output.Position = mul(output.Position, Projection2D);
    output.Uv = input.Uv;

    return output;
}

float4 PS(VertexOutput input) : SV_TARGET0
{
    //return 1.0f - DiffuseMap.Sample(LinearSampler, input.Uv);
    
    float3 color = DiffuseMap.Sample(LinearSampler, input.Uv).rgb;
    
    //float grayscale = (color.r + color.g + color.b) / 3.0f;
    //return float4(grayscale, grayscale, grayscale, 1.0f);
    
    color.r = color.r * 0.1f;
    color.g = color.g * 0.25f;
    return float4(color, 1.0f);
}

DepthStencilState Depth
{
    DepthEnable = false;
};

technique11 T0
{
    P_DSS_VP(P0, Depth, VS, PS)
}