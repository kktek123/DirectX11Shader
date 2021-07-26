#include "00_Global.fx"
#include "00_Light.fx"
#include "00_Render.fx"
#include "00_Terrain.fx"
#include "00_Deffered.fx"
#include "00_Water.fx"
#include "00_Sky.fx"
#include "000_LOD.fx"
//#include "000_Render2D.fx"
float4 PS(MeshOutput input) : SV_Target
{
    return PS_Shadow(input.sPosition, PS_AllLight(input));
   // return PS_AllLight(input);

}



struct DomainOutput_TerrainLOD
{
    //float4 Position : SV_Position0; //Rasterizing Position
    //float3 oPosition : Position3; //Original Position
    //float3 wPosition : Position4; //World Position(XYZ)
    //float4 sPosition : Position5; //Shadow Position
    //float4 gPosition : Position6; //Geometry Position

    //float2 Uv : Uv0;
    //float3 Normal : Normal0;
    //float3 Tangent : Tangent0;

    //float4 Clip : SV_ClipDistance0;
    
    float4 Position : SV_Position0;
    float4 wvpPosition : Position1; //WVP
    float4 wvpPosition_Light : Position2; //WVP - Projector
    float3 oPosition : Position3;
    float3 wPosition : Position4;
    float4 sPosition : Position5; //Shadow Position
    float4 gPosition : Position6; //Geometry Position
    float2 Uv : Uv0;
    float2 DetailUv : Uv1;
    
    float4 Clip : SV_ClipDistance; //x - used
};



[domain("quad")]
DomainOutput_TerrainLOD DS_TerrainLOD
(
    CHullOutput_TerrainLod hinput, float2 uv : SV_DomainLocation,
    OutputPatch<HullOutput_TerrainLod, 4> patch //, uint patchID : SV_PrimitiveID
)
{
    DomainOutput_TerrainLOD output;

    float3 p0 = lerp(patch[0].Position, patch[1].Position, uv.x).xyz;
    float3 p1 = lerp(patch[2].Position, patch[3].Position, uv.x).xyz;
    float4 position = float4(lerp(p0, p1, uv.y), 1);

    float2 uv0 = lerp(patch[0].Uv, patch[1].Uv, uv.x);
    float2 uv1 = lerp(patch[2].Uv, patch[3].Uv, uv.x);
    output.Uv = lerp(uv0, uv1, uv.y);

    position.y = HeightMap.SampleLevel(LinearSampler, output.Uv, 0).r * 255 / TerrainHeightRatio;

    DS_GENERATE
    
    output.DetailUv = output.Uv * 100 - 10 * (int) output.Uv;
    //output.Clip = dot(WorldPosition(position), Clipping);
    VS_Projector(output.wvpPosition_Light, position);
    return output;
}


[domain("quad")]
DomainOutput_TerrainLOD DS_Reflect_TerrainLOD
(
    CHullOutput_TerrainLod hinput, float2 uv : SV_DomainLocation,
    OutputPatch<HullOutput_TerrainLod, 4> patch //, uint patchID : SV_PrimitiveID
)
{
    DomainOutput_TerrainLOD output;

    float3 p0 = lerp(patch[0].Position, patch[1].Position, uv.x).xyz;
    float3 p1 = lerp(patch[2].Position, patch[3].Position, uv.x).xyz;
    float4 position = float4(lerp(p0, p1, uv.y), 1);

    float2 uv0 = lerp(patch[0].Uv, patch[1].Uv, uv.x);
    float2 uv1 = lerp(patch[2].Uv, patch[3].Uv, uv.x);
    output.Uv = lerp(uv0, uv1, uv.y);

    position.y = HeightMap.SampleLevel(LinearSampler, output.Uv, 0).r * 255 / TerrainHeightRatio;
    
    DS_GENERATE
    
    output.DetailUv = output.Uv * 100 - 10 * (int) output.Uv;
    matrix reflection = mul(World, mul(Reflection, Projection));
    output.Position = mul(position, reflection);
    VS_Projector(output.wvpPosition_Light, position);
    return output;
}
float4 TerrainPixelShader(DomainOutput_TerrainLOD input)
{
    float slope;
    float4 color;
    float3 lightDir;
    float4 texColor1;
    float4 texColor2;
    float4 bumpMap;
    float3 bumpNormal;
    float4 material1;
    float4 material2;
    float blendAmount;
    
    return color;

}

