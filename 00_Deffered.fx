//#include "00_Light.fx"

RasterizerState Deffered_Rasterizer_State;
DepthStencilState Deffered_DepthStencil_State;

///////////////////////////////////////////////////////////////////////////////
// Packed GBuffer
///////////////////////////////////////////////////////////////////////////////
struct PixelOutput_GBuffer
{
    float4 Diffuse : SV_Target0;    
    float4 Specular : SV_Target1;
    float4 Emissive : SV_Target2;
    float4 Normal : SV_Target3;
    float4 Tangent : SV_Target4;
    float4 Depth : SV_Target5;
    //이미 계산되있는 값을 계산한다.
};

PixelOutput_GBuffer PS_PackGBuffer(MeshOutput input)
{
    NormalMapping(input.Uv, input.Normal, input.Tangent);
 
    Texture(Material.Diffuse, DiffuseMap, input.Uv); //diffuse샘플링
    Texture(Material.Specular, SpecularMap, input.Uv); //Specular

    PixelOutput_GBuffer output;
    output.Diffuse = float4(Material.Diffuse.rgb, 1);
    output.Specular = Material.Specular;
    output.Emissive = Material.Emissive;
    output.Normal = float4(input.Normal, 1);
    output.Tangent = float4(input.Tangent, 1);
    
    return output;
}

//PixelOutput_GBuffer PS_PackGBuffer(MeshOutput input)
//{
//    NormalMapping(input.Uv, input.Normal, input.Tangent);
 
//    Texture(Material.Diffuse, DiffuseMap, input.Uv);//diffuse샘플링
//    Texture(Material.Specular, SpecularMap, input.Uv); //Specular
    
//    Material.Diffuse = CalculateFogColor(Material.Diffuse, input.wPosition);
 
//    PS_Projector(Material.Diffuse, input.wvpPosition_Sub);
    
//    PixelOutput_GBuffer output;
//    output.Diffuse = PS_Shadow(input.sPosition, float4(Material.Diffuse.rgb, 1));
//    output.Specular = Material.Specular;
//    output.Emissive = Material.Emissive;
//    output.Normal = float4(input.Normal, 1);
//    output.Tangent = float4(input.Tangent, 1);
    
//    float2 xy = 1.0f / float2(Projection._11, Projection._22);
//    float z = Projection._43;
//    float w = Projection._33;
//    float depth = input.wvpPosition.z;
//    float linearDepth = z / (depth - w) * xy; //선형깊이
//    //z = -zn*zf(zf-zn)(zn에대한 zf의비율)far
//    //w = zf/(zf-zn)(zf대한 zn의비율)near
//    //depth 0~1까지의 비율
//    //near~far 선형비율
//    output.Depth = PS_Shadow(input.sPosition, float4(Material.Diffuse.rgb, 1));
    
//    return output;
//}

PixelOutput_GBuffer PS_PackGBufferTerrain(VertexTerrain input)
{
    NormalMapping(input.Uv, input.Normal, input.Tangent);
 
    Texture(Material.Diffuse, DiffuseMap, input.Uv); //diffuse샘플링
    Texture(Material.Specular, SpecularMap, input.Uv); //Specular
    
    Material.Diffuse = CalculateFogColor(Material.Diffuse, input.wPosition);
 
    PS_Projector(Material.Diffuse, input.wvpPosition_Sub);
    
    PixelOutput_GBuffer output;
    output.Diffuse = PS_Shadow(input.sPosition, float4(Material.Diffuse.rgb, 1));
    output.Specular = Material.Specular;
    output.Emissive = Material.Emissive;
    output.Normal = float4(input.Normal, 1);
    output.Tangent = float4(input.Tangent, 1);
    
    float2 xy = 1.0f / float2(Projection._11, Projection._22);
    float z = Projection._43;
    float w = Projection._33;
    float depth = input.wvpPosition.z;
    float linearDepth = z / (depth - w) * xy; //선형깊이
    //z = -zn*zf(zf-zn)(zn에대한 zf의비율)far
    //w = zf/(zf-zn)(zf대한 zn의비율)near
    //depth 0~1까지의 비율
    //near~far 선형비율
    output.Depth = PS_Shadow(input.sPosition, float4(Material.Diffuse.rgb, 1));
    
    return output;
}

