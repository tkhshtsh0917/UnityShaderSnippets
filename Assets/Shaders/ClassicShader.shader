Shader "Custom/ClassicShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SpecularGloss ("Speclar Gloss", float) = 5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        CGINCLUDE

        sampler2D _MainTex;
        float4 _MainTex_ST;
        half _SpecularGloss;

        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        #define lightColor _LightColor0

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
            float3 normal : NORMAL;
        };
        ENDCG

        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 viewDir : TEXCOORD1;
                float3 lightDir : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                o.lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                o.vertex = UnityObjectToClipPos(v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 texCol = tex2D(_MainTex, i.uv);

                // Lambert Diffuse
                float diffuse = saturate(dot(i.normal, i.lightDir));

                // Half-Lambert Diffuse
                // diffuse = diffuse * 0.5f + 0.5f;

                // Phong Specular
                // float3 reflectVec = reflect(-i.lightDir, i.normal);
                // float specular = pow(saturate(dot(reflectVec, i.viewDir)), _SpecularGloss);

                // Blinn-Phong Specular
                float3 halfVec = normalize(i.lightDir + i.viewDir);
                float specular = pow(saturate(dot(i.normal, halfVec)), _SpecularGloss);

                // Ambient
                float3 ambient = ShadeSH9(float4(i.normal, 1));

                return fixed4(texCol.xyz * ((diffuse + specular) * lightColor.xyz + ambient), texCol.a);
            }
            ENDCG
        }

        Pass
        {
            Tags { "LightMode"="ForwardAdd" }
            Blend One One

            CGPROGRAM

            #pragma multi_compile_fwdadd_fullshadows

            #include "AutoLight.cginc"

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 viewDir : TEXCOORD1;
                float3 lightDir : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                o.lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                o.worldPos = worldPos;
                o.vertex = UnityObjectToClipPos(v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);

                fixed4 texCol = tex2D(_MainTex, i.uv);

                // Lambert Diffuse
                float diffuse = saturate(dot(i.normal, i.lightDir));

                // Half-Lambert Diffuse
                // diffuse = diffuse * 0.5f + 0.5f;

                // Phong Specular
                // float3 reflectVec = reflect(-i.lightDir, i.normal);
                // float specular = pow(saturate(dot(reflectVec, i.viewDir)), _SpecularGloss);

                // Blinn-Phong Specular
                float3 halfVec = normalize(i.lightDir + i.viewDir);
                float specular = pow(saturate(dot(i.normal, halfVec)), _SpecularGloss);

                return fixed4(texCol.xyz * (diffuse + specular) * lightColor.xyz, texCol.a) * attenuation;
            }
            ENDCG
        }
    }
}
