#include "00_Global.fx"
#include "00_Deffered.fx"
#include "00_PostEffect.fx"

float RGBCVtoHUE(in float3 RGB, in float C, in float V)
{
    float3 Delta = (V - RGB) / C;
    Delta.rgb -= Delta.brg;
    Delta.rgb += float3(2, 4, 6);

    Delta.brg = step(V, RGB) * Delta.brg;
    
    float H = max(Delta.r, max(Delta.g, Delta.b));
    return frac(H / 6);
}
 
float3 RGBtoHSV(in float3 RGB)
{
    float3 HSV = 0;
    HSV.z = max(RGB.r, max(RGB.g, RGB.b));
    float M = min(RGB.r, min(RGB.g, RGB.b));
    float C = HSV.z - M;
    if (C != 0)
    {
        HSV.x = RGBCVtoHUE(RGB, C, HSV.z);
        HSV.y = C / HSV.z;
    }
    return HSV;
}
 
float3 HUEtoRGB(in float H)
{
    float R = abs(H * 6 - 3) - 1;
    float G = 2 - abs(H * 6 - 2);
    float B = 2 - abs(H * 6 - 4);
    return saturate(float3(R, G, B));
}
 
float3 HSVtoRGB(float3 HSV)
{
    float3 RGB = HUEtoRGB(HSV.x) - 1;
    float3 temp = (RGB * HSV.y + 1);

    temp *= HSV.z;

    return temp;
}

float3 HSVComplement(float3 HSV)
{
    float3 complement = HSV;
    complement.x -= 0.5;
    if (complement.x < 0.0)
    {
        complement.x += 1.0;
    }
    
    return (complement);
}

float HueLerp(float h1, float h2, float v)
{
    float d = abs(h1 - h2);
    if (d <= 0.5)
    {
        return lerp(h1, h2, v);
    }
    else if (h1 < h2)
    {
        return frac(lerp((h1 + 1.0), h2, v));
    }
    else
    {
        return frac(lerp(h1, (h2 + 1.0), v));
    }
}

float3 PostComplement(float3 input)
{
    float3 guide = float3(1.0f, 0.5f, 0.0f);
    float amount = 0.5f;
 
    float correlation = 0.5f;
    float concentration = 2.0f;
 
    
    float3 input_hsv = RGBtoHSV(input);
    float3 hue_pole1 = RGBtoHSV(guide);
    float3 hue_pole2 = HSVComplement(hue_pole1);
 
    float dist1 = abs(input_hsv.x - hue_pole1.x);
    if (dist1 > 0.5)
        dist1 = 1.0 - dist1;
    float dist2 = abs(input_hsv.x - hue_pole2.x);
    if (dist2 > 0.5)
        dist2 = 1.0 - dist2;
 
    float descent = smoothstep(0, correlation, input_hsv.y);
 
    
    float3 output_hsv = input_hsv;
    if (dist1 < dist2)
    {
        float c = descent * amount * (1.0 - pow((dist1 * 2.0), 1.0 / concentration));
        
        output_hsv.x = HueLerp(input_hsv.x, hue_pole1.x, c);
        output_hsv.y = lerp(input_hsv.y, hue_pole1.y, c);
    }
    else
    {
        float c = descent * amount * (1.0 - pow((dist2 * 2.0), 1.0 / concentration));
        
        output_hsv.x = HueLerp(input_hsv.x, hue_pole2.x, c);
        output_hsv.y = lerp(input_hsv.y, hue_pole2.y, c);
    }
 
    return HSVtoRGB(output_hsv);
}

float4 PS(VertexOutput_PostEffect input) : SV_Target
{
    float4 extract = Maps[0].Sample(LinearSampler, input.Uv);
    float3 color = PostComplement(float3(extract.r, extract.g, extract.b));
	
    return float4(color, 1.0f);
}

technique11 T0
{
    P_VP(P0, VS_PostEffect, PS)
}