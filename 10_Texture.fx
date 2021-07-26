matrix World, View, Projection;

struct VertexInput
{
    float4 Position : Position;
    float2 Uv : Uv;
};

struct VertexOutput
{
    float4 Position : SV_Position;
    float2 Uv : Uv;
};

VertexOutput VS(VertexInput input)
{
    VertexOutput output;
    output.Position = mul(input.Position, World);    
    output.Position = mul(output.Position, View);
    output.Position = mul(output.Position, Projection);
    
    output.Uv = input.Uv;
    
    return output;
}

Texture2D Texture;
SamplerState Sampler;
float4 PS(VertexOutput input) : SV_Target
{
    float4 diffuse = Texture.Sample(Sampler, input.Uv);
    
    if (input.Uv.x > 0.5f)
        diffuse = float4(1, 0, 0, 1);

    return diffuse;
}


SamplerState Sampler_Filter_Point
{
    Filter = MIN_MAG_MIP_POINT;
};

SamplerState Sampler_Filter_Linear
{
    Filter = MIN_MAG_MIP_LINEAR;
};

uint FilterMode;
float4 PS_Filter(VertexOutput input) : SV_Target
{
    [branch]
    switch (FilterMode)
    {
        case 0:
            return Texture.Sample(Sampler_Filter_Point, input.Uv);
        
        case 1:
            return Texture.Sample(Sampler_Filter_Linear, input.Uv);
    }

    return float4(0, 0, 0, 1);
}


SamplerState Sampler_Address_Wrap
{
    AddressU = Wrap;
    AddressV = Wrap;
};

SamplerState Sampler_Address_Mirror
{
    AddressU = Mirror;
    AddressV = Mirror;
};

SamplerState Sampler_Address_Clamp
{
    AddressU = Clamp;
    AddressV = Clamp;
};

SamplerState Sampler_Address_Border
{
    AddressU = Border;
    AddressV = Border;

    BorderColor = float4(0, 0, 1, 1);
};

uint AddressMode;
float4 PS_Address(VertexOutput input) : SV_Target
{
    [branch]
    switch (AddressMode)
    {
        case 0:
            return Texture.Sample(Sampler_Address_Wrap, input.Uv);
        
        case 1:
            return Texture.Sample(Sampler_Address_Mirror, input.Uv);
        
        case 2:
            return Texture.Sample(Sampler_Address_Clamp, input.Uv);
        
        case 3:
            return Texture.Sample(Sampler_Address_Border, input.Uv);
    }

    return float4(0, 0, 0, 1);
}



technique11 T0
{
    pass P0
    {
        SetVertexShader(CompileShader(vs_5_0, VS()));
        SetPixelShader(CompileShader(ps_5_0, PS()));
    }

    pass P1
    {
        SetVertexShader(CompileShader(vs_5_0, VS()));
        SetPixelShader(CompileShader(ps_5_0, PS_Filter()));
    }

    pass P2
    {
        SetVertexShader(CompileShader(vs_5_0, VS()));
        SetPixelShader(CompileShader(ps_5_0, PS_Address()));
    }
}