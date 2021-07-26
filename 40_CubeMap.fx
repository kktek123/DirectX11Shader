#include "00_Global.fx"
#include "00_Light.fx"
#include "00_Render.fx"
#include "00_Sky.fx"

float4 PS(MeshOutput input) : SV_Target
{
    return PS_Shadow(input.sPosition, PS_AllLight(input));
}

///////////////////////////////////////////////////////////////////////////////
// CubeMap
///////////////////////////////////////////////////////////////////////////////
cbuffer CB_DynamicCube
{
    matrix CubeViews[6];
    matrix CubeProjection;
    uint CubeRenderType;
};

[maxvertexcount(18)]
void GS_PreRender(triangle MeshOutput input[3], inout TriangleStream<MeshGeometryOutput> stream)
{
    int vertex = 0;
    MeshGeometryOutput output;
    
    [unroll(6)]
    for (int i = 0; i < 6; i++)
    {
        output.TargetIndex = i;
        
        [unroll(3)]
        for (vertex = 0; vertex < 3; vertex++)
        {
            output.Position = mul(input[vertex].gPosition, CubeViews[i]);
            output.Position = mul(output.Position, CubeProjection);
            output.wvpPosition = output.Position;
            output.wvpPosition_Sub = output.Position;
            
            output.wPosition = input[vertex].wPosition;
            output.sPosition = input[vertex].sPosition;
            output.oPosition = input[vertex].oPosition;
            output.gPosition = input[vertex].gPosition;
            output.Normal = input[vertex].Normal;
            output.Tangent = input[vertex].Tangent;
            output.Uv = input[vertex].Uv;
            
            stream.Append(output);
        }

        stream.RestartStrip();
    }
}

float4 PS_PreRender_Sky(MeshGeometryOutput input) : SV_Target
{
    return PS_Sky(ConvertMeshOutput(input));
}

float4 PS_PreRender(MeshGeometryOutput input) : SV_Target
{
    return PS_Shadow(input.sPosition, PS_AllLight(ConvertMeshOutput(input)));
}

TextureCube DynamicCubeMap;


float Amount = 1.0f;
float Bias = 1.0f;
float Scale = 1.0f;
float4 PS_Cube(MeshOutput input) : SV_Target
{
    float3 normal = normalize(input.Normal);
    float3 view = normalize(input.wPosition - ViewPosition());
    float3 reflection = reflect(view, normal);
    
    
    float ratio = 1.52f;
    float3 refraction = refract(normalize(view), normal, ratio);
    
    float4 color = 0;
    color.a = 1.0f;
    
    float4 diffuse = 0;
    
    if (CubeRenderType == 0)
    {
        color = DynamicCubeMap.Sample(LinearSampler, input.oPosition);
    }
    else if (CubeRenderType == 1)
    {
        color = DynamicCubeMap.Sample(LinearSampler, reflection);
    }
    else if (CubeRenderType == 2)
    {
        color = DynamicCubeMap.Sample(LinearSampler, refraction);
        color.a = 0.75f;
    }
    else if (CubeRenderType == 3)
    {
        diffuse = PS_AllLight(input);
        color = DynamicCubeMap.Sample(LinearSampler, reflection);
        
        color.rgb *= (0.15f + diffuse * 0.95f);
    }
    else if (CubeRenderType == 4)
    {
        diffuse = PS_AllLight(input);
        color = DynamicCubeMap.Sample(LinearSampler, reflection);
        
        float4 fresnel = Bias + (1.0f - Scale) * pow(abs(1.0f - dot(view, normal)), Amount);
        color = Amount * diffuse + lerp(diffuse, color, fresnel);
        color.a = 1.0f;
    }

    return color;
}


technique11 T0
{
    //Sky
    P_RS_DSS_VP(P0, FrontCounterClockwise_True, DepthEnable_False, VS_Mesh, PS_Sky)

    //Depth 
    P_RS_VP(P1, FrontCounterClockwise_True, VS_Depth_Mesh, PS_Depth)
    P_RS_VP(P2, FrontCounterClockwise_True, VS_Depth_Model, PS_Depth)
    P_RS_VP(P3, FrontCounterClockwise_True, VS_Depth_Animation, PS_Depth)

    //Render
    P_VP(P4, VS_Mesh, PS)
    P_VP(P5, VS_Model, PS)
    P_VP(P6, VS_Animation, PS)

    
    //Cube PreRender    
    P_RS_DSS_VGP(P7, FrontCounterClockwise_True, DepthEnable_False, VS_Mesh, GS_PreRender, PS_PreRender_Sky)
    P_VGP(P8, VS_Mesh, GS_PreRender, PS_PreRender)
    P_VGP(P9, VS_Model, GS_PreRender, PS_PreRender)
    P_VGP(P10, VS_Animation, GS_PreRender, PS_PreRender)

    P_BS_VP(P11, AlphaBlend, VS_Mesh, PS_Cube)
    P_BS_VP(P12, AlphaBlend, VS_Model, PS_Cube)
    P_BS_VP(P13, AlphaBlend, VS_Animation, PS_Cube)
}