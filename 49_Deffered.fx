#include "00_Global.fx"
#include "00_Deffered.fx"
#include "00_Render.fx"

//DepthStencilState Deffered_DepthStencil_State;

technique11 T0
{
    //Deffered - Depth Shadow
    P_VP(P0, VS_Depth_Mesh, PS_Depth)
    P_VP(P1, VS_Depth_Model, PS_Depth)
    P_VP(P2, VS_Depth_Animation, PS_Depth)

    //Deffered - PackGBuffer
    P_VP(P3, VS_Mesh, PS_PackGBuffer)
    P_VP(P4, VS_Model, PS_PackGBuffer)
    P_VP(P5, VS_Animation, PS_PackGBuffer)
    //Deffered - Directional
    P_VP(P6, VS_Directional, PS_Directional)
}