float4 PS_Shadow(DomainOutput_TerrainLOD input, float4 color)
{
    input.sPosition.xyz /= input.sPosition.w;

    [flatten]
    if (input.sPosition.x < -1.0f || input.sPosition.x > 1.0f ||
        input.sPosition.y < -1.0f || input.sPosition.y > 1.0f ||
        input.sPosition.z < 0.0f || input.sPosition.z > 1.0f)
        return color;

    input.sPosition.x = input.sPosition.x * 0.5f + 0.5f;
    input.sPosition.y = -input.sPosition.y * 0.5f + 0.5f;
    input.sPosition.z -= ShadowBias;

    
    float depth = input.sPosition.z;;
    float factor = 0.0f;

    float2 size = 1.0f / ShadowMapSize;
    float2 offsets[] =
    {
        float2(-size.x, -size.y), float2(0.0f, -size.y), float2(+size.x, -size.y),
        float2(-size.x, 0.0f), float2(0.0f, 0.0f), float2(+size.x, 0.0f),
        float2(-size.x, +size.y), float2(0.0f, +size.y), float2(+size.x, +size.y),
    };

    float2 uv = 0;
    float sum = 0;
        
    [unroll(9)]
    for (int i = 0; i < 9; i++)
    {
        uv = input.sPosition.xy + offsets[i];
        sum += ShadowMap.SampleCmpLevelZero(ShadowSampler, uv, depth).r;
    }

    factor = sum / 9.0f;
    factor = saturate(factor + depth);

    return float4(color.rgb * factor, 1);
}