PixelOutput_GBuffer PS_PackGBufferWithShadow(MeshOutput input)
{
    NormalMapping(input.Uv, input.Normal, input.Tangent);
 
    Texture(Material.Diffuse, DiffuseMap, input.Uv); //diffuse샘플링
    Texture(Material.Specular, SpecularMap, input.Uv); //Specular
    
    Material.Diffuse = CalculateFogColor(Material.Diffuse, input.wPosition);
 
    PS_Projector(Material.Diffuse, input.wvpPosition_Sub);
    
    PixelOutput_GBuffer output;
    output.Diffuse = PS_Shadow(input.sPosition, float4(Material.Diffuse.rgb, 1));
    output.Specular = Material.Specular;
    output.Emissive = Material.Emissive;
    output.Normal = float4(input.Normal, 1);
    output.Tangent = float4(input.Tangent, 1);
    
    float2 xy = 1.0f / float2(Projection._11, Projection._22);
    float z = Projection._43;
    float w = Projection._33;
    float depth = input.wvpPosition.z;
    float linearDepth = z / (depth - w) * xy; //선형깊이
    //z = -zn*zf(zf-zn)(zn에대한 zf의비율)far
    //w = zf/(zf-zn)(zf대한 zn의비율)near
    //depth 0~1까지의 비율
    //near~far 선형비율
    output.Depth = float4(linearDepth, linearDepth, linearDepth, 1);
    
    return output;
}

///////////////////////////////////////////////////////////////////////////////
// UnpackGBuffer
///////////////////////////////////////////////////////////////////////////////
Texture2D GBufferMaps[6];

void UnpackGBuffer(inout float4 position, in float2 screen, out MaterialDesc material, out float3 normal, out float3 tangent)
{
    material.Ambient = float4(0, 0, 0, 1);
    material.Diffuse = GBufferMaps[1].Load(int3(position.xy, 0)); //diffuse//해당위치의 diffuse값을 가져온다 Load:필터링이나 샘플링없이 텍셀 데이터를 읽습니다.http://www.terms.co.kr/texel.htm
    material.Specular = GBufferMaps[2].Load(int3(position.xy, 0)); //specular
    material.Emissive = GBufferMaps[3].Load(int3(position.xy, 0)); //emissive
    //SV_Position = w로 나누어진것 원본비율로 이미 나누어져있다 ,NDC의 위치가 된다.
    //Screen = w로 안나누어짐 
    
    normal = GBufferMaps[4].Load(int3(position.xy, 0)).rgb;
    tangent = GBufferMaps[5].Load(int3(position.xy, 0)).rgb;

    //월드 공간상의 위치//깊이로 원본 위치를 만들어낸다.
    float2 xy = 1.0f / float2(Projection._11, Projection._22);
    float z = Projection._43;
    float w = -Projection._33;
    
    float depth = GBufferMaps[0].Load(int3(position.xy, 0)).r;//float써야하지만R24쓰기때문
    float linearDepth = z / (depth + w);//선형깊이
    
    position.xy = screen.xy * xy * linearDepth;
    position.z = linearDepth;
    position.w = 1.0f;
    //position픽셀값
    position = mul(position, ViewInverse);//world좌표
}

///////////////////////////////////////////////////////////////////////////////
// Directional Lighting
///////////////////////////////////////////////////////////////////////////////
static const float2 NDC[4] = { float2(-1, +1), float2(+1, +1), float2(-1, -1), float2(+1, -1) };

struct VertexOutput_Directional
{
    float4 Position : SV_Position;
    float2 Screen : Position1;
    //SV_Position = w로 나누어진것 원본비율로 이미 나누어져있다 ,NDC의 위치가 된다.
    //Position1 = w로 안나누어짐 
};

