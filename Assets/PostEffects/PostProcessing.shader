Shader "Main/PostProcessing"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    CGINCLUDE
        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
        };

        sampler2D _MainTex;
        float4 _MainTex_ST;

        v2f vert (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);

            return o;
        }
    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass // 0   --   Screen Tint
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 _ScreenTint;

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                return col * _ScreenTint;
            }
            ENDCG
        }

        Pass // 1   --   Chromatic Aberration
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 _ChromaticOffset;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = (1, 1, 1, 1);
                float4 offset = (_ChromaticOffset * 2 - 1)  * 0.01;

                float2 uv2 = i.uv * 2 - 1;
                float len = (length(uv2) - 0.5) * _ChromaticOffset.w;

                if (len > 0)
                {
                    fixed4 uvR = tex2D(_MainTex, i.uv + offset.r * len);
                    fixed4 uvG = tex2D(_MainTex, i.uv + offset.g * len);
                    fixed4 uvB = tex2D(_MainTex, i.uv + offset.b * len);

                    col.x = uvR.x;
                    col.y = uvG.y;
                    col.z = uvB.z;
                }
                else
                {
                    col = tex2D(_MainTex, i.uv);
                }
                return col;
            }
            ENDCG
        }

        Pass // 2   --   Grayscale
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                float gray = col.x * 0.299 + col.y * 0.587 + col.z * 0.114;
                col.xyz = gray;

                return col;
            }
            ENDCG
        }
    }
}