float4 PS_TerrainLOD(DomainOutput_TerrainLOD input) : SV_Target
{
    float2 left = input.Uv + float2(-TexelCellSpaceU, 0.0f);
    float2 right = input.Uv + float2(+TexelCellSpaceU, 0.0f);
    float2 top = input.Uv + float2(0.0f, -TexelCellSpaceV);
    float2 bottom = input.Uv + float2(0.0f, TexelCellSpaceV);

    float leftY = HeightMap.SampleLevel(LinearSampler, left, 0).r * 255 / TerrainHeightRatio;
    float rightY = HeightMap.SampleLevel(LinearSampler, right, 0).r * 255 / TerrainHeightRatio;
    float topY = HeightMap.SampleLevel(LinearSampler, top, 0).r * 255 / TerrainHeightRatio;
    float bottomY = HeightMap.SampleLevel(LinearSampler, bottom, 0).r * 255 / TerrainHeightRatio;

    float3 tangent = normalize(float3(WorldCellSpace * 2.0f, rightY - leftY, 0.0f));
    float3 biTangent = normalize(float3(0.0f, bottomY - topY, WorldCellSpace * -2.0f));
    float3 normal = normalize(cross(tangent, biTangent));
    
    float slope;
    float4 color;
    float3 lightDir;
    float4 texColor1;
    float4 texColor2;
    float4 bumpMap;
    float4 bumpMap2;
    
    float3 bumpNormal;
    float lightIntensity;
    float4 material1;
    float4 material2;
    float blendAmount;
    
    //Texture(Material.Diffuse, DiffuseMap, input.Uv);
    Material.Diffuse = GetLayerColor(input.Uv);
    //NormalMapping(input.Uv, normal, tangent);
    //Texture(Material.Specular, SpecularMap, input.Uv);

    float4 scolor = Material.Diffuse;
    
    float depth = input.wvpPosition.z / input.wvpPosition.w;

   //
    slope = 1.0f - normal.y;
    lightDir = -GlobalLight.Direction;
    //texColor1 = DiffuseMap.Sample(LinearSampler, input.TiledUv);
    texColor1 = Material.Diffuse;
    SetDetailTexture(texColor1, DetailMap, input.DetailUv, depth);
    material1 = texColor1;
    
    texColor2 = SnowMap.Sample(LinearSampler, input.DetailUv);
    SetDetailTexture(texColor2, SnowMap, input.DetailUv, depth);
    material2 = texColor2;
    if (slope < 0.99)
    {
        blendAmount = slope / 0.2f;
        color = lerp(material2, material1, blendAmount);
         [branch]
        if (depth < 0.9996f)
            NormalMapping(input.DetailUv, normal, tangent);
        if (depth > 0.9996f)
            NormalMapping(input.Uv, DistanceMap, normal, tangent);

    }
    if (slope >= 0.2)
    {
        color = material1;
         [branch]
        if (depth < 0.9996f)
            NormalMapping(input.DetailUv, normal, tangent);
        if (depth > 0.9996f)
            NormalMapping(input.Uv, DistanceMap, normal, tangent);
    }
    
    Material.Diffuse = saturate(color);
    
    MaterialDesc output = MakeMaterial();
    MaterialDesc result = MakeMaterial();
    ComputeLight(output, normal, input.wPosition);
    AddMaterial(result, output);

    ComputePointLight(output, normal, input.wPosition);
    AddMaterial(result, output);
    
    ComputeSpotLight(output, normal, input.wPosition);
    AddMaterial(result, output);

    //ComputeCapsuleLights(output, normal, input.wPosition);
    //AddMaterial(result, output);
    
    float4 lightColor = float4(MaterialToColor(result), 1.0f);
    lightColor = CalculateFogColor(lightColor, input.wPosition);
 
    PS_Projector(lightColor, input.wvpPosition_Light);

    Material.Diffuse = saturate(float4(lightColor.rgb, 1.0f));
    
    return Material.Diffuse;
    //return PS_Shadow(input.sPosition, Material.Diffuse);
    
   // return float4(normal, 1);
}
PixelOutput_GBuffer PS_PackGBufferLod(DomainOutput_TerrainLOD input)
{
    float2 left = input.Uv + float2(-TexelCellSpaceU, 0.0f);
    float2 right = input.Uv + float2(+TexelCellSpaceU, 0.0f);
    float2 top = input.Uv + float2(0.0f, -TexelCellSpaceV);
    float2 bottom = input.Uv + float2(0.0f, TexelCellSpaceV);

    float leftY = HeightMap.SampleLevel(LinearSampler, left, 0).r * 255 / TerrainHeightRatio;
    float rightY = HeightMap.SampleLevel(LinearSampler, right, 0).r * 255 / TerrainHeightRatio;
    float topY = HeightMap.SampleLevel(LinearSampler, top, 0).r * 255 / TerrainHeightRatio;
    float bottomY = HeightMap.SampleLevel(LinearSampler, bottom, 0).r * 255 / TerrainHeightRatio;

    float3 tangent = normalize(float3(WorldCellSpace * 2.0f, rightY - leftY, 0.0f));
    float3 biTangent = normalize(float3(0.0f, bottomY - topY, WorldCellSpace * -2.0f));
    float3 normal = normalize(cross(tangent, biTangent));
    
    float slope;
    float4 color;
    float3 lightDir;
    float4 texColor1;
    float4 texColor2;
    float4 bumpMap;
    float4 bumpMap2;
    
    float3 bumpNormal;
    float lightIntensity;
    float4 material1;
    float4 material2;
    float blendAmount;
    //NormalMapping(input.Uv, normal, tangent);
 
    Texture(Material.Diffuse, DiffuseMap, input.Uv); //diffuse샘플링
    Material.Diffuse = GetLayerColor(input.Uv);
    //Texture(Material.Specular, SpecularMap, input.Uv); //Specular
    //NormalMapping(input.Uv, normal, tangent);
    //Texture(Material.Specular, SpecularMap, input.Uv);

    float4 scolor = Material.Diffuse;
    
    float depth = input.wvpPosition.z / input.wvpPosition.w;

   //
    slope = 1.0f - normal.y;
    lightDir = -GlobalLight.Direction;
    //texColor1 = DiffuseMap.Sample(LinearSampler, input.TiledUv);
   
    
    //[branch]
    //if (depth > 0.995f)
    //    NormalMapping(input.Uv, DistanceMap, normal, tangent);
    
    [branch]
    if (depth > 0.999f)
        NormalMapping(input.Uv, normal, tangent);
    if (depth < 0.999f)
        NormalMapping(input.DetailUv, DistanceMap, normal, tangent);
    if (depth < 0.996f)
        NormalMapping(input.DetailUv, normal, tangent);
    
    texColor1 = Material.Diffuse;
    SetDetailTexture(texColor1, DetailMap, input.DetailUv, depth);
    material1 = mul(texColor1, texColor1);
    
    texColor2 = float4(1, 1, 1, 1);
    //texColor2 = SnowMap.Sample(LinearSampler, input.DetailUv);
    //
    SetNormalMapping(texColor2, input.Uv, SnowMap, normal, tangent);
    //SetDetailTexture(texColor2, SnowMap, input.DetailUv, depth);
    material2 = texColor2;
    
    if (slope < 0.2)
    {
        blendAmount = slope / 0.2f;
        color = lerp(material2, material1, blendAmount);
        
         [branch]
        if (depth < 0.996f)
            SetNormalMapping(color, input.DetailUv, SnowMap, normal, tangent);

    }
    if (slope >= 0.2)
    {
        color = material1;
   
    }
    color = CalculateFogColor(color, input.wPosition);
 
    PS_Projector(color, input.wvpPosition_Light);
    Material.Diffuse = color;
    
    PixelOutput_GBuffer output;
    output.Diffuse = PS_Shadow(input.sPosition, float4(Material.Diffuse.rgb, 1));
    output.Specular = float4(Material.Specular.r, Material.Specular.g*0.7, Material.Specular.b, 1);
    output.Emissive = float4(Material.Emissive.rgb, 0.5);
    output.Normal = float4(normal, 1);
    output.Tangent = float4(tangent, 1);
    
    return output;
}

