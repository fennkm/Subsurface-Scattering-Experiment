Shader "Custom/Phong"
{
    Properties
    {
        _AmbientReflectivity ("Ambient Reflectivity", float) = 0.2

        _DiffuseReflectivity ("Diffuse Reflectivity", float) = 0.5
        _DiffuseColour ("Diffuse Colour", Color) = (1, 1, 1, 1)

        _SpecularReflectivity ("Specular Reflectivity", float) = 0.6
        _SpecularFactor ("Specular Factor", float) = 2
        
        _LightIntensity ("Light Intensity", float) = 1

        _LightColour ("Light Colour", Color) = (1, 1, 1, 1)
        _LightPointX ("Light Point X", float) = 0.0
        _LightPointY ("Light Point Y", float) = 0.0
        _LightPointZ ("Light Point Z", float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct vertData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct interpolator
            {
                // float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            float _AmbientReflectivity;

            float _DiffuseReflectivity;
            float4 _DiffuseColour;
            
            float _SpecularReflectivity;
            float _SpecularFactor;
            float4 _LightColour;

            float _LightIntensity;

            float _LightPointX;
            float _LightPointY;
            float _LightPointZ;

            interpolator vert (vertData v)
            {
                interpolator o;
                
                o.normal = normalize(mul(unity_ObjectToWorld, v.normal));

                o.vertex = UnityObjectToClipPos(v.vertex);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            fixed4 frag (interpolator i) : SV_Target
            {
                fixed4 normCol = fixed4(i.normal.xyz, 1);
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                float3 normWorldPos = i.worldPos.xyz / i.worldPos.w;
                float3 lightVec = 
                    normalize(
                        float3(_LightPointX, _LightPointY, _LightPointZ) - 
                        normWorldPos
                    );
                
                float diffuse = 
                    clamp(dot(i.normal, lightVec), 0, 1) * 
                    _DiffuseReflectivity * 
                    _LightIntensity;

                float3 reflectVec = 
                    normalize(
                        2 * dot(i.normal, lightVec) * i.normal - 
                        lightVec
                    );

                float specular = 
                    pow(clamp(dot(reflectVec, viewDir), 0, 1), _SpecularFactor) *
                    _SpecularReflectivity * 
                    _LightIntensity;

                float ambient = _AmbientReflectivity * _LightIntensity;

                fixed4 col = 
                    (diffuse + ambient) * _DiffuseColour + 
                    specular * _LightColour;
                
                return col;
            }
            ENDCG
        }
    }
}
