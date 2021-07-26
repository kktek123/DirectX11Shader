#include "00_Global.fx"
#include "00_Light.fx"

struct VertexOutput
{
    float4 Position : SV_Position;
    float2 Uv : Uv;
    float3 Normal : Normal;
};

VertexOutput VS_Mesh(VertexTextureNormal input)
{
    VertexOutput output;
    output.Position = mul(input.Position, World);
    output.Position = mul(output.Position, View);
    output.Position = mul(output.Position, Projection);
    
    output.Normal = mul(input.Normal, (float3x3) World);
    output.Uv = input.Uv;
    
    return output;
}

float4 PS_Mesh(VertexOutput input) : SV_Target
{
    float3 diffuse = DiffuseMap.Sample(LinearSampler, input.Uv).rgb;
    float NdotL = dot(-GlobalLight.Direction, normalize(input.Normal));
    
    return float4(diffuse * NdotL, 1);
}

struct VertexCubeOutput
{
    float4 Position : SV_Position;
    float3 oPosition : Position1;
    float3 wPosition : Position2;
    float3 Normal : Normal;
};

VertexCubeOutput VS(VertexNormal input)
{
    VertexCubeOutput output;
    output.Position = mul(input.Position, World);    
    output.wPosition = output.Position;
    
    output.Position = mul(output.Position, View);
    output.Position = mul(output.Position, Projection);
    
    output.oPosition = input.Position.xyz;
    
    output.Normal = mul(input.Normal, (float3x3) World);
    
    return output;
}

TextureCube CubeMap;
float4 PS(VertexCubeOutput input) : SV_Target
{
    float3 view = normalize(input.wPosition - ViewPosition());
    float3 normal = normalize(input.Normal);
    float3 r = reflect(view, normal);
    
    float4 diffuse = CubeMap.Sample(LinearSampler, input.oPosition);
    //float4 diffuse = CubeMap.Sample(LinearSampler, r);
    
    return diffuse;
}

technique11 T0
{
    P_VP(P0, VS_Mesh, PS_Mesh)
    P_VP(P1, VS, PS)
}