PixelOutput_GBuffer PS_PackGBufferLoTerrain(VertexTerrain input) : SV_Target0
{

    float3 tangent = input.Tangent;
    //float3 biTangent = normalize(float3(0.0f, bottomY - topY, WorldCellSpace * -2.0f));
    float3 normal = input.Normal;
    float NdotL = dot(normal, -GlobalLight.Direction);
    float4 brushColor = GetBrushColor(input.wPosition);
    float4 lineColor = GetLineColor(input.wPosition);
    float slope;
    float4 color;
    float3 lightDir;
    float4 texColor1;
    float4 texColor2;
    float4 bumpMap;
    float4 bumpMap2;
    
    float3 bumpNormal;
    float lightIntensity;
    float4 material1;
    float4 material2;
    float blendAmount;
    //NormalMapping(input.Uv, normal, tangent);
 
    Texture(Material.Diffuse, DiffuseMap, input.Uv); //diffuse샘플링
    Texture(Material.Specular, SpecularMap, input.Uv); //Specular
    Material.Diffuse = GetLayerColor(input.Uv);
    //NormalMapping(input.Uv, normal, tangent);
    //Material.Diffuse = (Material.Diffuse * NdotL) + brushColor + lineColor;
    float4 scolor = Material.Diffuse;
    
    float depth = input.wvpPosition.z / input.wvpPosition.w;

   //
    slope = 1.0f - normal.y;
    lightDir = -GlobalLight.Direction;
    //texColor1 = DiffuseMap.Sample(LinearSampler, input.TiledUv);
   
    
    //[branch]
    //if (depth > 0.995f)
    //    NormalMapping(input.Uv, DistanceMap, normal, tangent);
    //    [branch]
    //if (depth > 0.999f)
    //    NormalMapping(input.Uv, normal, tangent);
    //if (depth < 0.999f && depth >= 0.996f)
    //    NormalMapping(input.detailUv, DistanceMap, normal, tangent);
    //if (depth < 0.996f)
    //    NormalMapping(input.detailUv, normal, tangent);
    
    [flatten]
    if (depth >= 0.9995f)
        NormalMapping(input.Uv, normal, tangent);
    if (depth < 0.9995f)
        NormalMapping(input.detailUv, normal, tangent);
    
    texColor1 = Material.Diffuse;
    SetDetailTexture(texColor1, DetailMap, input.detailUv, depth);
    material1 = mul(texColor1, texColor1);
    
    texColor2 = float4(1, 1, 1, 1);
    //texColor2 = SnowMap.Sample(LinearSampler, input.detailUv);
    //SetNormalMapping(texColor2, input.Uv, SnowMap, normal, tangent);
    //SetDetailTexture(texColor2, SnowMap, input.detailUv, depth);
    //SetDetailTexture(texColor2, SnowMap, input.detailUv, depth);
    material2 = texColor2;
    
    if (slope < 0.1)
    {
        blendAmount = slope / 0.9;
        color = lerp(material2, material1, blendAmount);
        
          [flatten]
        if (depth < 0.9995f)
            SetNormalMapping(color, input.detailUv, SnowMap, normal, tangent);
        //[branch]
        //if (depth < 0.9995f)
        //    SetNormalMapping(color, input.detailUv, SnowMap, normal, tangent);
       // SetDetailTexture(texColor2, SnowMap, input.detailUv, depth);

    }
    else if (slope >= 0.1)
    {
        color = material1;
    
      [flatten]
        if (depth < 0.9995f)//  && depth <= 0.999f)
            NormalMapping(input.detailUv, DistanceMap, normal, tangent);
   
    }
    
    //float as = 0.2;
    //if (slope <= as)
    //{
    //    blendAmount = slope / 0.9;
        
    //    color = lerp(material1, material2, blendAmount);
        
    //    //  [branch]
    //    //if (depth < 0.9999f)
    //    //    NormalMapping(input.detailUv, DistanceMap, normal, tangent);
  
    //    //SetDetailTexture(texColor2, SnowMap, input.detailUv, depth);

    //}
    //if (slope > as)
    //{
    //    color = material1;
      
    //    // [branch]
    //    //if (depth < 0.9999f)
    //    //    SetNormalMapping(color, input.detailUv, SnowMap, normal, tangent);
    //}
    color = CalculateFogColor(color, input.wPosition);
 
    //PS_Projector(color, input.wvpPosition_Sub);
    Material.Diffuse = color;
    
    //normal = mul(normal, mul(normal, normal));
    //tangent = mul(tangent, tangent);
    PixelOutput_GBuffer output;
    output.Diffuse = PS_Shadow(input.sPosition, float4(Material.Diffuse.rgb, 1));
    //output.Specular = float4(Material.Specular.r, Material.Specular.g*0.7, Material.Specular.b, 0.1);
    output.Emissive = float4(Material.Emissive.rgb, 0);
    output.Normal = float4(normal, 1);
    output.Tangent = float4(tangent, 1);
    
    return output;
}


