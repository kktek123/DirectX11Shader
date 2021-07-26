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


uint BlurCount = 8;
float4 PS_Blur(VertexOutput input) : SV_Target
{
    float2 arr[9] =
    {
        float2(-1, -1), float2(+0, -1), float2(+1, -1),
        float2(-1, +0), float2(+0, +0), float2(+1, +0),
        float2(-1, +1), float2(+0, +1), float2(+1, +1),
    };
    
    
    float3 color = 0;
    for (uint blur = 0; blur < BlurCount; blur++)
    {
        for (int i = 0; i < 9; i++)
        {
            float x = arr[i].x * (float) blur * PixelSize.x;
            float y = arr[i].y * (float) blur * PixelSize.y;
            
            float2 uv = input.Uv + float2(x, y);
            color += Maps[0].Sample(LinearSampler, uv).rgb;
        }
    }
    
    color /= BlurCount * 9;
    
    return float4(color.rgb, 1);
}


uint RadialBlurCount = 8;
float RadialBlurRadius = 0.0f;
float RadialBlurAmount = 0.04f; //4%
float2 RadialCenter = float2(0.5f, 0.5f);

float4 PS_RadialBlur(VertexOutput input) : SV_Target
{
    float2 radius = input.Uv - RadialCenter;
    float r = length(radius) + 1e-6f;
    radius /= r;
    
    r = 2 * r / RadialBlurRadius;
    r = saturate(r);
    
    float2 delta = radius * r * r * RadialBlurAmount / RadialBlurCount;
    delta = -delta;
    
    float4 color = 0;
    for (uint i = 0; i < RadialBlurCount; i++)
    {
        color += Maps[0].Sample(LinearSampler, input.Uv);
        input.Uv += delta;
    }
    color /= RadialBlurCount;
    
    return float4(color.rgb, 1);
}


int GaussBlurCount = 6;
static const float Weights[13] =
{
    0.0561f, 0.1353f, 0.2780f, 0.4868f, 0.7261f, 0.9231f,
    1.0f,
    0.9231f, 0.7261f, 0.4868f, 0.2780f, 0.1353f, 0.0561f
};

float4 PS_GaussBlurX(VertexOutput input) : SV_Target
{
    float2 uv = input.Uv;
    float u = PixelSize.x;
    
    float sum = 0;
    float4 color = 0;
    for (int i = -GaussBlurCount; i <= +GaussBlurCount; i++)
    {
        float2 temp = uv + float2(u * (float) i, 0.0f);
        color += Weights[6 + i] * Maps[0].Sample(LinearSampler, temp);
        
        sum += Weights[6 + i];
    }
    color /= sum;
    
    return float4(color.rgb, 1);
}

float4 PS_GaussBlurY(VertexOutput input) : SV_Target
{
    float2 uv = input.Uv;
    float v = PixelSize.y;
    
    float sum = 0;
    float4 color = 0;
    for (int i = -GaussBlurCount; i <= +GaussBlurCount; i++)
    {
        float2 temp = uv + float2(0.0f, v * (float) i);
        color += Weights[6 + i] * Maps[1].Sample(LinearSampler, temp);
        
        sum += Weights[6 + i];
    }
    color /= sum;
    
    return float4(color.rgb, 1);
}

float4 PS_GaussBlur(VertexOutput input) : SV_Target
{
    return Maps[2].Sample(LinearSampler, input.Uv);
}


struct PS_GaussBlurCombineOutput
{
    float4 Target0 : SV_Target0;
    float4 Target1 : SV_Target1;
};

PS_GaussBlurCombineOutput PS_GaussBlurCombine(VertexOutput input)
{
    PS_GaussBlurCombineOutput output;
    
    float2 uv = input.Uv;
    float u = PixelSize.x;
    
    float sum = 0;
    float4 color = 0;
    for (int i = -GaussBlurCount; i <= +GaussBlurCount; i++)
    {
        float2 temp = uv + float2(u * (float) i, 0.0f);
        color += Weights[6 + i] * Maps[0].Sample(LinearSampler, temp);
        
        sum += Weights[6 + i];
    }
    color /= sum;
    
    output.Target0 = float4(color.rgb, 1);
    
    
    uv = input.Uv;
    float v = PixelSize.y;
    
    sum = 0;
    color = 0;
    for (int k = -GaussBlurCount; k <= +GaussBlurCount; k++)
    {
        float2 temp = uv + float2(0.0f, v * (float) k);
        color += Weights[6 + k] * Maps[0].Sample(LinearSampler, temp);
        
        sum += Weights[6 + k];
    }
    color /= sum;
    
    output.Target1 =  float4(color.rgb, 1);
    
    return output;
}

float4 PS_GaussBlurFinal(VertexOutput input) : SV_Target
{
    float4 color = Maps[1].Sample(LinearSampler, input.Uv);
    float4 color2 = Maps[2].Sample(LinearSampler, input.Uv);
    
    return float4((color.rgb + color2.rgb) * 0.5f, 1);
}

technique11 T0
{
    P_VP(P0, VS, PS_Blur)
    P_VP(P1, VS, PS_RadialBlur)
    P_VP(P2, VS, PS_GaussBlur)
    P_VP(P3, VS, PS_GaussBlurFinal)
}

technique11 T1
{
    P_VP(P0, VS, PS_GaussBlurX)
    P_VP(P1, VS, PS_GaussBlurY)
    P_VP(P2, VS, PS_GaussBlurCombine)
}