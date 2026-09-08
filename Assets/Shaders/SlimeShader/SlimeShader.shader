Shader "Custom/SlimeShader"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _Transparency("Transparency", Range(0,1)) = 1
        _FresnelPow("Fresnel Power", Float) = 1
        _SmoothValueLow("Step Value", Range(0,1)) = .2
        _SmoothValueHigh("Step Value", Range(0,1)) = .5
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            float4 _BaseColor;
            float4 _RimColor;
            float _Transparency, _SmoothValueLow, _FresnelPow, _SmoothValueHigh;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.uv = IN.uv;
                OUT.normal = TransformObjectToWorldNormal(IN.normal);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float3 normals = normalize(IN.normal);
                float3 camera = GetCameraPositionWS();
                Light mainLight = GetMainLight();
                
                float3 viewDirection = normalize(camera - IN.worldPos);
                float frenselCalc = pow(1 - max(dot(normals, viewDirection),0), _FresnelPow); 
                
                float diffuse = max(dot(normals, mainLight.direction), 0);
                float toonEffect = smoothstep(_SmoothValueLow, _SmoothValueHigh, diffuse);
                toonEffect = floor(toonEffect * 2)/3;
                float3 ambiance = _BaseColor.rgb * .25;
                float3 frenselColor = frenselCalc * _RimColor;
                float3 albedo = ((toonEffect * _BaseColor.rgb) + ambiance) + frenselColor;

                return float4(albedo,_Transparency);
            }
            ENDHLSL
        }
    }
}
