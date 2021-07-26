//ByteAddressBuffer Input; //SRV
RWByteAddressBuffer Output; //UAV

struct Group
{
    uint3 GroupID;
    uint3 GroupThreadID;
    uint3 DispatchThreadID;
    uint GroupIndex;
};

struct ComputeInput
{
    uint3 GroupID : SV_GroupID;
    uint3 GroupThreadID : SV_GroupThreadID;
    uint3 DispatchThreadID : SV_DispatchThreadID;
    uint GroupIndex : SV_GroupIndex;
};

[numthreads(10, 8, 3)]
void CS(ComputeInput input)
{
    Group group;
    group.GroupID = asuint(input.GroupID);
    group.GroupThreadID = asuint(input.GroupThreadID);
    group.DispatchThreadID = asuint(input.DispatchThreadID);
    group.GroupIndex = asuint(input.GroupIndex);
    
    uint index = input.GroupID.x * 240 + input.GroupIndex;
    uint address = index * 10 * 4;
    
    Output.Store3(address + 0, asuint(group.GroupID));
    Output.Store3(address + 12, asuint(group.GroupThreadID));
    Output.Store3(address + 24, asuint(group.DispatchThreadID));
    Output.Store(address + 36, asuint(group.GroupIndex));
}

technique11 T0
{
    pass P0
    {
        SetVertexShader(NULL);
        SetPixelShader(NULL);

        SetComputeShader(CompileShader(cs_5_0, CS()));
    }
}