VertexOutput_Directional VS_Directional(uint id : SV_VertexID)
{
    VertexOutput_Directional output;
    
    output.Position = float4(NDC[id], 0, 1);//포인트 리스트
    output.Screen = output.Position.xy; //NDC좌표들어가있다
    
    return output;
}
//컴퓨트라이트와 똑같다
void ComputeLight_Deffered(out MaterialDesc output, MaterialDesc material, float3 normal, float3 wPosition)
{
    output = MakeMaterial();
    
    
    float3 direction = -GlobalLight.Direction;
    float NdotL = dot(direction, normalize(normal));
    
    output.Ambient = GlobalLight.Ambient * material.Ambient;
    float3 E = normalize(ViewPosition() - wPosition);

    [flatten]
    if (NdotL > 0.0f)
    {
        output.Diffuse = material.Diffuse * NdotL;
        
        [flatten]
        if (any(material.Specular.rgb))
        {
            float3 R = normalize(reflect(-direction, normal));
            float RdotE = saturate(dot(R, E));
            
            float specular = pow(RdotE, material.Specular.a);
            output.Specular = material.Specular * specular * GlobalLight.Specular;
        }
    }
    
    [flatten]
    if (any(material.Emissive.rgb))
    {
        float NdotE = dot(E, normalize(normal));
        float emissive = smoothstep(1.0f - material.Emissive.a, 1.0f, 1.0f - saturate(NdotE));

        output.Emissive = material.Emissive * emissive;
    }
}

float4 PS_Directional(VertexOutput_Directional input) : SV_Target
{
    float4 position = input.Position;//NDC좌표들어가있다
    //float4 sPosition = WorldPosition(input.Position);
    //sPosition = mul(sPosition, ShadowView);
    //sPosition = mul(sPosition, ShadowProjection);
    
    float3 normal = 0, tangent = 0;
    MaterialDesc material = MakeMaterial();//초기화
    
    UnpackGBuffer(position, input.Screen, material, normal, tangent);
     //             world   
    
    MaterialDesc result = MakeMaterial();
    ComputeLight_Deffered(result, material, normal, tangent);

    return float4(MaterialToColor(result), 1);
    //return PS_Shadow(sPosition, float4(MaterialToColor(result), 1));
}


///////////////////////////////////////////////////////////////////////////////
// PointLighting
///////////////////////////////////////////////////////////////////////////////
cbuffer CB_Deffered_PointLight
{
    float PointLight_TessFactor;//테실레이션 쓰기
    float3 CB_Deffered_PointLight_Padding;
    
    matrix PointLight_Projection[MAX_POINT_LIGHT];
    PointLightDesc PointLight_Deffered[MAX_POINT_LIGHT];
};

float4 VS_PointLights() : Position
{
    return float4(0, 0, 0, 1);
}

struct CHullOutput_PointLights
{
    float Edges[4] : SV_TessFactor;
    float Inside[2] : SV_InsideTessFactor;
};

CHullOutput_PointLights CHS_PointLights()
{
    CHullOutput_PointLights output;

    output.Edges[0] = output.Edges[1] = output.Edges[2] = output.Edges[3] = PointLight_TessFactor;
    output.Inside[0] = output.Inside[1] = PointLight_TessFactor;
    
    return output;
}

struct HullOutput_PointLights
{
    float4 Direction : Position;
};

[domain("quad")]
[partitioning("integer")]
[outputtopology("triangle_ccw")]
[outputcontrolpoints(4)]
[patchconstantfunc("CHS_PointLights")]
HullOutput_PointLights HS_PointLights(uint id : SV_PrimitiveID)
{
    float4 direction[2] = { float4(1, 1, 1, 1), float4(-1, 1, -1, 1) };//구를 만들 방향
    //  1   1
    //  -1  1
    //y를 회전하는 회전식과 같다.
    HullOutput_PointLights output;
    output.Direction = direction[id % 2];//controlpoint를 넣는다.

    return output;//두개씩 모아서 보낸다.
}

struct DomainOutput_PointLights
{
    float4 Position : SV_Position;
    float2 Screen : Uv;
    uint PrimitiveID : Id;
};

[domain("quad")]
DomainOutput_PointLights DS_PointLights(CHullOutput_PointLights input, float2 uv : SV_DomainLocation,
    const OutputPatch<HullOutput_PointLights, 4> quad, uint id : SV_PrimitiveID)
{
    float2 clipSpace = uv.xy * 2.0f - 1.0f;//NDC공간에서 World좌표넣는다
    float2 clipSpaceAbs = abs(clipSpace.xy);
    float maxLength = max(clipSpaceAbs.x, clipSpaceAbs.y);//차중에 큰값//어느지점에 일정한 값을 가져온다.
    
    float3 direction = normalize(float3(clipSpace.xy, (maxLength - 1.0f)) * quad[0].Direction.xyz);//점을 원을 그리는 방향으로 이동시킨다.
    float4 position = float4(direction, 1.0f);//정점위치
    
    DomainOutput_PointLights output;
    output.Position = mul(position, PointLight_Projection[id / 2]);
    output.Screen = output.Position.xy / output.Position.w;
    output.PrimitiveID = id / 2;

    return output;
}

