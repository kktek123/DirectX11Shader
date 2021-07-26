
struct TerrainLODOutput
{
    float4 Position : Position0;

    float2 Uv : Uv0;
    float3 Normal : Normal0;
    float3 Tangent : Tangent0;
    float2 BoundY : BoundY0;

};
struct TerrainLODVertex
{
    float4 Position : Position0;
    float2 Uv : Uv0;
    float2 BoundY : BoundY0;
    matrix Transform : Inst0;
};

void SetTerrainLodWorld(inout matrix world, TerrainLODVertex input)
{
    world = input.Transform;
}
TerrainLODOutput VS_TerrainLOD(TerrainLODVertex input)
{
    TerrainLODOutput output;
    
    SetTerrainLodWorld(World, input);
    //VS_GENERATE
    output.Position = input.Position;
    output.Uv = input.Uv;
    output.BoundY = input.BoundY;
    return output;
}


DepthOutput VS_Depth_TerrainLOD(TerrainLODVertex input)
{
    DepthOutput output;

    SetTerrainLodWorld(World, input);
    VS_DEPTH_GENERATE

    return output;
}

//TerrainLODOutput VS_MeshLOD(VertexMesh input)
//{
//    TerrainLODOutput output;

//    SetMeshWorld(World, input);
//    //VS_GENERATE
//    output.Position = input.Position;
//    output.Uv = input.Uv;
//    //output.BoundY = input.BoundY;
//    return output;
//}




//TerrainLODOutput VS_ModelLOD(VertexModel input)
//{
//    TerrainLODOutput output;

//    SetModelWorld(World, input);
//    //VS_GENERATE
//    output.Position = input.Position;
//    output.Uv = input.Uv;
//    output.BoundY = input.BoundY;
//    return output;
//}

//TerrainLODOutput VS_AnimationLOD(VertexModel input)
//{
//    TerrainLODOutput output;

//    SetAnimationWorld(World, input); //위치크기지정
//    //VS_GENERATE

//    output.Position = input.Position;
//    output.Uv = input.Uv;
//    output.BoundY = input.BoundY;
//    return output;
//}


CHullOutput_TerrainLod HS_Constant_TerrainLod(InputPatch<TerrainLODOutput, 4> input)
{
    //float minY = input[0].BoundY.x;
    //float maxY = input[0].BoundY.y;

    //float3 vMin = float3(input[2].Position.x, minY, input[2].Position.z);
    //float3 vMax = float3(input[1].Position.x, maxY, input[1].Position.z);

    //float3 boxCenter = (vMin + vMax) * 0.5f;
    //float3 boxExtents = (vMax - vMin) * 1.5f;


    CHullOutput_TerrainLod output;

    //[flatten]
    //if (InFrustumCube(boxCenter, boxExtents))
    //{
    //    output.Edge[0] = output.Edge[1] = output.Edge[2] = output.Edge[3] = -1;
    //    output.Inside[0] = output.Inside[1] = -1;

    //    return output;
    //}


    float3 e0 = (input[0].Position + input[2].Position).xyz * 0.5f;
    float3 e1 = (input[0].Position + input[1].Position).xyz * 0.5f;
    float3 e2 = (input[1].Position + input[3].Position).xyz * 0.5f;
    float3 e3 = (input[2].Position + input[3].Position).xyz * 0.5f;

    output.Edge[0] = TessellationFactor(e0);
    output.Edge[1] = TessellationFactor(e1);
    output.Edge[2] = TessellationFactor(e2);
    output.Edge[3] = TessellationFactor(e3);

    
    float3 c = (input[0].Position.xyz + input[1].Position.xyz + input[2].Position.xyz + input[3].Position.xyz) * 0.25f;
    output.Inside[0] = TessellationFactor(c);
    output.Inside[1] = TessellationFactor(c);

    return output;
}

[domain("quad")]
[partitioning("fractional_even")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(4)]
[patchconstantfunc("HS_Constant_TerrainLod")]
HullOutput_TerrainLod HS_TerrainLOD(InputPatch<TerrainLODOutput, 4> input, uint id : SV_OutputControlPointID)
{
    HullOutput_TerrainLod output;
    output.Position = input[id].Position;
    output.Uv = input[id].Uv;
    return output;
}

