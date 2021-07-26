#include "00_Global.fx"

struct VertexOutput
{
    float4 Position : Position;
};

VertexOutput VS(Vertex input)
{
    VertexOutput output;
    output.Position = input.Position;

    return output;
}

struct CHullOutput
{
    float Edge[4] : SV_TessFactor;
    float Inside[2] : SV_InsideTessFactor;
};


float2 Distance;
CHullOutput CHS(InputPatch<VertexOutput, 4> input)
{
    float4 position = 0;
    
    [unroll(4)]
    for (int i = 0; i < 4; i++)
        position.xyz += input[i].Position.xyz;
    
    float3 center = position.xyz * 0.25f;
    
    position.w = 1.0f;
    position = WorldPosition(position);
    
    
    float dist = distance(position.xyz, ViewPosition());
    float factor = saturate((Distance.y - dist) / (Distance.y - Distance.x)) * 64;
    
    
    CHullOutput output;
    output.Edge[0] = factor;
    output.Edge[1] = factor;
    output.Edge[2] = factor;
    output.Edge[3] = factor;
    
    output.Inside[0] = factor;
    output.Inside[1] = factor;
    
    return output;
}

struct HullOutput
{
    float4 Position : Position;
};

[domain("quad")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(4)]
[patchconstantfunc("CHS")]
HullOutput HS(InputPatch<VertexOutput, 4> input, uint pointID : SV_OutputControlPointID)
{
    HullOutput output;
    output.Position = input[pointID].Position;
    
    return output;
}

struct DomainOutput
{
    float4 Position : SV_Position;
};

[domain("quad")]
DomainOutput DS(CHullOutput input, const OutputPatch<HullOutput, 4> patch, float2 uv : SV_DomainLocation)
{
    DomainOutput output;
    
    float3 v1 = lerp(patch[0].Position.xyz, patch[1].Position.xyz, 1 - uv.y);
    float3 v2 = lerp(patch[2].Position.xyz, patch[3].Position.xyz, 1 - uv.y);
    float3 position = lerp(v1, v2, uv.x);
    
    output.Position = WorldPosition(float4(position, 1));
    output.Position = ViewProjection(output.Position);

    return output;
}

float4 PS(DomainOutput input) : SV_Target
{
    return float4(1, 0, 0, 1);
}

technique11 T0
{
    P_RS_VTP(P0, FillMode_WireFrame, VS, HS, DS, PS)
}