float4 PS_PointLights_Debug(DomainOutput_PointLights input) : SV_Target
{
    return float4(0, 1, 0, 1);
}


void ComputePointLight_Deffered(inout MaterialDesc output, uint id, MaterialDesc material, float3 normal, float3 wPosition)
{
    output = MakeMaterial();
    
    PointLightDesc desc = PointLight_Deffered[id];

    
    float3 light = desc.Position - wPosition;
    float dist = length(light);
        
    [flatten]
    if (dist > desc.Range)
        return;
        
        
    light /= dist;
        
    output.Ambient = material.Ambient * desc.Ambient;
        
    float NdotL = dot(light, normalize(normal));
    float3 E = normalize(ViewPosition() - wPosition);

    [flatten]
    if (NdotL > 0.0f)
    {
        float3 R = normalize(reflect(-light, normal));
        float RdotE = saturate(dot(R, E));
        float specular = pow(RdotE, material.Specular.a);
            
        output.Diffuse = material.Diffuse * NdotL * desc.Diffuse;
        output.Specular = material.Specular * specular * desc.Specular;
    }
    
        
    float NdotE = dot(E, normalize(normal));
    float emissive = smoothstep(1.0f - material.Emissive.a, 1.0f, 1.0f - saturate(NdotE));

    output.Emissive = material.Emissive * emissive * desc.Emissive;
        
        
    float temp = 1.0f / saturate(dist / desc.Range);
    float att = temp * temp * (1.0f / max(1.0f - desc.Intensity, 1e-8f));
        
    output.Ambient = output.Ambient * temp;
    output.Diffuse = output.Diffuse * att;
    output.Specular = output.Specular * att;
    output.Emissive = output.Emissive * att;
}

float4 PS_PointLights(DomainOutput_PointLights input) : SV_Target
{
    float4 position = input.Position;
    
    float3 normal = 0, tangent = 0;
    MaterialDesc material = MakeMaterial();
    
    UnpackGBuffer(position, input.Screen, material, normal, tangent);
    //정점이 계속 바뀌어서 for필요없음
    
    MaterialDesc result = MakeMaterial();
    ComputePointLight_Deffered(result, input.PrimitiveID, material, normal, position.xyz);

    return float4(MaterialToColor(result), 1);
}

///////////////////////////////////////////////////////////////////////////////
// SpotLighting
///////////////////////////////////////////////////////////////////////////////
cbuffer CB_Deffered_SpotLight
{
    float SpotLight_TessFactor;
    float3 CB_Deffered_SpotLight_Padding;
    
    float4 SpotLight_Angle[MAX_SPOT_LIGHT];
    matrix SpotLight_Projection[MAX_SPOT_LIGHT];
    
    SpotLightDesc SpotLight_Deffered[MAX_SPOT_LIGHT];
};

float4 VS_SpotLights() : Position
{
    return float4(0, 0, 0, 1);
}

struct ConstantHullOutput_SpotLights
{
    float Edges[4] : SV_TessFactor;
    float Inside[2] : SV_InsideTessFactor;
};

ConstantHullOutput_SpotLights ConstantHS_SpotLights()
{
    ConstantHullOutput_SpotLights output;
    
    output.Edges[0] = output.Edges[1] = output.Edges[2] = output.Edges[3] = SpotLight_TessFactor;
    output.Inside[0] = output.Inside[1] = SpotLight_TessFactor;
    
    return output;
}

struct HullOutput_SpotLights
{
    float4 Position : Position;
};

[domain("quad")]
[partitioning("integer")]
[outputtopology("triangle_ccw")]
[outputcontrolpoints(4)]
[patchconstantfunc("ConstantHS_SpotLights")]
HullOutput_SpotLights HS_SpotLights()
{
    HullOutput_SpotLights output;

    output.Position = float4(0, 0, 0, 1);

    return output;
}

