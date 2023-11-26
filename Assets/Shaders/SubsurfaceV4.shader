Shader "Custom/SubsurfaceV4"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _SubsurfaceTransmission ("Subsurface Transmission", float) = 0.2
        _SubsurfaceDistortion ("Subsurface Distortion", Range(0,1)) = 0.5
        _SubsurfaceFactor ("Subsurface Factor", float) = 4
        _AmbientTransmission ("Ambient Transmission", float) = 0.2

        _ThicknessMap ("Thickness Map", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        /*
        Must be of form
        #pragma surface [surfaceFunction] [lightModel] [optionalParams...]
            surfaceFunction: function containing the surface shader code
                must be in form: void surf (Input IN, inout SurfaceOutput o)
                where Input is a structure you define (with texture coordinates and
                other automatic variables
            lightModel: Lighting model to use. Built in ones include:
                Standard, StandardSpecular, Lambert, BlinnPhong. 
                You can also define your own. Different models use different output structs:
                Standard: SurfaceOutputStandard
                StandardSpecular: SurfaceOutputStandardSpecular
                Lambert, BlinnPhong: SurfaceOutput
            optionalParams:
                see https://docs.unity3d.com/Manual/SL-SurfaceShaders.html
        */
        #pragma surface surf StandardTranslucent fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        #include "UnityPBSLighting.cginc"

        sampler2D _ThicknessMap;

        /*
            Typically has any texture coordinates needed by the shader. These must be
            of the form uv_[TextureName] or uv2_... for a second coordinate set.
            Additional values can also go here such as view dir, screen pos, ect.
            See https://docs.unity3d.com/Manual/SL-SurfaceShaders.html for full list.
        */
        struct Input
        {
            float2 uv_ThicknessMap;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float _SubsurfaceTransmission;
        float _SubsurfaceDistortion;
        float _SubsurfaceFactor;
        float _AmbientTransmission;

        float thickness;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        /*
        Define a surface function to put data into the output structure SurfaceOutput
        This contains things like uv and describes the properties of the surface
    
            struct SurfaceOutput
            {
                fixed3 Albedo;  // diffuse color
                fixed3 Normal;  // tangent space normal, if written
                fixed3 Emission;
                half Specular;  // specular power in 0..1 range
                fixed Gloss;    // specular intensity
                fixed Alpha;    // alpha for transparencies
            };
            struct SurfaceOutputStandard
            {
                fixed3 Albedo;      // base (diffuse or specular) color
                fixed3 Normal;      // tangent space normal, if written
                half3 Emission;
                half Metallic;      // 0=non-metal, 1=metal
                half Smoothness;    // 0=rough, 1=smooth
                half Occlusion;     // occlusion (default 1)
                fixed Alpha;        // alpha for transparencies
            };
            struct SurfaceOutputStandardSpecular
            {
                fixed3 Albedo;      // diffuse color
                fixed3 Specular;    // specular color
                fixed3 Normal;      // tangent space normal, if written
                half3 Emission;
                half Smoothness;    // 0=rough, 1=smooth
                half Occlusion;     // occlusion (default 1)
                fixed Alpha;        // alpha for transparencies
            };
        */
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            thickness = tex2D(_ThicknessMap, IN.uv_ThicknessMap);
        }

        /*
        A lighting model function must be of the form Lighting[Name] where name is
        defined in the pragma. They can take 3 forms:
            half4 Lighting<Name> (SurfaceOutput s, UnityGI gi);
                Used for forward rendering NOT dependent on view direction
            half4 Lighting<Name> (SurfaceOutput s, half3 viewDir, UnityGI gi);
                Used for forward rendering that IS dependent on veiw direction
            half4 Lighting<Name>_Deferred (SurfaceOutput s, UnityGI gi, out half4 outDiffuseOcclusion, out half4 outSpecSmoothness, out half4 outNormal);
                Used for deferred rendering

            struct UnityGI
            {
                UnityLight light;
                UnityIndirect indirect;
            };
        */
        fixed4 LightingStandardTranslucent(SurfaceOutputStandard s, fixed3 viewDir, UnityGI gi)
        {
            fixed4 col = LightingStandard(s, viewDir, gi);
            
            float3 lightDir = gi.light.dir;

            float3 lightExitDir = -normalize(lightDir + s.Normal * _SubsurfaceDistortion);
            
            float intensity = pow(saturate(dot(viewDir, lightExitDir)), _SubsurfaceFactor);

            float subsurf = (intensity + _AmbientTransmission) * thickness * _SubsurfaceTransmission;
            
            col.rgb += gi.light.color * _Color.rgb * subsurf;

            return float4(col.rgb, 1);
        }

        /*
        You must also declare a matching _GI function to decode lightmap data and probes:
            half4 Lighting<Name>_GI (SurfaceOutput s, UnityGIInput data, inout UnityGI gi);
        
            struct UnityGIInput
            {
                UnityLight light; // pixel light, sent from the engine

                float3 worldPos;
                half3 worldViewDir;
                half atten;
                half3 ambient;

                // interpolated lightmap UVs are passed as full float precision data to fragment shaders
                // so lightmapUV (which is used as a tmp inside of lightmap fragment shaders) should
                // also be full float precision to avoid data loss before sampling a texture.
                float4 lightmapUV; // .xy = static lightmap UV, .zw = dynamic lightmap UV

                #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION) || defined(UNITY_ENABLE_REFLECTION_BUFFERS)
                float4 boxMin[2];
                #endif
                #ifdef UNITY_SPECCUBE_BOX_PROJECTION
                float4 boxMax[2];
                float4 probePosition[2];
                #endif
                // HDR cubemap properties, use to decompress HDR texture
                float4 probeHDR[2];
            };
        */
        void LightingStandardTranslucent_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
        {
            LightingStandard_GI(s, data, gi);  
        }
        
        ENDCG
    }
    FallBack "Diffuse"
}
