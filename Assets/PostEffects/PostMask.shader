Shader "Custom/PostMask"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 screenPosition : TEXCOORD1;
            };


            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _GlobalRenderTexture;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPosition = ComputeScreenPos(o.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 textureCoordinates = i.screenPosition.xy / i.screenPosition.w;

                fixed4 displacement = tex2D(_MainTex, i.uv - float2(sin(_Time.y * 17) * 0.0, _Time.y / 2));

                fixed4 col = tex2D(_GlobalRenderTexture, textureCoordinates + float2(0, displacement.x / 100));
                return col;
            }
            ENDCG
        }
    }
}