PixelOutput_GBuffer PS_WaterGbuffer(VertexOutput_Water input) : SV_Target
{
    //input.Uv.y += WaveTranslation;
    //input.Uv2.x += WaveTranslation;
    
    float4 normalMap = NormalMap.Sample(LinearSampler, input.Uv) * 2.0f - 1.0f;
    float4 normalMap2 = NormalMap.Sample(LinearSampler, input.Uv2) * 2.0f - 1.0f;
    float3 normal = normalMap.rgb + normalMap2.rgb;
    
    float2 reflection;
    reflection.x = input.ReflectionPosition.x / input.ReflectionPosition.w * 0.5f + 0.5f;
    reflection.y = -input.ReflectionPosition.y / input.ReflectionPosition.w * 0.5f + 0.5f;
    reflection += normal.xy * WaveScale;
    float4 reflectionColor = ReflectionMap.Sample(LinearSampler, reflection);
    
    float2 refraction;
    refraction.x = input.RefractionPosition.x / input.RefractionPosition.w * 0.5f + 0.5f;
    refraction.y = -input.RefractionPosition.y / input.RefractionPosition.w * 0.5f + 0.5f;
    refraction += normal.xy * WaveScale;
    float4 refractionColor = saturate(RefractionMap.Sample(LinearSampler, refraction) + RefractionColor);
    
    
    float3 light = GlobalLight.Direction;
    light.y *= -1.0f;
    light.z *= -1.0f;
    
    float3 view = normalize(ViewPosition() - input.wPosition);
    float3 heightView = view.yyy;
    
    float r = (1.2f - 1.0f) / (1.2f / 1.0f);
    float fresnel = saturate(min(1, r + (1 - r) * pow(1 - dot(normal, heightView), 2)));
    float4 diffuse = lerp(reflectionColor, refractionColor, fresnel);
    
    
    float3 R = normalize(reflect(light, normal));
    float specular = saturate(dot(R, view));
    
    [flatten]
    if (specular > 0.0f)
    {
        specular = pow(specular, WaterShininess);
        diffuse = saturate(diffuse + specular);
    }
    
    PixelOutput_GBuffer output;
    output.Diffuse = float4(diffuse.rgb, WaterAlpha);
    
    return output;
}

