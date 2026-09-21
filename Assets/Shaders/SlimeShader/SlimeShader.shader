Shader "Custom/SlimeShader"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _Transparency("Transparency", Range(0,1)) = 1
        _AmbienceAmount("Ambience", Range(0,1)) = .25
        _FresnelPow("Fresnel Power", Float) = 1
        _SmoothValueLow("Step Value Low", Range(0,1)) = .2
        _SmoothValueHigh("Step Value High", Range(0,1)) = .5
        _ToonStep("Toon Step", Range(.001,10)) = 1
        _OutlineWidth("Outline Width", Range(0,1)) = 1
        _OutlineColor("Outline Color", Color) = (1,1,1,1)
        _SpeedOfWobble("Speed of Wobble", Float) = 1
        _WobbleRange("Wobble Range", Range(0,1)) = .2
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Blend SrcAlpha OneMinusSrcAlpha
        
        Pass
        {
            ZWrite On
            Tags { "LightMode" = "UniversalForward" } 
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
            float _Transparency, _SmoothValueLow, _FresnelPow, _SmoothValueHigh, _AmbienceAmount, _ToonStep, _SpeedOfWobble, _WobbleRange;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.uv = IN.uv;
                OUT.normal = TransformObjectToWorldNormal(IN.normal);
                OUT.worldPos = TransformObjectToWorld(IN.positionOS.xyz);
                float3 localPos = IN.positionOS.xyz;
                float wobble = sin(_Time.y * _SpeedOfWobble) * _WobbleRange;
                localPos.x *= 1 / (1 + wobble);
                localPos.y *= 1 + wobble;
                localPos.z *= 1 / (1 + wobble);
                OUT.positionHCS = TransformObjectToHClip(localPos);
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
                toonEffect = floor(toonEffect * _ToonStep)/_ToonStep;
                float3 ambiance = _BaseColor.rgb * _AmbienceAmount;
                float3 frenselColor = frenselCalc * _RimColor.rgb;
                float3 albedo = ((toonEffect * _BaseColor.rgb) + ambiance) + frenselColor;

                return float4(albedo,_Transparency);
            }
            ENDHLSL
        }
        Pass
        {
            ZWrite Off
            Cull Front
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normals : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normals : TEXCOORD1;
            };
            
            float _OutlineWidth, _SpeedOfWobble, _WobbleRange;
            float4 _OutlineColor;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float3 outlinePos = IN.positionOS + IN.normals * _OutlineWidth;
                float3 localPos = outlinePos;
                float wobble = sin(_Time.y * _SpeedOfWobble) * _WobbleRange;
                localPos.x *= 1 / (1 + wobble);
                localPos.y *= 1 + wobble;
                localPos.z *= 1 / (1 + wobble);
                OUT.positionHCS = TransformObjectToHClip(localPos);
                OUT.normals = TransformObjectToWorldNormal(IN.normals);
                return OUT;
            }

            float4 frag() : SV_Target
            {
                return float4(_OutlineColor);
            }

            ENDHLSL
        }

        Pass
        {
            ZWrite On
            ColorMask 0
            Tags { "LightMode" = "ShadowCaster" }
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
            };
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                return OUT;
            }

            float4 frag() : SV_Target
            {
                return float4(0,0,0,0);
            }

            ENDHLSL
        }
    }
}
