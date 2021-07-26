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


struct PixelOutput
{
    float4 Color : SV_Target0;
    float4 Color2 : SV_Target1;
};

PixelOutput PS(VertexOutput input)
{
    PixelOutput output;
    
    float3 color = DiffuseMap.Sample(LinearSampler, input.Uv).rgb;
    output.Color = float4(1.0f - color, 1.0f);
    
    
    float grayscale = (color.r + color.g + color.b) / 3.0f;
    output.Color2 = float4(grayscale, grayscale, grayscale, 1.0f);
    
    return output;
}

DepthStencilState Depth
{
    DepthEnable = false;
};

technique11 T0
{
    P_DSS_VP(P0, Depth, VS, PS)
}