PixelOutput_GBuffer PS_DepthGBuffer(DepthOutput input) : SV_Target
{
    float depth = input.Position.z / input.Position.w;
    
    //depth = 1.0f - depth * 5.0f; //카메라 영역
    PixelOutput_GBuffer output;
    output.Diffuse = float4(depth, depth, depth, 1.0f);
    
    return output;
}


technique11 T0
{
    //Terrain Render
    P_VP(P0, VS_PreRender_Reflection_Terrain, PS_PackGBufferLoTerrain)
    P_DSS_VP(P1, Deffered_DepthStencil_State, VS_Terrain_Projector, PS_PackGBufferLoTerrain)
    P_RS_VP(P2, FrontCounterClockwise_True, VS_Depth_Terrain, PS_Depth)
    //P_VTP(P0, VS_TerrainLOD, HS_TerrainLOD, DS_Reflect_TerrainLOD, PS_PackGBufferLod)
    //P_DSS_VTP(P1,Deffered_DepthStencil_State, VS_TerrainLOD, HS_TerrainLOD, DS_TerrainLOD, PS_PackGBufferLod)
    //P_VP(P2, VS_Depth_TerrainLOD, PS_DepthGBuffer)
    //Shadow Depth
    P_RS_VP(P3, FrontCounterClockwise_True, VS_Depth_Mesh, PS_Depth)
    P_RS_VP(P4, FrontCounterClockwise_True, VS_Depth_Model, PS_Depth)
    P_RS_VP(P5, FrontCounterClockwise_True, VS_Depth_Animation, PS_Depth)
    //P_RS_DSS_BS_VP(P2, Deffered_Rasterizer_State, Deffered_DepthStencil_State, Additive, VS_Depth_TerrainLOD, PS_DepthGBuffer)
    //P_RS_DSS_BS_VP(P3, Deffered_Rasterizer_State, Deffered_DepthStencil_State, Additive, VS_Depth_Mesh, PS_DepthGBuffer)
    //P_RS_DSS_BS_VP(P4, Deffered_Rasterizer_State, Deffered_DepthStencil_State, Additive, VS_Depth_Model, PS_DepthGBuffer)
    //P_RS_DSS_BS_VP(P5, Deffered_Rasterizer_State, Deffered_DepthStencil_State, Additive, VS_Depth_Animation, PS_DepthGBuffer)

    //sky
    P_VP(P6, VS_Scattering, PS_Scattering)

    P_VP(P7, VS_Dome, PS_Dome)
    P_RS_BS_VP(P8, CullMode_None,AlphaBlend, VS_Moon, PS_Moon)
    P_RS_BS_VP(P9, CullMode_None, Additive, VS_Cloud, PS_Cloud)


    
    //Reflection PreRender
    P_VP(P10,  VS_PreRender_Reflection_Mesh, PS_PackGBuffer)
    P_VP(P11,  VS_PreRender_Reflection_Model, PS_PackGBuffer)
    P_VP(P12,  VS_PreRender_Reflection_Animation, PS_PackGBuffer)
    ////Reflection PreRender
    //P_VTP(P10, VS_MeshLOD, HS_TerrainLOD, DS_Reflect_TerrainLOD, PS_LOD)
    //P_VTP(P11, VS_ModelLOD, HS_TerrainLOD, DS_Reflect_TerrainLOD, PS_LOD)
    //P_VTP(P12, VS_AnimationLOD, HS_TerrainLOD, DS_Reflect_TerrainLOD, PS_LOD)

    P_VP(P13, VS_PreRender_Reflection_Dome, PS_Dome)
    P_RS_BS_VP(P14, CullMode_None,AlphaBlend, VS_PreRender_Reflection_Moon, PS_Moon)
    P_RS_BS_VP(P15, CullMode_None, Additive, VS_PreRender_Reflection_Cloud, PS_Cloud)


    //Render
    P_DSS_VP(P16, Deffered_DepthStencil_State, VS_Mesh, PS_PackGBuffer)
    P_DSS_VP(P17, Deffered_DepthStencil_State, VS_Model, PS_PackGBuffer)
    P_DSS_VP(P18, Deffered_DepthStencil_State, VS_Animation, PS_PackGBuffer)

    ////Render
    //P_VTP(P16, VS_MeshLOD, HS_TerrainLOD, DS_TerrainLOD, PS_LOD)
    //P_VTP(P17, VS_ModelLOD, HS_TerrainLOD, DS_TerrainLOD, PS_LOD)
    //P_VTP(P18, VS_AnimationLOD, HS_TerrainLOD, DS_TerrainLOD, PS_LOD)

    //Water Render
    P_BS_VP(P19, AlphaBlend, VS_Water, PS_WaterGbuffer)
    //P_DSS_VP(P20, DepthEnable_False, VS_2D, PS_2D)
     P_DSS_VP(P20, Deffered_DepthStencil_State, VS_Directional, PS_Directional)
    //Deffered - PointLights
    P_RS_VTP(P21, Deffered_Rasterizer_State, VS_PointLights, HS_PointLights, DS_PointLights, PS_PointLights_Debug)
    P_RS_DSS_BS_VTP(P22, Deffered_Rasterizer_State, Deffered_DepthStencil_State, Additive, VS_PointLights, HS_PointLights, DS_PointLights, PS_PointLights)

    //Deffered - SpotLights
    P_RS_VTP(P23, Deffered_Rasterizer_State, VS_SpotLights, HS_SpotLights, DS_SpotLights, PS_SpotLights_Debug)
    P_RS_DSS_BS_VTP(P24, Deffered_Rasterizer_State, Deffered_DepthStencil_State, Additive, VS_SpotLights, HS_SpotLights, DS_SpotLights, PS_SpotLights)

    //Render
    P_VP(P25,  VS_Mesh, PS)
    P_VP(P26,  VS_Model, PS)
    P_VP(P27,  VS_Animation, PS)
    P_BS_VP(P28, AlphaBlend, VS_Water, PS_Water)
   

}