struct DomainOutput_SpotLights
{
    float4 Position : SV_Position;
    float2 Screen : Uv;
    uint PrimitiveID : Id;
};

[domain("quad")]
DomainOutput_SpotLights DS_SpotLights(ConstantHullOutput_SpotLights input, float2 uv : SV_DomainLocation,
    const OutputPatch<HullOutput_SpotLights, 4> quad, uint id : SV_PrimitiveID)
{
    float c = SpotLight_Angle[id].x;
    float s = SpotLight_Angle[id].y;
    
    
    float2 clipSpace = uv.xy * float2(2, -2) + float2(-1, 1);
    
    float2 clipSpaceAbs = abs(clipSpace.xy);//밑의 둘래
    float maxLength = max(clipSpaceAbs.x, clipSpaceAbs.y);

    
    float cylinder = 0.2f;
    float expentAmount = (1.0f + cylinder);
    
    float2 clipSpaceCylAbs = saturate(clipSpaceAbs * expentAmount);
    float maxLengthCapsule = max(clipSpaceCylAbs.x, clipSpaceCylAbs.y);
    float2 clipSpaceCyl = sign(clipSpace.xy) * clipSpaceCylAbs;
    
    float3 halfSpherePosition = normalize(float3(clipSpaceCyl.xy, 1.0f - maxLengthCapsule));
    halfSpherePosition = normalize(float3(halfSpherePosition.xy * s, c));

    float cylOffsetZ = saturate((maxLength * expentAmount - 1.0f) / cylinder);
    
    
    float4 position = 0;
    position.xy = halfSpherePosition.xy * (1.0f - cylOffsetZ);
    position.z = halfSpherePosition.z - cylOffsetZ * c;
    position.w = 1.0f;
    
    
    DomainOutput_SpotLights output;
    output.Position = mul(position, SpotLight_Projection[id]);
    output.Screen = output.Position.xy / output.Position.w;
    output.PrimitiveID = id;
    
    return output;
}

float4 PS_SpotLights_Debug(DomainOutput_PointLights input) : SV_Target
{
    return float4(0, 1, 0, 1);
}

void ComputeSpotLight_Deffered(inout MaterialDesc output, uint id, MaterialDesc material, float3 normal, float3 wPosition)
{
    output = MakeMaterial();
    
    
    SpotLightDesc desc = SpotLight_Deffered[id];

    float3 light = desc.Position - wPosition;
    float dist = length(light);
        
    [flatten]
    if (dist > desc.Range)
        return;
        
        
    light /= dist;
        
    output.Ambient = material.Ambient * desc.Ambient;
        
    float NdotL = dot(light, normalize(normal));
    float3 E = normalize(ViewPosition() - wPosition);

    [flatten]
    if (NdotL > 0.0f)
    {
        float3 R = normalize(reflect(-light, normal));
        float RdotE = saturate(dot(R, E));
        float specular = pow(RdotE, material.Specular.a);
            
        output.Diffuse = material.Diffuse * NdotL * desc.Diffuse;
        output.Specular = material.Specular * specular * desc.Specular;
    }
    
        
    float NdotE = dot(E, normalize(normal));
    float emissive = smoothstep(1.0f - material.Emissive.a, 1.0f, 1.0f - saturate(NdotE));

    output.Emissive = material.Emissive * emissive * desc.Emissive;
        
        
    float temp = pow(saturate(dot(-light, desc.Direction)), desc.Angle);
    float att = temp * (1.0f / max(1.0f - desc.Intensity, 1e-8f));
        
    output.Ambient = output.Ambient * temp;
    output.Diffuse = output.Diffuse * att;
    output.Specular = output.Specular * att;
    output.Emissive = output.Emissive * att;
}

float4 PS_SpotLights(DomainOutput_PointLights input) : SV_Target
{
    float4 position = input.Position;
    
    float3 normal = 0, tangent = 0;
    MaterialDesc material = MakeMaterial();
    
    UnpackGBuffer(position, input.Screen, material, normal, tangent);
    
    
    MaterialDesc result = MakeMaterial();
    ComputeSpotLight_Deffered(result, input.PrimitiveID, material, normal, position.xyz);

    return float4(MaterialToColor(result), 1);
}