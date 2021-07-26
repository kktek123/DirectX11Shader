#include "00_Global.fx"
#include "00_Deffered.fx"

#define MAX_POSTEFFECT_SRVS 8

cbuffer CB_PostEffect
{
    float2 PixelSize;
};
Texture2D Maps[MAX_POSTEFFECT_SRVS];

struct VertexOutput
{
    float4 Position : SV_Position;
    float2 Uv : Uv;
};

VertexOutput VS(float4 Position : Position)
{
    VertexOutput output;
    
    output.Position = Position;
    output.Uv.x = Position.x * 0.5f + 0.5f;
    output.Uv.y = -Position.y * 0.5f + 0.5f;
    
    return output;
}

float4 PS_Diffuse(VertexOutput input) : SV_Target
{
    return Maps[0].Sample(LinearSampler, input.Uv);
}

float4 PS_Grayscale(VertexOutput input) : SV_Target
{
    float3 grayscale = float3(0.2627f, 0.6780f, 0.0593f);
    
    float4 diffuse = Maps[0].Sample(LinearSampler, input.Uv);
    float temp = dot(diffuse.rgb, grayscale);
    
    return float4(temp, temp, temp, 1.0f);
}

//Saturation = 0 : grayscale
//0 < Saturation < 1 : desaturation
//Saturation = 1 : original
//Saturation > 1 : satuaration
float Saturation = 0;
float4 PS_Saturation(VertexOutput input) : SV_Target
{
    float3 grayscale = float3(0.2126f, 0.7152f, 0.0722f);
    
    float4 diffuse = Maps[0].Sample(LinearSampler, input.Uv);
    float temp = dot(diffuse.rgb, grayscale);
    
    diffuse.rgb = lerp(temp, diffuse.rgb, Saturation);
    diffuse.a = 1.0f;
    
    return diffuse;
}


float Sharpness = 0;
float4 PS_Sharpness(VertexOutput input) : SV_Target
{
    float4 center = Maps[0].Sample(LinearSampler, input.Uv);
    float4 top = Maps[0].Sample(LinearSampler, input.Uv + float2(0, -PixelSize.y));
    float4 bottom = Maps[0].Sample(LinearSampler, input.Uv + float2(0, +PixelSize.y));
    float4 left = Maps[0].Sample(LinearSampler, input.Uv + float2(-PixelSize.x, 0));
    float4 right = Maps[0].Sample(LinearSampler, input.Uv + float2(+PixelSize.x, 0));
    
    float4 edge = center * 4 - left - right - top - bottom;
    
    return center + Sharpness * edge;
}


float4x4 ColorToSepiaMatrix = float4x4
(
    0.393, 0.769, 0.189, 0,
    0.349, 0.686, 0.168, 0,
    0.272, 0.534, 0.131, 0,
    0, 0, 0, 1
);

float4 PS_Sepia(VertexOutput input) : SV_Target
{
    float4 color = Maps[0].Sample(LinearSampler, input.Uv);
    
    return mul(ColorToSepiaMatrix, color);
}


//1 : Linear
//>1 : Non-Linear
float Power = 2;
float2 Scale = float2(2, 2);

float4 PS_Vignette(VertexOutput input) : SV_Target
{
    float4 color = Maps[0].Sample(LinearSampler, input.Uv);
    
    float radius = length((input.Uv - 0.5f) * 2 / Scale);
    float vignette = pow(abs(radius + 0.0001f), Power);
    
    return saturate(1 - vignette) * color;
}


float Strength = 1.0f;
int interaceValue = 2;

float4 PS_Interace(VertexOutput input) : SV_Target
{
    float4 color = Maps[0].Sample(LinearSampler, input.Uv);
    
    float height = 1.0f / PixelSize.y;
    
    int value = (int) ((floor(input.Uv.y * height) % interaceValue) / (interaceValue / 2));
    
    [flatten]
    if (value)
    {
        float3 grayScale = float3(0.2126f, 0.7152f, 0.0722f);
        float luminance = dot(color.rgb, grayScale);
        
        luminance = min(0.999f, luminance);
        
        color.rgb = lerp(color.rgb, color.rgb * luminance, Strength);
    }
    return color;
}


float LensPower = 1;
float3 Distortion = -0.02f;

float4 PS_LensDistortion(VertexOutput input) : SV_Target
{
    float2 uv = input.Uv * 2 - 1;
    
    float2 vpSize = float2(1.0f / PixelSize.x, 1.0f / PixelSize.y);
    float aspect = vpSize.x / vpSize.y;
    float radiusSquared = aspect * aspect * uv.x * uv.x + uv.y * uv.y;
    float radius = sqrt(radiusSquared);

    float3 f = Distortion * pow(abs(radius + 0.0001f), LensPower) + 1;
    
    float2 r = (f.r * uv + 1) * 0.5f;
    float2 g = (f.g * uv + 1) * 0.5f;
    float2 b = (f.b * uv + 1) * 0.5f;
    
    float4 color = 0;
    color.r = Maps[0].Sample(LinearSampler, r).r;
    color.ga = Maps[0].Sample(LinearSampler, g).ga;
    color.b = Maps[0].Sample(LinearSampler, b).b;
    
    return color;
}

float4 PS_UnpackGBuffer(VertexOutput input) : SV_Target
{
    float4 position = input.Position;
    float2 screen = input.Uv * 2.0f - 1.0f;
    
    float3 normal = 0, tangent = 0;
    MaterialDesc material = MakeMaterial();
    
    UnpackGBuffer(position, screen, material, normal, tangent);
    
    return material.Diffuse;
}


float2 ScaleSourceSize;
float4 PS_Linear4(VertexOutput input) : SV_Target
{
    float2 size = 1.0f / ScaleSourceSize;
    
    float4 s0 = Maps[0].Sample(LinearSampler, input.Uv + float2(-size.x, -size.y));
    float4 s1 = Maps[0].Sample(LinearSampler, input.Uv + float2(+size.x, -size.y));
    float4 s2 = Maps[0].Sample(LinearSampler, input.Uv + float2(-size.x, +size.y));
    float4 s3 = Maps[0].Sample(LinearSampler, input.Uv + float2(+size.x, +size.y));
    
    return (s0 + s1 + s2 + s3) / 4;
}


float2 WiggleOffset = float2(10, 10);
float2 WiggleAmount = float2(0.01f, 0.01f);
float4 PS_Wiggle(VertexOutput input) : SV_Target
{
    float2 uv = input.Uv;
    uv.x += sin(Time + uv.x * WiggleOffset.x) * WiggleAmount.x;
    uv.y += cos(Time + uv.y * WiggleOffset.y) * WiggleAmount.y;
    
    return Maps[0].Sample(LinearSampler, uv);
}


technique11 T0
{
    P_VP(P0, VS, PS_Diffuse)
    P_VP(P1, VS, PS_Grayscale)
    P_VP(P2, VS, PS_Saturation)
    P_VP(P3, VS, PS_Sharpness)
    P_VP(P4, VS, PS_Sepia)
    P_VP(P5, VS, PS_Vignette)
    P_VP(P6, VS, PS_Interace)
    P_VP(P7, VS, PS_LensDistortion)
    P_VP(P8, VS, PS_UnpackGBuffer)
    P_VP(P9, VS, PS_Linear4)
    P_VP(P10, VS, PS_Wiggle)
}