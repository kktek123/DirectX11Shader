#include "00_Global.fx"
#include "00_Deffered.fx"
#include "00_Render.fx"

technique11 T0
{
    //Deffered - Depth Shadow
    P_VP(P0, VS_Depth_Mesh, PS_Depth)
    P_VP(P1, VS_Depth_Model, PS_Depth)
    P_VP(P2, VS_Depth_Animation, PS_Depth)

    //Deffered - PackGBuffer
    P_DSS_VP(P3, Deffered_DepthStencil_State, VS_Mesh, PS_PackGBuffer)
    P_DSS_VP(P4, Deffered_DepthStencil_State, VS_Model, PS_PackGBuffer)
    P_DSS_VP(P5, Deffered_DepthStencil_State, VS_Animation, PS_PackGBuffer)

    //Deffered - Directional
    P_DSS_VP(P6, Deffered_DepthStencil_State, VS_Directional, PS_Directional)

    //Deffered - PointLights
    P_RS_VTP(P7, Deffered_Rasterizer_State, VS_PointLights, HS_PointLights, DS_PointLights, PS_PointLights_Debug)
    P_RS_DSS_BS_VTP(P8, Deffered_Rasterizer_State, Deffered_DepthStencil_State, Additive, VS_PointLights, HS_PointLights, DS_PointLights, PS_PointLights)
}